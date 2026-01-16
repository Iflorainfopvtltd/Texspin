import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/department_task_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import '../utils/shared_preferences_manager.dart';
import 'staff_task_submission_dialog.dart';
import 'dart:developer' as developer;

class DepartmentTaskManagementDialog extends StatefulWidget {
  const DepartmentTaskManagementDialog({super.key});

  @override
  State<DepartmentTaskManagementDialog> createState() =>
      _DepartmentTaskManagementDialogState();
}

class _DepartmentTaskManagementDialogState
    extends State<DepartmentTaskManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<DepartmentTask> _tasks = [];
  List<DepartmentTask> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  // My Tasks View State
  String? _currentStaffId;
  final TextEditingController _myTasksSearchController =
      TextEditingController();
  String _myTasksSelectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadTasks();
    _loadCurrentStaffId();
  }

  Future<void> _loadCurrentStaffId() async {
    final staffId = await SharedPreferencesManager.getStaffId();
    if (mounted) {
      setState(() {
        _currentStaffId = staffId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _myTasksSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDepartmentTasks();
      if (response['tasks'] != null) {
        setState(() {
          _tasks = (response['tasks'] as List)
              .map((task) => DepartmentTask.fromJson(task))
              .toList();
          _filteredTasks = _tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error loading department tasks: $e',
        name: 'DepartmentTaskManagement',
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTasks(String query) {
    setState(() {
      _applyFilters(query, _selectedFilter);
    });
  }

  void _applyFilters(String query, String statusFilter) {
    var filtered = _tasks;

    // Apply status filter
    if (statusFilter != 'all') {
      filtered = filtered.where((task) {
        final status = task.status.toLowerCase();
        switch (statusFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'accepted':
            return status == 'completed' || status == 'accepted';
          case 'rejected':
            return status == 'rejected';
          case 'revision':
            return status == 'revision';
          default:
            return true;
        }
      }).toList();
    }

    // Apply text filter
    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        final taskName = task.name.toLowerCase();
        final staffName =
            '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                .toLowerCase();
        final searchLower = query.toLowerCase();
        return taskName.contains(searchLower) ||
            staffName.contains(searchLower);
      }).toList();
    }

    _filteredTasks = filtered;
  }

  void _showAddEditTaskDialog({DepartmentTask? task}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditDepartmentTaskDialog(
            task: task,
            onSaved: () {
              Navigator.of(context).pop();
              _loadTasks();
            },
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AddEditDepartmentTaskDialog(
          task: task,
          onSaved: () {
            Navigator.of(context).pop();
            _loadTasks();
          },
        ),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department Task'),
        content: const Text(
          'Are you sure you want to delete this department task?',
        ),
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
        await _apiService.deleteDepartmentTask(taskId: taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Department task deleted successfully'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.green500;
      case 'accepted':
        return AppTheme.green500;
      case 'submitted':
      case 'revision':
        return AppTheme.blue500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
    }
  }

  void _showAcceptDialog(DepartmentTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Task'),
        content: Text('Are you sure you want to accept "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Accept',
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

  void _showRejectDialog(DepartmentTask task) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.red500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.red500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Reject Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to reject "${task.name}"? This action cannot be undone.',
                style: const TextStyle(color: AppTheme.gray600, height: 1.5),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.gray600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
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
                      await _reviewTask(
                        task.id,
                        'rejected',
                        rejectionReason: reasonController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReassignDialog(DepartmentTask task) {
    showDialog(
      context: context,
      builder: (context) =>
          ReassignDepartmentTaskDialog(task: task, onReassigned: _loadTasks),
    );
  }

  Future<void> _sendReminder(String taskId) async {
    try {
      final response = await _apiService.sendDepartmentTaskReminder(
        taskId: taskId,
      );

      if (mounted) {
        final successMessage =
            response['message']?.toString() ?? 'Reminder sent successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
      }
    } catch (e) {
      developer.log('Error sending reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error sending reminder: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _reviewTask(
    String taskId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final response = await _apiService.reviewDepartmentTask(
        taskId: taskId,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        // Optimistic update
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(
              status: status,
              rejectionReason: rejectionReason,
            );
            // Re-apply filters to update the view
            _applyFilters(_searchController.text, _selectedFilter);
          }
        });

        // Use API response message if available, otherwise use default
        String successMessage;
        if (response['message'] != null) {
          successMessage = response['message'].toString();
        } else {
          successMessage = status == 'completed'
              ? 'Task accepted successfully'
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
        await _loadTasks(); // Refresh the task list
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadTaskFile(DepartmentTask task) async {
    String? fileUrl;
    String? fileName;

    // Check if task has viewUrl (Preferred as per user request)
    if (task.viewUrl != null && task.viewUrl!.isNotEmpty) {
      fileUrl = task.viewUrl;
      fileName = task.fileName ?? 'dept_task_file';
    }
    // Check if task has downloadUrl (new structure)
    else if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
      fileUrl = task.downloadUrl;
      fileName = task.fileName ?? 'dept_task_file';
    }
    // Fallback to attachments (old structure)
    else if (task.attachments != null && task.attachments!.isNotEmpty) {
      final attachment = task.attachments!.first;
      fileUrl = attachment['fileUrl'] ?? '';
      fileName = attachment['fileName'] ?? 'dept_task_file';
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

    await _downloadFile(fileUrl, fileName ?? 'file');
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Downloading $fileName...')),
            ],
          ),
          backgroundColor: AppTheme.blue600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Construct full URL using ApiService baseUrl
      // Handle case where fileUrl might already contain baseUrl or be absolute
      final String fullUrl = fileUrl.startsWith('http')
          ? fileUrl
          : ApiService.baseUrl + fileUrl;

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
                Expanded(child: Text('Error downloading $fileName: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.gray700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters(_searchController.text, _selectedFilter);
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
    );
  }

  DataRow _buildTaskDataRow(DepartmentTask task) {
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
            width: 150,
            child: Text(
              task.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              assignedStaffName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          Text(
            task.deadline != null ? _formatDate(task.deadline!) : 'N/A',
            style: const TextStyle(color: AppTheme.gray700),
          ),
        ),
        DataCell(
          (task.status.toLowerCase() == 'rejected' ||
                  task.status.toLowerCase() == 'revision')
              ? Tooltip(
                  message: task.rejectionReason ?? 'No reason provided',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        task.status,
                      ).withValues(alpha: 0.1),
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
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              // For submitted tasks: show download, accept and reject
              if (task.status.toLowerCase() == 'submitted') ...[
                // Download button (if downloadUrl is available)
                if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadTaskFile(task),
                    tooltip: 'Download File',
                  ),
                // Accept button
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.green600,
                  ),
                  onPressed: () => _showAcceptDialog(task),
                  tooltip: 'Accept',
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
              ]
              // For rejected tasks: show reassign button
              else if (task.status.toLowerCase() == 'rejected') ...[
                IconButton(
                  icon: const Icon(Icons.person_add, color: AppTheme.blue600),
                  onPressed: () => _showReassignDialog(task),
                  tooltip: 'Reassign',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.red500,
                  ),
                  onPressed: () => _deleteTask(task.id),
                  tooltip: 'Delete',
                ),
              ] else ...[
                // For other tasks: show download (if available), edit and delete
                // Download button (if downloadUrl is available or has attachments)
                if ((task.downloadUrl != null &&
                        task.downloadUrl!.isNotEmpty) ||
                    (task.attachments != null && task.attachments!.isNotEmpty))
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadTaskFile(task),
                    tooltip: 'Download File',
                  ),
                // Reminder button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.send_outlined,
                      color: AppTheme.yellow500,
                    ),
                    onPressed: () => _sendReminder(task.id),
                    tooltip: 'Send Reminder',
                  ),
                // Edit button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.blue600,
                    ),
                    onPressed: () => _showAddEditTaskDialog(task: task),
                    tooltip: 'Edit',
                  ),
                // Delete button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.red500,
                    ),
                    onPressed: () => _deleteTask(task.id),
                    tooltip: 'Delete',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Department Tasks'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.gray600,
            indicatorColor: AppTheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Staff Assigned Task'),
              Tab(text: 'My Tasks'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStaffAssignedTasksView(isMobile),
            _buildMyTasksView(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: () => _showAddEditTaskDialog(),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffAssignedTasksView(isMobile),
                      _buildMyTasksView(),
                    ],
                  ),
                ),
              ],
            ),
            // Floating Action Button
            if (_tabController.index == 0)
              Positioned(
                right: isMobile ? 16 : 24,
                bottom: isMobile ? 16 : 24,
                child: FloatingActionButton(
                  onPressed: () => _showAddEditTaskDialog(),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.gray600,
        indicatorColor: AppTheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Staff Assigned Task'),
          Tab(text: 'My Tasks'),
        ],
      ),
    );
  }

  Widget _buildStaffAssignedTasksView(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.red500),
              const SizedBox(height: 16),
              const Text(
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
                style: const TextStyle(color: AppTheme.gray600),
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
      );
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              CustomTextInput(
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
              const SizedBox(height: 16),
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Submitted', 'submitted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Revision', 'revision'),
                  ],
                ),
              ),
            ],
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
                        _tasks.isEmpty ? Icons.business : Icons.search_off,
                        size: 64,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _tasks.isEmpty
                            ? 'No department tasks yet'
                            : 'No tasks found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.gray600,
                        ),
                      ),
                      if (_tasks.isEmpty) ...[
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Add First Department Task',
                          onPressed: () => _showAddEditTaskDialog(),
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ],
                  ),
                )
              : isMobile
              ? RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return DepartmentTaskCard(
                        task: task,
                        onEdit: () => _showAddEditTaskDialog(task: task),
                        onDelete: () => _deleteTask(task.id),
                        onRefresh: _loadTasks,
                      );
                    },
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
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
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.blue50,
                        ),
                        dataRowColor: WidgetStateProperty.all(Colors.white),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Task Name',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Assigned To',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Deadline',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
      ],
    );
  }

  Widget _buildMyTasksView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter tasks for current user
    final myTasks = _tasks.where((task) {
      if (_currentStaffId == null) return false;
      // Check assignedStaff map for ID
      final assignedId =
          task.assignedStaff['id'] ??
          task.assignedStaff['_id'] ??
          task.assignedStaff['staffId'];
      return assignedId == _currentStaffId;
    }).toList();

    // Apply local filters
    final searchText = _myTasksSearchController.text.toLowerCase();
    final filteredMyTasks = myTasks.where((task) {
      // Status Filter
      if (_myTasksSelectedFilter != 'all') {
        final status = task.status.toLowerCase();
        bool matches = false;
        if (_myTasksSelectedFilter == 'pending')
          matches = status == 'pending';
        else if (_myTasksSelectedFilter == 'submitted')
          matches = status == 'submitted';
        else if (_myTasksSelectedFilter == 'accepted')
          matches =
              status == 'completed' ||
              status ==
                  'accepted'; // Accepted instead of approved for dept tasks?
        else if (_myTasksSelectedFilter == 'rejected')
          matches = status == 'rejected';
        else if (_myTasksSelectedFilter == 'revision')
          matches = status == 'revision';

        if (!matches) return false;
      }

      // Search Filter
      if (searchText.isNotEmpty) {
        return task.name.toLowerCase().contains(searchText);
      }
      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        // Filter Section
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomTextInput(
                hint: 'Search by task name...',
                controller: _myTasksSearchController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMyTasksFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Submitted', 'submitted'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Accepted', 'completed'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Rejected', 'rejected'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Revision', 'revision'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Table or List
        Expanded(
          child: filteredMyTasks.isEmpty
              ? const Center(child: Text('No personal tasks assigned'))
              : isMobile
              ? RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMyTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildMyTaskCard(filteredMyTasks[index]);
                    },
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
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
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.blue50,
                        ),
                        dataRowColor: WidgetStateProperty.all(Colors.white),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Task Name',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Assigned To',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Deadline',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: filteredMyTasks
                            .map((task) => _buildMyTasksDataRow(task))
                            .toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMyTaskCard(DepartmentTask task) {
    final assignedStaffName =
        '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
            .trim();

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDepartmentTaskStatusColor(
                      task.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getDepartmentTaskStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.gray600,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Info Row
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedStaffName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  task.deadline != null ? _formatDate(task.deadline!) : 'N/A',
                  style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Actions Section
            Center(child: _buildMyTasksMobileActions(context, task)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksMobileActions(BuildContext context, DepartmentTask task) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Download Button (if available)
        if ((task.downloadUrl != null && task.downloadUrl!.isNotEmpty) ||
            (task.attachments != null && task.attachments!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CustomButton(
              text: 'Download File',
              onPressed: () => _downloadFile(
                task.downloadUrl ?? '',
                task.fileName ?? 'file',
              ),
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              icon: const Icon(Icons.download, size: 16),
              isFullWidth: true,
            ),
          ),

        // Status based actions
        if (task.status.toLowerCase() == 'pending')
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  onPressed: () => _updateMyTaskStatus(task.id, 'ongoing'),
                  variant: ButtonVariant.default_,
                  size: ButtonSize.sm,
                  icon: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  onPressed: () => _showMyTaskRejectDialog(task),
                  variant: ButtonVariant.destructive,
                  size: ButtonSize.sm,
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.white),
                  isFullWidth: true,
                ),
              ),
            ],
          )
        else if (task.status.toLowerCase() == 'ongoing' ||
            task.status.toLowerCase() == 'in progress' ||
            task.status.toLowerCase() == 'accepted' ||
            task.status.toLowerCase() == 'approved' ||
            task.status.toLowerCase() == 'revision')
          CustomButton(
            text: 'Update Work',
            onPressed: () {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StaffTaskSubmissionDialog(
                      task: task,
                      onSubmitted: _loadTasks,
                    ),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => StaffTaskSubmissionDialog(
                    task: task,
                    onSubmitted: _loadTasks,
                  ),
                );
              }
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
            isFullWidth: true,
          ),
      ],
    );
  }

  Widget _buildMyTasksFilterChip(String label, String value) {
    final isSelected = _myTasksSelectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.gray700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _myTasksSelectedFilter = value;
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
    );
  }

  DataRow _buildMyTasksDataRow(DepartmentTask task) {
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
            width: 150,
            child: Text(
              task.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                  .trim(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
              color: _getDepartmentTaskStatusColor(
                task.status,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: TextStyle(
                color: _getDepartmentTaskStatusColor(task.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(_buildMyTasksActions(task)),
      ],
    );
  }

  Color _getDepartmentTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.yellow600;
      case 'submitted':
        return AppTheme.blue600;
      case 'accepted':
      case 'completed':
        return AppTheme.green600;
      case 'rejected':
        return AppTheme.red600;
      default:
        return AppTheme.gray600;
    }
  }

  Widget _buildMyTasksActions(DepartmentTask task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty ||
            (task.attachments != null && task.attachments!.isNotEmpty))
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.blue600),
            onPressed: () =>
                _downloadFile(task.downloadUrl ?? '', task.fileName ?? 'file'),
            tooltip: 'Download File',
          ),
        if (task.status.toLowerCase() == 'pending') ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppTheme.green600),
            onPressed: () => _updateMyTaskStatus(
              task.id,
              'ongoing',
            ), // Ongoing? Or accepted? API uses accepted usually.
            tooltip: 'Accept',
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppTheme.red600),
            onPressed: () => _showMyTaskRejectDialog(task),
            tooltip: 'Reject',
          ),
        ] else if (task.status.toLowerCase() == 'ongoing' ||
            task.status.toLowerCase() == 'in progress' ||
            task.status.toLowerCase() == 'accepted' ||
            task.status.toLowerCase() == 'approved' ||
            task.status.toLowerCase() == 'revision') ...[
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppTheme.blue600),
            onPressed: () {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StaffTaskSubmissionDialog(
                      task: task,
                      onSubmitted: _loadTasks,
                    ),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => StaffTaskSubmissionDialog(
                    task: task,
                    onSubmitted: _loadTasks,
                  ),
                );
              }
            },
            tooltip: 'Update Work',
          ),
        ],
      ],
    );
  }

  Future<void> _updateMyTaskStatus(String taskId, String status) async {
    try {
      // API expects 'accepted' not 'ongoing'?
      // Individual task used 'ongoing' -> 'approved'.
      // Department task respond uses 'status' param.
      // If user clicks Accept, we usually send 'accepted' or 'ongoing'.
      // Based on API: /texspin/api/department-task/:id/accept
      // It likely expects 'accepted'.
      final apiStatus = status == 'ongoing' ? 'accepted' : status;

      await _apiService.respondToDepartmentTask(
        taskId: taskId,
        status: apiStatus,
      );
      if (mounted) {
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(status: apiStatus);
            // Also update filtered tasks if needed, but since filteredTasks is derived or referencing _tasks?
            // If filteredTasks == _tasks reference, it's updated.
            // If it's a new list, we need to re-apply filters or update it too.
            // _filteredTasks = _tasks; // Re-applying filters is safer but updating local ref works if it's the same list check.
            // Let's re-run filter just in case or just update list.

            // Re-apply filters to ensure view stays consistent
            // _applyFilters(_searchController.text, _selectedFilter); // This might switch views unexpectedly? No.
            // Actually _buildMyTasksView derives from _tasks dynamically.
            // _buildStaffAssignedTasks uses _filteredTasks.
            // So for My Tasks, updating _tasks is enough.
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        await _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMyTaskRejectDialog(DepartmentTask task) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.red500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.red500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Reject Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason for rejecting this task. This will be visible to the assigner.',
                style: TextStyle(color: AppTheme.gray600, height: 1.5),
              ),
              const SizedBox(height: 24),
              CustomTextInput(
                label: 'Rejection Reason',
                hint: 'Enter your reason here...',
                controller: reasonController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.gray600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (reasonController.text.isNotEmpty) {
                        Navigator.pop(context);
                        try {
                          await _apiService.respondToDepartmentTask(
                            taskId: task.id,
                            status: 'rejected',
                            rejectionReason: reasonController.text,
                          );
                          if (mounted) {
                            setState(() {
                              final index = _tasks.indexWhere(
                                (t) => t.id == task.id,
                              );
                              if (index != -1) {
                                _tasks[index] = _tasks[index].copyWith(
                                  status: 'rejected',
                                  rejectionReason: reasonController.text,
                                );
                              }
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task rejected'),
                                backgroundColor: AppTheme.red500,
                              ),
                            );
                            await _loadTasks();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a reason'),
                            backgroundColor: AppTheme.red500,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddEditDepartmentTaskDialog extends StatefulWidget {
  final DepartmentTask? task;
  final VoidCallback onSaved;

  const AddEditDepartmentTaskDialog({
    super.key,
    this.task,
    required this.onSaved,
  });

  @override
  State<AddEditDepartmentTaskDialog> createState() =>
      _AddEditDepartmentTaskDialogState();
}

class _AddEditDepartmentTaskDialogState
    extends State<AddEditDepartmentTaskDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _reminderDaysController = TextEditingController();

  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _descriptionController.text = widget.task!.description;
      _selectedStaffId = widget.task!.assignedStaff['_id'];
      _isRecurring = widget.task!.isRecurringActive ?? false;
      if (widget.task!.frequency != null) {
        _frequencyController.text = widget.task!.frequency.toString();
      }
      if (widget.task!.reminderDays != null &&
          widget.task!.reminderDays!.isNotEmpty) {
        _reminderDaysController.text = widget.task!.reminderDays!.join(', ');
      }
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
    _frequencyController.dispose();
    _reminderDaysController.dispose();
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

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str
        .toLowerCase()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  int _calculateDaysFromNow(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(
      DateTime(now.year, now.month, now.day),
    );
    return difference.inDays;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // If we have an existing deadline that is in the past, allow selecting from that date
    // otherwise restrict to today onwards
    final firstDate = _deadline != null && _deadline!.isBefore(now)
        ? _deadline!
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isRecurring) {
      if (_deadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a deadline'),
            backgroundColor: AppTheme.red500,
          ),
        );
        return;
      }
    } else {
      if (_frequencyController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter frequency days'),
            backgroundColor: AppTheme.red500,
          ),
        );
        return;
      }
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
      String? deadlineStr;
      if (!_isRecurring && _deadline != null) {
        // Set time to noon to avoid timezone shift issues
        final noonDate = DateTime(
          _deadline!.year,
          _deadline!.month,
          _deadline!.day,
          12,
          0,
          0,
        );
        deadlineStr = noonDate.toIso8601String().split('T')[0];
      }

      int? frequency;
      if (_isRecurring && _frequencyController.text.isNotEmpty) {
        frequency = int.tryParse(_frequencyController.text.trim());
      }

      List<int>? reminderDays;
      if (!_isRecurring && _reminderDaysController.text.isNotEmpty) {
        reminderDays = _reminderDaysController.text
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((e) => e != null)
            .cast<int>()
            .toList();
      }

      if (widget.task == null) {
        await _apiService.createDepartmentTask(
          name: _toTitleCase(_nameController.text.trim()),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
          isRecurringActive: _isRecurring,
          frequency: frequency,
          reminderDays: reminderDays,
        );
      } else {
        await _apiService.updateDepartmentTask(
          taskId: widget.task!.id,
          name: _toTitleCase(_nameController.text.trim()),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
          isRecurringActive: _isRecurring,
          frequency: frequency,
          reminderDays: reminderDays,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null
                  ? 'Department task created successfully'
                  : 'Department task updated successfully',
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.task == null
                      ? 'Add Department Task'
                      : 'Edit Department Task',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 20),
        CustomTextInput(
          label: 'Task Name',
          hint: 'Enter department task name',
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
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // Recurring Task Toggle
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                  });
                },
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Is Repeated?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Deadline or Frequency
        if (_isRecurring)
          CustomTextInput(
            label: 'Reminder (Days)',
            hint: 'e.g. 5',
            controller: _frequencyController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isRecurring && (value == null || value.trim().isEmpty)) {
                return 'Please enter frequency days';
              }
              final n = int.tryParse(value!);
              if (n == null || n <= 0) {
                return 'Please enter a valid number';
              }
              return null;
            },
            enabled: !_isLoading,
          )
        else
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
              if (_deadline != null) const SizedBox(height: 8),
              if (_deadline != null)
                Text(
                  'This task has assigned ${_calculateDaysFromNow(_deadline!)} days',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),

        // Task Reminder Days (only for non-recurring tasks)
        if (!_isRecurring)
          CustomTextInput(
            label: 'Task Reminder (Days)',
            hint: 'e.g. 4',
            controller: _reminderDaysController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final parts = value.split(',');
                for (final part in parts) {
                  final n = int.tryParse(part.trim());
                  if (n == null || n < 0) {
                    return 'Enter valid numbers (0 or greater) separated by comma';
                  }
                  if (_deadline != null) {
                    final assignedDays = _calculateDaysFromNow(_deadline!);
                    if (n > assignedDays) {
                      return 'Reminder ($n) too large. Max: $assignedDays';
                    }
                  }
                }
              }
              return null;
            },
            enabled: !_isLoading,
          ),
        if (!_isRecurring) const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        if (!isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: _isLoading
                    ? 'Saving...'
                    : (widget.task == null ? 'Create' : 'Update'),
                onPressed: _isLoading ? null : _saveTask,
              ),
            ],
          )
        else
          CustomButton(
            text: _isLoading
                ? 'Saving...'
                : (widget.task == null ? 'Create' : 'Update'),
            onPressed: _isLoading ? null : _saveTask,
          ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.task == null
                ? 'Add Department Task'
                : 'Edit Department Task',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(child: formContent),
          ),
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: formContent),
        ),
      ),
    );
  }
}

