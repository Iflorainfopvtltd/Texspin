import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:developer' as developer;

class StaffAuditTaskCard extends StatelessWidget {
  // ... existing code ...
  Future<void> _downloadFile(
    BuildContext context,
    String fileName,
    String label,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Downloading $label...')),
            ],
          ),
          backgroundColor: AppTheme.blue600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Construct full URL
      final String fullUrl = fileName.startsWith('http')
          ? fileName
          : '${ApiService.baseUrl}/$fileName';
      final Uri url = Uri.parse(fullUrl);

      developer.log('Downloading file from: $fullUrl');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$label download started')),
                ],
              ),
              backgroundColor: AppTheme.green500,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error downloading $label: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  final AuditMain task;
  final String? currentStaffId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onSubmit;

  const StaffAuditTaskCard({
    super.key,
    required this.task,
    this.currentStaffId,
    required this.onAccept,
    required this.onReject,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Status Logic
    final bool isPending = task.status.toLowerCase() == 'pending';
    final bool isApproved =
        task.status.toLowerCase() == 'approved' ||
        task.status.toLowerCase() == 'accepted';
    final bool isRevision = task.status.toLowerCase() == 'revision';

    final String taskName = task.auditTemplate?['name'] ?? 'Audit Task';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    taskName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatus(context),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Assigned Questions:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 4),
            currentStaffId != null
                ? _buildAssignedQuestions(context)
                : const Text(
                    "Loading...",
                    style: TextStyle(color: AppTheme.gray500),
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
                  'Scheduled: ${_formatDate(task.date)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Attachments
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildAttachmentMenu(context),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if ((isApproved || isRevision) && onSubmit != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blue600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.upload, size: 16),
                        label: Text(isRevision ? 'Submit Revision' : 'Submit'),
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.red500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    String status = task.status; // Default
    if (task.auditQuestions != null && currentStaffId != null) {
      final assignedQ = task.auditQuestions!.firstWhere(
        (q) => q['assignedTo'] == currentStaffId,
        orElse: () => {},
      );
      if (assignedQ.isNotEmpty && assignedQ['status'] != null) {
        status = assignedQ['status'];
      }
    }
    return _buildStatusBadge(status);
  }

  Widget _buildAssignedQuestions(BuildContext context) {
    if (task.auditQuestions == null || task.auditQuestions!.isEmpty) {
      return const Text('No questions assigned');
    }

    final assignedQuestions = task.auditQuestions!.where((q) {
      return q['assignedTo'] == currentStaffId;
    }).toList();

    if (assignedQuestions.isEmpty) {
      return const Text('No questions assigned');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: assignedQuestions.map((q) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Expanded(
                child: Text(
                  q['question'] ?? 'Unknown Question',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentMenu(BuildContext context) {
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
                () => _downloadFile(context, file, label),
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

    return Row(
      children: [
        const Text(
          "Attachments: ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        PopupMenuButton<String>(
          tooltip: 'View Attachments',
          icon: const Icon(Icons.download_for_offline, color: AppTheme.primary),
          itemBuilder: (BuildContext context) => menuItems,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
      case 'completed':
      case 'assigned':
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
