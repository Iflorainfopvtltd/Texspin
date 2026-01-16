import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/staff_task_details_dialog.dart';
import '../widgets/staff_task_submission_dialog.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_button.dart';

class StaffDepartmentTasksScreen extends StatefulWidget {
  const StaffDepartmentTasksScreen({super.key});

  @override
  State<StaffDepartmentTasksScreen> createState() =>
      _StaffDepartmentTasksScreenState();
}

class _StaffDepartmentTasksScreenState
    extends State<StaffDepartmentTasksScreen> {
  final ApiService _apiService = ApiService();
  List<DepartmentTask> _tasks = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  List<DepartmentTask> _filteredTasks = [];
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
      final response = await _apiService.getDepartmentTasks();
      if (response['tasks'] != null) {
        setState(() {
          List<DepartmentTask> parsedTasks = (response['tasks'] as List)
              .map((task) => DepartmentTask.fromJson(task))
              .toList();

          parsedTasks.sort((a, b) {
            final aIsPending = a.status.toLowerCase() == 'pending';
            final bIsPending = b.status.toLowerCase() == 'pending';

            if (aIsPending && !bIsPending) return -1;
            if (!aIsPending && bIsPending) return 1;

            return b.createdAt.compareTo(a.createdAt);
          });

          _tasks = parsedTasks;
          _filteredTasks = parsedTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTaskResponse(
    String taskId,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToDepartmentTask(
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
        switch (statusFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'revision':
            return status == 'revision';
          case 'accepted':
            return status == 'completed' || status == 'accepted';
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
        CustomTextInput(
          hint: 'Search by task name...',
          controller: _searchController,
          onChanged: (value) => _filterTasks(value),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Revision', 'revision'),
              const SizedBox(width: 8),
              _buildFilterChip('Accepted', 'accepted'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
            ],
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
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text(
          'Department Tasks',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: _buildFilterSection(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _filteredTasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(_filteredTasks[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DepartmentTask task) {
    final isPending = task.status.toLowerCase() == 'pending';
    final isAccepted = task.status.toLowerCase() == 'accepted';
    final isRevision = task.status.toLowerCase() == 'revision';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                _buildStatusBadge(task),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(color: AppTheme.gray600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
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
            const Divider(),
            const SizedBox(height: 8),

            // Actions
            Column(
              children: [
                CustomButton(
                  text: 'View Details',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => StaffTaskDetailsDialog(task: task),
                    );
                  },
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.default_,
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),

                if (isAccepted || isRevision) ...[
                  CustomButton(
                    text: isRevision ? 'Submit Revision' : 'Submit Task',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => StaffTaskSubmissionDialog(
                          task: task,
                          onSubmitted: _loadTasks,
                        ),
                      );
                    },
                    variant: ButtonVariant.default_,
                    size: ButtonSize.default_,
                    isFullWidth: true,
                    icon: const Icon(
                      Icons.upload,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],

                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Accept',
                          onPressed: () =>
                              _handleTaskResponse(task.id, 'accepted'),
                          variant: ButtonVariant
                              .default_, // Greenish if custom theme supports it, else default
                          size: ButtonSize.default_,
                          icon: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Reject',
                          onPressed: () => _showRejectDialog(task.id),
                          variant: ButtonVariant.destructive,
                          size: ButtonSize.default_,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DepartmentTask task) {
    Color color;
    switch (task.status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        color = AppTheme.green500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      case 'pending':
        color = AppTheme.yellow500;
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
