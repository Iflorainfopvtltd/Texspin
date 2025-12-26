import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../services/file_download_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';

import 'staff_audit_task_submission_dialog.dart';
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

  Future<void> _downloadFile(String fileName, String label) async {
    try {
      // Check storage permission first
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

      // Assuming files are served from /uploads/ path if they are relative filenames
      // If the API returns full URLs, this logic needs adjustment.
      // Based on typical behavior, we'll try prepending base url + /uploads/ or similar if it's just a filename.
      // However, usually API key responses like "previousDoc" are just filenames.
      // Let's assume a standard path for now or just append to base URL if it looks like a path.

      String fileUrl = fileName;
      if (!fileName.startsWith('http')) {
        // If it's just a filename, assume it's under /texspin/api/uploads/ or similar?
        // Actually, let's use the file upload logic as a hint or just standard static file serving.
        // If we don't know the accurate path, we might fail.
        // For now, let's try assuming it's a relative path from baseUrl.
        fileUrl = '${ApiService.baseUrl}/$fileName';
        // Note: You might need to adjust this path prefix based on backend static file serving config.
      }

      final filePath = await FileDownloadService.downloadFile(
        url: fileUrl,
        fileName: fileName.split('/').last,
        onProgress: (received, total) {
          // Optional: update progress UI
        },
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
                            DataColumn(label: Text('Assigned Questions')),
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
                                  SizedBox(
                                    width: 300,
                                    child: _buildAssignedQuestions(task),
                                  ),
                                ),
                                DataCell(
                                  // Find the status of the first assigned question for this staff
                                  Builder(
                                    builder: (context) {
                                      String status = task.status; // Default
                                      if (task.auditQuestions != null &&
                                          _currentStaffId != null) {
                                        final assignedQ = task.auditQuestions!
                                            .firstWhere(
                                              (q) =>
                                                  q['assignedTo'] ==
                                                  _currentStaffId,
                                              orElse: () => {},
                                            );
                                        if (assignedQ.isNotEmpty &&
                                            assignedQ['status'] != null) {
                                          status = assignedQ['status'];
                                        }
                                      }
                                      return _buildStatusBadge(status);
                                    },
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
                                                  StaffAuditTaskSubmissionDialog(
                                                    task: task,
                                                    onSubmitted: _loadTasks,
                                                  ),
                                            );
                                          },
                                        ),
                                      ],
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

  Widget _buildAssignedQuestions(AuditMain task) {
    if (task.auditQuestions == null ||
        task.auditQuestions!.isEmpty ||
        _currentStaffId == null) {
      return const Text('No questions assigned');
    }

    final assignedQuestions = task.auditQuestions!.where((q) {
      return q['assignedTo'] == _currentStaffId;
    }).toList();

    if (assignedQuestions.isEmpty) {
      return const Text('No questions assigned');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: assignedQuestions.map((q) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(q['question'] ?? 'Unknown Question')),
            ],
          ),
        );
      }).toList(),
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

  Widget _buildStatusBadge(String status) {
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