class ReassignDepartmentTaskDialog extends StatefulWidget {
  final DepartmentTask task;
  final VoidCallback? onReassigned;

  const ReassignDepartmentTaskDialog({
    super.key,
    required this.task,
    this.onReassigned,
  });

  @override
  State<ReassignDepartmentTaskDialog> createState() =>
      _ReassignDepartmentTaskDialogState();
}

class _ReassignDepartmentTaskDialogState
    extends State<ReassignDepartmentTaskDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reminderDaysController = TextEditingController();
  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.task.deadline != null) {
        _deadline = DateTime.parse(widget.task.deadline!);
      }
      if (widget.task.reminderDays != null &&
          widget.task.reminderDays!.isNotEmpty) {
        _reminderDaysController.text = widget.task.reminderDays!.join(', ');
      }
      if (widget.task.assignedStaff.isNotEmpty) {
        _selectedStaffId =
            widget.task.assignedStaff['id'] ??
            widget.task.assignedStaff['_id'] ??
            widget.task.assignedStaff['staffId'];
      }
    } catch (e) {
      developer.log('Error parsing task data: $e');
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _reminderDaysController.dispose();
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

  Future<void> _reassignTask() async {
    if (_deadline == null && widget.task.isRecurringActive != true) {
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
      final deadlineStr = _deadline != null
          ? _deadline!.toIso8601String().split('T')[0]
          : null; // Format as YYYY-MM-DD if present

      int? reminderDays;
      if (_reminderDaysController.text.isNotEmpty) {
        reminderDays = int.tryParse(_reminderDaysController.text.trim());
      }

      await _apiService.reassignDepartmentTask(
        taskId: widget.task.id,
        assignedStaffId: _selectedStaffId!,
        deadline: deadlineStr,
        reminderDays: reminderDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department task reassigned successfully'),
            backgroundColor: AppTheme.green500,
          ),
        );
        Navigator.of(context).pop();
        widget.onReassigned?.call();
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reassign Department Task: ${widget.task.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 20),

        // Staff Selection
        _isLoadingStaff
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleSelectDropdown<Staff>(
                label: 'Reassign to Staff',
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
        const SizedBox(height: 16),

        // Deadline Selection
        if (widget.task.isRecurringActive == true)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.blue50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.blue100),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat, color: AppTheme.blue600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blue900,
                        ),
                      ),
                      Text(
                        'This task repeats automatically. Deadline is set by the schedule.',
                        style: TextStyle(fontSize: 12, color: AppTheme.blue800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Deadline',
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
                              : 'Select new deadline',
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

        // Task Reminder Days
        CustomTextInput(
          label: 'Task Reminder (Days)',
          hint: 'e.g. 4',
          controller: _reminderDaysController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final parts = value.split(',');
              for (final part in parts) {
                final n = int.tryParse(part.trim());
                if (n == null || n < 0) {
                  return 'Enter valid numbers (0 or greater)';
                }
              }
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // Action Buttons
        if (!isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: _isLoading ? 'Reassigning...' : 'Reassign Task',
                onPressed: _isLoading ? null : _reassignTask,
              ),
            ],
          )
        else
          CustomButton(
            text: _isLoading ? 'Reassigning...' : 'Reassign Task',
            onPressed: _isLoading ? null : _reassignTask,
          ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reassign: ${widget.task.name}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}

Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      children: [
        const Icon(Icons.business, color: AppTheme.gray600, size: 24),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Department Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppTheme.gray600),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
