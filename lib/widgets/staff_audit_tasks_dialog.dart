import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../services/file_download_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';

import 'staff_audit_task_submission_dialog.dart';
import 'staff_audit_question_submission_dialog.dart';
import 'custom_text_input.dart';
import 'dart:developer' as developer;

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
  String? _currentStaffId;

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
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      _currentStaffId = staffId;

      final response = await _apiService.getStaffAuditMains(staffId: staffId);
      List<dynamic> list = [];

      if (response.containsKey('audits')) {
        list = response['audits'] as List;
      } else if (response.containsKey('auditMains')) {
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
    String questionId,
    String action, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToAuditQuestion(
        auditId: auditId,
        questionId: questionId,
        action: action,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task $action successfully')));
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

  Future<void> _downloadFile(String fileName, String label) async {
    try {
      if (!await FileDownloadService.hasStoragePermission()) {
        final granted = await FileDownloadService.requestStoragePermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Storage permission is required to download files',
                ),
                backgroundColor: AppTheme.red500,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $label...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      String fileUrl = fileName;
      if (!fileName.startsWith('http')) {
        fileUrl = '${ApiService.baseUrl}/$fileName';
      }

      final filePath = await FileDownloadService.downloadFile(
        url: fileUrl,
        fileName: fileName.split('/').last,
        onProgress: (received, total) {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label downloaded to $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => FileDownloadService.openFile(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading $label: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String auditId, String questionId) {
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
                  auditId,
                  questionId,
                  'reject',
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
                            DataColumn(label: Text('Assigned Questions')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _tasks.expand((task) {
                            // Filter questions assigned to current staff
                            final myQuestions =
                                task.auditQuestions?.where((q) {
                                  return q['assignedTo'] == _currentStaffId;
                                }).toList() ??
                                [];

                            // If no specific questions, show one generic row (or none? existing logic showed one)
                            if (myQuestions.isEmpty) {
                              return [
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        task.auditTemplate?['name'] ?? 'N/A',
                                      ),
                                    ),
                                    DataCell(Text(_formatDate(task.date))),
                                    const DataCell(
                                      Text('No questions assigned'),
                                    ),
                                    DataCell(
                                      _buildStatusBadge(task.status),
                                    ), // Fallback to task status
                                    DataCell(_buildAttachmentMenu(task)),
                                  ],
                                ),
                              ];
                            }

                            // Create a row for each assigned question
                            return myQuestions.map((question) {
                              final status =
                                  question['status']?.toString() ?? task.status;
                              final qId = question['_id']?.toString() ?? '';
                              final questionText =
                                  question['question']?.toString() ??
                                  'Unknown Question';

                              final isAssigned =
                                  status.toLowerCase() == 'assigned';
                              final isApproved =
                                  status.toLowerCase() == 'accepted' ||
                                  status.toLowerCase() == 'approved';
                              final isRevision =
                                  status.toLowerCase() == 'revision';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(task.auditTemplate?['name'] ?? 'N/A'),
                                  ),
                                  DataCell(Text(_formatDate(task.date))),
                                  DataCell(
                                    SizedBox(
                                      width: 300,
                                      child: Text(questionText),
                                    ),
                                  ),
                                  DataCell(
                                    _buildStatusBadge(
                                      status,
                                      reason:
                                          question['reason']?.toString() ??
                                          question['rejectionReason']
                                              ?.toString(),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Attachment Menu
                                        _buildAttachmentMenu(task),

                                        if (isApproved || isRevision) ...[
                                          const SizedBox(width: 8),
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
                                                    StaffAuditQuestionSubmissionDialog(
                                                      task: task,
                                                      question: question,
                                                      onSubmitted: _loadTasks,
                                                    ),
                                              );
                                            },
                                          ),
                                        ],
                                        if (isAssigned && qId.isNotEmpty) ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.green600,
                                            ),
                                            tooltip: 'Accept',
                                            onPressed: () =>
                                                _handleTaskResponse(
                                                  task.id,
                                                  qId,
                                                  'approve',
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: AppTheme.red500,
                                            ),
                                            tooltip: 'Reject',
                                            onPressed: () =>
                                                _showRejectDialog(task.id, qId),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            });
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

  Widget _buildAttachmentMenu(AuditMain task) {
    List<PopupMenuEntry<String>> menuItems = [];

    // Helper to add menu item
    void addMenuItem(String? file, String label, IconData icon) {
      if (file != null && file.isNotEmpty) {
        menuItems.add(
          PopupMenuItem<String>(
            value: file,
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
              ],
            ),
            onTap: () {
              // We need to delay the async call slightly to allow menu to close
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _downloadFile(file, label),
              );
            },
          ),
        );
      }
    }

    addMenuItem(task.previousDoc, 'Previous Doc', Icons.history);
    addMenuItem(task.otherDoc, 'Other Doc', Icons.description);
    addMenuItem(task.auditMethodology, 'Methodology', Icons.library_books);
    addMenuItem(task.actionEvidence, 'Action Evidence', Icons.verified);

    if (task.otherDocs != null && task.otherDocs!.isNotEmpty) {
      for (int i = 0; i < task.otherDocs!.length; i++) {
        addMenuItem(
          task.otherDocs![i],
          'Attachment ${i + 1}',
          Icons.attach_file,
        );
      }
    }

    if (menuItems.isEmpty) {
      // Return empty container if no attachments
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'View Attachments',
      icon: const Icon(Icons.download_for_offline, color: AppTheme.primary),
      itemBuilder: (BuildContext context) => menuItems,
    );
  }

  Widget _buildStatusBadge(String status, {String? reason}) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
      case 'completed':
      case 'assigned': // Added logic for assigned
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
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (reason != null &&
        reason.isNotEmpty &&
        (status.toLowerCase() == 'rejected' ||
            status.toLowerCase() == 'revision')) {
      return Tooltip(
        message: '$reason',
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white),
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
