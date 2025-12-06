import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import 'dart:developer' as developer;

class TaskManagementScreen extends StatefulWidget {
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
      case 'in progress':
        return AppTheme.blue500;
      default:
        return AppTheme.yellow500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Individual Tasks'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTaskScreen(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                  padding: const EdgeInsets.all(16),
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
                                _tasks.isEmpty ? Icons.task : Icons.search_off,
                                size: 64,
                                color: AppTheme.gray300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _tasks.isEmpty
                                    ? 'No tasks yet'
                                    : 'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.gray600,
                                ),
                              ),
                              if (_tasks.isEmpty) ...[
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Add First Task',
                                  onPressed: () => _showAddEditTaskScreen(),
                                  icon: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = _filteredTasks[index];
                              final assignedStaffName =
                                  '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                                      .trim();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.gray200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.gray900,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              task.status,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            task.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(
                                                task.status,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 20,
                                          ),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    size: 18,
                                                    color: AppTheme.blue600,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: AppTheme.red500,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showAddEditTaskScreen(
                                                task: task,
                                              );
                                            } else if (value == 'delete') {
                                              _deleteTask(task.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      task.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.gray600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: AppTheme.gray500,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            assignedStaffName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.gray700,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: AppTheme.gray500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDate(task.deadline),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.gray700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
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
        _deadline = DateTime.parse(widget.task!.deadline);
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
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
