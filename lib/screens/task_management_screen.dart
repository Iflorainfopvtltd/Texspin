import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import '../widgets/individual_task_management_dialog.dart';
import 'dart:developer' as developer;

class TaskManagementScreen extends StatefulWidget {
  // ... existing code ...

  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getTasks();
      if (response['tasks'] != null) {
        setState(() {
          _tasks = (response['tasks'] as List)
              .map((task) => Task.fromJson(task))
              .toList();
          _filteredTasks = _tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'TaskManagement');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTasks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = _tasks;
      } else {
        _filteredTasks = _tasks.where((task) {
          final taskName = task.name.toLowerCase();
          final staffName =
              '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                  .toLowerCase();
          final searchLower = query.toLowerCase();
          return taskName.contains(searchLower) ||
              staffName.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showAddEditTaskScreen({Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(
          task: task,
          onSaved: () {
            Navigator.of(context).pop();
            _loadTasks();
          },
        ),
      ),
    );
  }

  void _showReassignDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) =>
          ReassignIndividualTaskDialog(task: task, onReassigned: _loadTasks),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteTask(taskId: taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
          _loadTasks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: AppTheme.red500,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.green500;
      case 'approved':
        return AppTheme.green500;
      case 'in progress':
        return AppTheme.blue500;
      case 'submitted':
        return AppTheme.blue500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
    }
  }

  void _showApproveDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: Text('Are you sure you want to approve "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Approve',
            onPressed: () {
              Navigator.pop(context);
              _reviewTask(task.id, 'completed');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Task task) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${task.name}"?'),
            const SizedBox(height: 16),
            CustomTextInput(
              label: 'Rejection Reason',
              hint: 'Please provide a reason for rejection',
              controller: reasonController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a rejection reason';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Reject',
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppTheme.red500,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _reviewTask(
                task.id,
                'rejected',
                rejectionReason: reasonController.text.trim(),
              );
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Future<void> _reviewTask(
    String taskId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final response = await _apiService.reviewTask(
        taskId: taskId,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        // Use API response message if available, otherwise use default
        String successMessage;
        if (response['message'] != null) {
          successMessage = response['message'].toString();
        } else {
          successMessage = status == 'completed'
              ? 'Task approved successfully'
              : 'Task rejected successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: status == 'completed'
                ? AppTheme.green500
                : AppTheme.red500,
          ),
        );
        _loadTasks(); // Refresh the task list
      }
    } catch (e) {
      developer.log('Error reviewing task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  DataRow _buildTaskDataRow(Task task) {
    final assignedStaffName =
        '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
            .trim();

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              task.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              task.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          Text(assignedStaffName, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        DataCell(
          Text(
            task.deadline != null
                ? _formatDate(task.deadline!)
                : (task.isRecurringActive == true ? 'Recurring' : 'N/A'),
            style: const TextStyle(color: AppTheme.gray700),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(task.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(task.status),
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Check task status and show appropriate buttons
              ...() {
                final status = task.status.toUpperCase().trim();

                if (status == 'SUBMITTED') {
                  return [
                    // Download button (if downloadUrl is available)
                    if (task.downloadUrl != null &&
                        task.downloadUrl!.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: AppTheme.blue600,
                        ),
                        onPressed: () => _downloadTaskFile(task),
                        tooltip: 'Download File',
                      ),
                    // Approve button
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.green600,
                      ),
                      onPressed: () => _showApproveDialog(task),
                      tooltip: 'Approve',
                    ),
                    // Reject button
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: AppTheme.red500,
                      ),
                      onPressed: () => _showRejectDialog(task),
                      tooltip: 'Reject',
                    ),
                  ];
                } else if (status.contains('REJECT')) {
                  return [
                    // Reassign button
                    IconButton(
                      icon: const Icon(
                        Icons.person_add,
                        color: AppTheme.blue600,
                      ),
                      onPressed: () => _showReassignDialog(task),
                      tooltip: 'Reassign',
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.red500,
                      ),
                      onPressed: () => _deleteTask(task.id),
                      tooltip: 'Delete',
                    ),
                  ];
                } else {
                  return [
                    // For non-submitted tasks: show other actions
                    // Download button (if downloadUrl is available or has attachments)
                    if ((task.downloadUrl != null &&
                            task.downloadUrl!.isNotEmpty) ||
                        (task.attachments != null &&
                            task.attachments!.isNotEmpty))
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: AppTheme.blue600,
                        ),
                        onPressed: () => _downloadTaskFile(task),
                        tooltip: 'Download File',
                      ),
                    // Edit button (only for pending and in progress tasks)
                    if (!status.contains('COMPLET') &&
                        !status.contains('APPROV') &&
                        !status.contains('REJECT'))
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.blue600,
                        ),
                        onPressed: () => _showAddEditTaskScreen(task: task),
                        tooltip: 'Edit',
                      ),
                    // Delete button
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.red500,
                      ),
                      onPressed: () => _deleteTask(task.id),
                      tooltip: 'Delete',
                    ),
                  ];
                }
              }(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadTaskFile(Task task) async {
    try {
      String? fileUrl;
      String? fileName;

      // Check if task has downloadUrl (new structure)
      if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
        fileUrl = task.downloadUrl;
        fileName = task.fileName ?? 'task_file';
      }
      // Fallback to attachments (old structure)
      else if (task.attachments != null && task.attachments!.isNotEmpty) {
        final attachment = task.attachments!.first;
        fileUrl = attachment['fileUrl'] ?? '';
        fileName = attachment['fileName'] ?? 'task_file';
      }

      if (fileUrl == null || fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No files to download'),
            backgroundColor: AppTheme.yellow500,
          ),
        );
        return;
      }

      // Construct full URL using ApiService baseUrl
      final String fullUrl = ApiService.baseUrl + fileUrl;
      final Uri url = Uri.parse(fullUrl);

      developer.log('Downloading file from: $fullUrl');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$fileName download started')),
                ],
              ),
              backgroundColor: AppTheme.green500,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error downloading file: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Individual Tasks'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditTaskScreen(),
            tooltip: 'Add Task',
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showAddEditTaskScreen(),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.red500),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: AppTheme.gray600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _loadTasks,
                      variant: ButtonVariant.default_,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: CustomTextInput(
                    controller: _searchController,
                    hint: 'Search by task name or staff name...',
                    onChanged: _filterTasks,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterTasks('');
                            },
                          )
                        : const Icon(Icons.search),
                  ),
                ),
                // Task List
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tasks.isEmpty
                                    ? Icons.person_outline
                                    : Icons.search_off,
                                size: 64,
                                color: AppTheme.gray300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _tasks.isEmpty
                                    ? 'No individual tasks yet'
                                    : 'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.gray600,
                                ),
                              ),
                              if (_tasks.isEmpty) ...[
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Add First Individual Task',
                                  onPressed: () => _showAddEditTaskScreen(),
                                  icon: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              left: isMobile ? 16 : 24,
                              right: isMobile ? 16 : 24,
                              bottom: isMobile ? 16 : 24,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.gray50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.gray200),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: isMobile ? 16 : 24,
                                  headingRowColor: WidgetStateProperty.all(
                                    AppTheme.blue50,
                                  ),
                                  dataRowColor: WidgetStateProperty.all(
                                    Colors.white,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Task Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Assigned To',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Deadline',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _filteredTasks
                                      .map((task) => _buildTaskDataRow(task))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final VoidCallback onSaved;

  const AddEditTaskScreen({super.key, this.task, required this.onSaved});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _descriptionController.text = widget.task!.description;
      _selectedStaffId = widget.task!.assignedStaff['_id'];
      try {
        if (widget.task!.deadline != null) {
          _deadline = DateTime.parse(widget.task!.deadline!);
        }
      } catch (e) {
        developer.log('Error parsing deadline: $e');
      }
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = (response['staff'] as List)
              .map((s) => Staff.fromJson(s))
              .toList();
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      developer.log('Error loading staff: $e');
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deadlineStr = _deadline!.toIso8601String();

      if (widget.task == null) {
        await _apiService.createTask(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
        );
      } else {
        await _apiService.updateTask(
          taskId: widget.task!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null
                  ? 'Task created successfully'
                  : 'Task updated successfully',
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextInput(
                label: 'Task Name',
                hint: 'Enter task name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter task name';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomTextInput(
                label: 'Description',
                hint: 'Enter task description',
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deadline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isLoading ? null : _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _deadline != null
                                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                  : 'Select deadline',
                              style: TextStyle(
                                fontSize: 16,
                                color: _deadline != null
                                    ? AppTheme.foreground
                                    : AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.mutedForeground,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoadingStaff
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleSelectDropdown<Staff>(
                      label: 'Assign to Staff',
                      isRequired: true,
                      options: _staff,
                      selectedId: _selectedStaffId,
                      onSelectionChanged: (value) {
                        setState(() => _selectedStaffId = value);
                      },
                      getDisplayText: (staff) => staff.fullName,
                      getSubText: (staff) => staff.designation ?? staff.role,
                      getId: (staff) => staff.id,
                      hintText: 'Select staff member',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a staff member';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isLoading
                    ? 'Saving...'
                    : (widget.task == null ? 'Create Task' : 'Update Task'),
                onPressed: _isLoading ? null : _saveTask,
                size: ButtonSize.lg,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
