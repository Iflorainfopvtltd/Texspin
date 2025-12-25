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
          _tasks = (response['tasks'] as List)
              .map((task) => Task.fromJson(task))
              .toList();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 600,
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _tasks.isEmpty
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
                          rows: _tasks.map((task) {
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
                                DataCell(Text(task.description)),
                                DataCell(Text(_formatDate(task.deadline))),
                                DataCell(
                                  Text(
                                    '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}',
                                  ),
                                ),
                                DataCell(_buildStatusBadge(task.status)),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
