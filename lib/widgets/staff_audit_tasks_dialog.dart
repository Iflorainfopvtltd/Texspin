import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'staff_audit_task_details_dialog.dart';
import 'staff_audit_task_submission_dialog.dart';
import 'custom_text_input.dart';

class StaffAuditTasksDialog extends StatefulWidget {
  const StaffAuditTasksDialog({super.key});

  @override
  State<StaffAuditTasksDialog> createState() => _StaffAuditTasksDialogState();
}

class _StaffAuditTasksDialogState extends State<StaffAuditTasksDialog> {
  final ApiService _apiService = ApiService();
  List<AuditMain> _tasks = [];
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
      final response = await _apiService.getAuditMains();
      List<dynamic> list = [];

      if (response.containsKey('auditMains')) {
        list = response['auditMains'] as List;
      } else if (response.containsKey('data')) {
        list = response['data'] as List;
      } else {
        // Try finding first list value
        for (var val in response.values) {
          if (val is List) {
            list = val;
            break;
          }
        }
      }

      setState(() {
        _tasks = list.map((item) => AuditMain.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTaskResponse(
    String auditId,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToAuditTask(
        auditId: auditId,
        status: status,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audit Task $status successfully')),
        );
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

  void _showRejectDialog(String auditId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Audit Task'),
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
                  auditId,
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
                  'Audit Tasks',
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
                  ? const Center(child: Text('No audit tasks found'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Audit Name')),
                            DataColumn(label: Text('Scheduled Date')),
                            DataColumn(label: Text('Auditor')),
                            DataColumn(label: Text('Auditee')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _tasks.map((task) {
                            final isPending =
                                task.status.toLowerCase() == 'pending';
                            final isApproved =
                                task.status.toLowerCase() == 'approved' ||
                                task.status.toLowerCase() == 'accepted';
                            final isRevision =
                                task.status.toLowerCase() == 'revision';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(task.auditTemplate?['name'] ?? 'N/A'),
                                ),
                                DataCell(Text(_formatDate(task.date))),
                                DataCell(
                                  Text(task.auditor?['fullName'] ?? 'N/A'),
                                ),
                                DataCell(
                                  Text(task.auditee?['fullName'] ?? 'N/A'),
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
                                                StaffAuditTaskDetailsDialog(
                                                  task: task,
                                                ),
                                          );
                                        },
                                      ),
                                      if (isApproved || isRevision)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.upload,
                                            color: AppTheme.blue600,
                                          ),
                                          tooltip: isRevision
                                              ? 'Submit Revision'
                                              : 'Submit Audit',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  StaffAuditTaskSubmissionDialog(
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
