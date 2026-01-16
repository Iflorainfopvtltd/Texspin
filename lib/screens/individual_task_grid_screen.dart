import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/task_card.dart';
import '../widgets/individual_task_management_dialog.dart';
import 'dart:developer' as developer;

class IndividualTaskGridScreen extends StatefulWidget {
  const IndividualTaskGridScreen({super.key});

  @override
  State<IndividualTaskGridScreen> createState() =>
      _IndividualTaskGridScreenState();
}

class _IndividualTaskGridScreenState extends State<IndividualTaskGridScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      developer.log('Error loading tasks: $e', name: 'IndividualTaskGrid');
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
          case 'approved':
            return status == 'completed' || status == 'approved';
          case 'rejected':
            return status == 'rejected';
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

  void _showAddEditTaskDialog({Task? task}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditIndividualTaskDialog(
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
        builder: (context) => AddEditIndividualTaskDialog(
          task: task,
          onSaved: () {
            Navigator.of(context).pop();
            _loadTasks();
          },
        ),
      );
    }
  }

  Future<void> _sendReminder(String taskId) async {
    try {
      final response = await _apiService.sendIndividualTaskReminder(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Individual Tasks'),
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddEditTaskDialog(),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [_buildStaffAssignedTasksView(), _buildMyTasksView()],
      ),
    );
  }

  Widget _buildStaffAssignedTasksView() {
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
        // Search Bar and Filters
        Padding(
          padding: const EdgeInsets.all(16),
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
                    _buildFilterChip('Approved', 'approved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Task List with Dynamic Heights
        Expanded(
          child: _filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 64,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _tasks.isEmpty
                            ? 'No individual tasks yet'
                            : 'No tasks found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.gray600,
                        ),
                      ),
                      if (_tasks.isEmpty) ...[
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Add First Individual Task',
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
                        child: TaskCard(
                          task: task,
                          onEdit: () => _showAddEditTaskDialog(task: task),
                          onDelete: () => _deleteTask(task.id),
                          onRefresh: _loadTasks,
                          onReminder: () => _sendReminder(task.id),
                          showActions: true,
                          isCompact: false,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMyTasksView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.assignment_ind, size: 64, color: AppTheme.gray300),
          SizedBox(height: 16),
          Text(
            'No personal tasks assigned',
            style: TextStyle(fontSize: 18, color: AppTheme.gray600),
          ),
        ],
      ),
    );
  }
}
