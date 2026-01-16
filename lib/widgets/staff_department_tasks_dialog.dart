import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'staff_task_details_dialog.dart';
import 'staff_task_submission_dialog.dart';
import 'custom_text_input.dart';
import '../widgets/custom_button.dart';

class StaffDepartmentTasksDialog extends StatefulWidget {
  const StaffDepartmentTasksDialog({super.key});

  @override
  State<StaffDepartmentTasksDialog> createState() =>
      _StaffDepartmentTasksDialogState();
}

class _StaffDepartmentTasksDialogState
    extends State<StaffDepartmentTasksDialog> {
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
          _filteredTasks = _tasks;
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return _buildMobileView();
    }

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
                  'Department Tasks',
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
                  : _buildTaskTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView() {
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
                : ListView.builder(
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _buildMobileTaskCard(_filteredTasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTable() {
    return SingleChildScrollView(
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
            final isPending = task.status.toLowerCase() == 'pending';
            final isAccepted = task.status.toLowerCase() == 'accepted';
            final isRevision = task.status.toLowerCase() == 'revision';
            return DataRow(
              cells: [
                DataCell(Text(task.name)),
                DataCell(SizedBox(width: 300, child: Text(task.description))),
                DataCell(
                  Text(
                    task.deadline != null ? _formatDate(task.deadline!) : 'N/A',
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
                                StaffTaskDetailsDialog(task: task),
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
                              builder: (context) => StaffTaskSubmissionDialog(
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
                          onPressed: () =>
                              _handleTaskResponse(task.id, 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: AppTheme.red500,
                          ),
                          tooltip: 'Reject',
                          onPressed: () => _showRejectDialog(task.id),
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
    );
  }

  Widget _buildMobileTaskCard(DepartmentTask task) {
    final isPending = task.status.toLowerCase() == 'pending';
    final isAccepted = task.status.toLowerCase() == 'accepted';
    final isRevision = task.status.toLowerCase() == 'revision';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    // Since we are moving away from dialogs on mobile, we might want to push a page.
                    // But for now, using the dialog is acceptable unless user asked for full page here too.
                    // The requirement was "update card ui". The details view is separate.
                    // We'll stick to dialog for details for now to minimize changes, or use the pattern used in audits (full screen dialog style).
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

    if (!MediaQuery.of(context).size.width.isFinite ||
        MediaQuery.of(context).size.width >= 600) {
      // Only show tooltip on web/tablet if needed, or always.
      // Tooltips can be annoying on mobile list items on some clicks, but acceptable.
      if (task.status.toLowerCase() == 'rejected' ||
          task.status.toLowerCase() == 'revision') {
        return Tooltip(
          message: task.rejectionReason ?? 'No reason provided',
          triggerMode: TooltipTriggerMode.tap,
          child: badge,
        );
      }
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
