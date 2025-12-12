import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/task_card.dart';
import '../widgets/task_management_dialog.dart';
import 'dart:developer' as developer;

class TaskGridScreen extends StatefulWidget {
  const TaskGridScreen({super.key});

  @override
  State<TaskGridScreen> createState() => _TaskGridScreenState();
}

class _TaskGridScreenState extends State<TaskGridScreen> {
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
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'TaskGrid');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Task> filtered = _tasks;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((task) => 
        task.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
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

  void _showAddEditTaskDialog({Task? task}) {
    showDialog(
      context: context,
      builder: (context) => AddEditTaskDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Individual Tasks'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const TaskManagementDialog(),
              );
            },
            tooltip: 'Table View',
          ),
        ],
      ),
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
                            _buildFilterChip('In Progress', 'in progress'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Submitted', 'submitted'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Completed', 'completed'),
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
                                  onPressed: () => _showAddEditTaskDialog(),
                                  icon: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate number of columns based on screen width
                              int crossAxisCount = 1;
                              if (constraints.maxWidth > 1200) {
                                crossAxisCount = 3;
                              } else if (constraints.maxWidth > 800) {
                                crossAxisCount = 2;
                              }
                              
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _filteredTasks[index];
                                  return TaskCard(
                                    task: task,
                                    isCompact: crossAxisCount > 1,
                                    onEdit: () => _showAddEditTaskDialog(task: task),
                                    onDelete: () => _deleteTask(task.id),
                                    onRefresh: _loadTasks,
                                  );
                                },
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
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.gray300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}