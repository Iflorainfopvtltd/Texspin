import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'staff_individual_task_details_dialog.dart';
import 'staff_individual_task_submission_dialog.dart';
import 'custom_text_input.dart';

class StaffIndividualTasksDialog extends StatefulWidget {
  const StaffIndividualTasksDialog({super.key});

  @override
  State<StaffIndividualTasksDialog> createState() =>
      _StaffIndividualTasksDialogState();
}

class _StaffIndividualTasksDialogState
    extends State<StaffIndividualTasksDialog> {
  final ApiService _apiService = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  List<Task> _filteredTasks = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
          List<Task> parsedTasks = (response['tasks'] as List)
              .map((task) => Task.fromJson(task))
              .toList();

          parsedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _tasks = parsedTasks;
          _filteredTasks = _tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTaskResponse(
    String taskId,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToTask(
        taskId: taskId,
        status: status,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task $status successfully')));
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String taskId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            CustomTextInput(
              label: 'Reason',
              controller: reasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleTaskResponse(
                  taskId,
                  'rejected',
                  reason: reasonController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
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
        // Adjust these cases based on your actual status values
        switch (statusFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'revision':
            return status == 'revision';
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
        final desc = task.description.toLowerCase();
        final searchLower = query.toLowerCase();
        return taskName.contains(searchLower) || desc.contains(searchLower);
      }).toList();
    }

    _filteredTasks = filtered;
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextInput(
                label: 'Search',
                hint: 'Search by task name...',
                controller: _searchController,
                onChanged: (value) => _filterTasks(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Revision', 'revision'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ),
      ],
    );
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Individual Tasks',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _filteredTasks.isEmpty
                  ? const Center(child: Text('No tasks found'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Deadline')),
                            DataColumn(label: Text('Assigned To')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredTasks.map((task) {
                            final isPending =
                                task.status.toLowerCase() == 'pending';
                            final isAccepted =
                                task.status.toLowerCase() == 'accepted' ||
                                task.status.toLowerCase() == 'approved';
                            final isRevision =
                                task.status.toLowerCase() == 'revision';
                            return DataRow(
                              cells: [
                                DataCell(Text(task.name)),
                                DataCell(
                                  SizedBox(
                                    width: 300,
                                    child: Text(task.description),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    task.deadline != null
                                        ? _formatDate(task.deadline!)
                                        : (task.isRecurringActive == true
                                              ? 'Recurring'
                                              : 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}',
                                  ),
                                ),
                                DataCell(_buildStatusBadge(task)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: AppTheme.blue600,
                                        ),
                                        tooltip: 'View Details',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                StaffIndividualTaskDetailsDialog(
                                                  task: task,
                                                ),
                                          );
                                        },
                                      ),
                                      if (isAccepted || isRevision)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.upload,
                                            color: AppTheme.blue600,
                                          ),
                                          tooltip: isRevision
                                              ? 'Submit Revision'
                                              : 'Submit Task',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  StaffIndividualTaskSubmissionDialog(
                                                    task: task,
                                                    onSubmitted: _loadTasks,
                                                  ),
                                            );
                                          },
                                        ),
                                      if (isPending) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: AppTheme.green600,
                                          ),
                                          tooltip: 'Accept',
                                          onPressed: () => _handleTaskResponse(
                                            task.id,
                                            'approved',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: AppTheme.red500,
                                          ),
                                          tooltip: 'Reject',
                                          onPressed: () =>
                                              _showRejectDialog(task.id),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Task task) {
    Color color;
    switch (task.status.toLowerCase()) {
      case 'accepted':
      case 'approved':
      case 'completed':
        color = AppTheme.green500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      case 'pending':
        color = AppTheme.yellow500;
        break;
      case 'revision':
        color = AppTheme.blue500;
        break;
      default:
        color = AppTheme.blue500;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        task.status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (task.status.toLowerCase() == 'rejected' ||
        task.status.toLowerCase() == 'revision') {
      return Tooltip(
        message: task.rejectionReason ?? 'No reason provided',
        triggerMode: TooltipTriggerMode.tap,
        child: badge,
      );
    }

    return badge;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
