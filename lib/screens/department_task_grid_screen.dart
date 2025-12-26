import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import '../widgets/department_task_card.dart';

import 'dart:developer' as developer;

class DepartmentTaskGridScreen extends StatefulWidget {
  const DepartmentTaskGridScreen({super.key});

  @override
  State<DepartmentTaskGridScreen> createState() =>
      _DepartmentTaskGridScreenState();
}

class _DepartmentTaskGridScreenState extends State<DepartmentTaskGridScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<DepartmentTask> _tasks = [];
  List<DepartmentTask> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

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
      final response = await _apiService.getDepartmentTasks();
      if (response['tasks'] != null) {
        setState(() {
          _tasks = (response['tasks'] as List)
              .map((task) => DepartmentTask.fromJson(task))
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error loading department tasks: $e',
        name: 'DepartmentTaskGrid',
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<DepartmentTask> filtered = _tasks;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((task) {
        final status = task.status.toLowerCase();
        switch (_selectedFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'accepted':
            return status == 'completed' || status == 'accepted';
          case 'rejected':
            return status == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        final taskName = task.name.toLowerCase();
        final staffName =
            '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                .toLowerCase();
        return taskName.contains(query) || staffName.contains(query);
      }).toList();
    }

    setState(() {
      _filteredTasks = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  void _showAddEditTaskDialog({DepartmentTask? task}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(title: const Text('Department Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTaskDialog(),
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
                      'Error loading department tasks',
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
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search Bar
                      CustomTextInput(
                        controller: _searchController,
                        hint: 'Search by task name or staff name...',
                        onChanged: _onSearchChanged,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : const Icon(Icons.search),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
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
                            _buildFilterChip('Accepted', 'accepted'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Rejected', 'rejected'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Task Grid
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tasks.isEmpty
                                    ? Icons.business
                                    : Icons.search_off,
                                size: 64,
                                color: AppTheme.gray300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _tasks.isEmpty
                                    ? 'No department tasks yet'
                                    : 'No tasks found',
                                style: TextStyle(
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
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = _filteredTasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DepartmentTaskCard(
                                  task: task,
                                  isCompact: false,
                                  onEdit: () =>
                                      _showAddEditTaskDialog(task: task),
                                  onDelete: () => _deleteTask(task.id),
                                  onRefresh: _loadTasks,
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.gray700,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      // Set time to noon to avoid timezone shift issues
      final noonDate = DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
        12,
        0,
        0,
      );
      final deadlineStr = noonDate.toIso8601String().split('T')[0];

      if (widget.task == null) {
        await _apiService.createDepartmentTask(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
        );
      } else {
        await _apiService.updateDepartmentTask(
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 24),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
