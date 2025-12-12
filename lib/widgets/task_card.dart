import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/file_download_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import 'dart:developer' as developer;

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh;
  final bool showActions;
  final bool isCompact;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
    this.showActions = true,
    this.isCompact = false,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.green500;
      case 'approved':
        return AppTheme.green500;
      case 'in progress':
        return AppTheme.blue500;
      case 'submitted':
        return AppTheme.blue500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadTaskFile(BuildContext context) async {
    try {
      String? fileUrl;
      String? fileName;

      // Check if task has downloadUrl (new structure)
      if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
        fileUrl = task.downloadUrl;
        fileName = task.fileName ?? 'task_file';
      } 
      // Fallback to attachments (old structure)
      else if (task.attachments != null && task.attachments!.isNotEmpty) {
        final attachment = task.attachments!.first;
        fileUrl = attachment['fileUrl'] ?? '';
        fileName = attachment['fileName'] ?? 'task_file';
      }

      if (fileUrl == null || fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No files to download'),
            backgroundColor: AppTheme.yellow500,
          ),
        );
        return;
      }

      // Check storage permission first
      if (!await FileDownloadService.hasStoragePermission()) {
        final granted = await FileDownloadService.requestStoragePermission();
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to download files'),
                backgroundColor: AppTheme.red500,
              ),
            );
          }
          return;
        }
      }

      // Show downloading message
      if (context.mounted) {
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
                Expanded(child: Text('Downloading $fileName...')),
              ],
            ),
            backgroundColor: AppTheme.blue600,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Construct full URL using ApiService baseUrl
      final String fullUrl = ApiService.baseUrl + fileUrl;
      
      // Download the file using our custom service
      final filePath = await FileDownloadService.downloadFile(
        url: fullUrl,
        fileName: fileName!,
        onProgress: (received, total) {
          // Optional: You can show download progress here
          developer.log('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
        },
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$fileName downloaded successfully'),
                      Text(
                        'Saved to: ${filePath.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => FileDownloadService.openFile(filePath),
            ),
          ),
        );
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
                Expanded(child: Text('Error downloading file: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: Text('Are you sure you want to approve "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Approve',
            onPressed: () {
              Navigator.pop(context);
              _reviewTask(context, 'completed');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${task.name}"?'),
            const SizedBox(height: 16),
            CustomTextInput(
              label: 'Rejection Reason',
              hint: 'Please provide a reason for rejection',
              controller: reasonController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a rejection reason';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Reject',
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppTheme.red500,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _reviewTask(context, 'rejected', rejectionReason: reasonController.text.trim());
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Future<void> _reviewTask(BuildContext context, String status, {String? rejectionReason}) async {
    try {
      final apiService = ApiService();
      final response = await apiService.reviewTask(
        taskId: task.id,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (context.mounted) {
        // Use API response message if available, otherwise use default
        String successMessage;
        if (response['message'] != null) {
          successMessage = response['message'].toString();
        } else {
          successMessage = status == 'completed' 
              ? 'Task approved successfully' 
              : 'Task rejected successfully';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: status == 'completed' ? AppTheme.green500 : AppTheme.red500,
          ),
        );
        onRefresh?.call(); // Refresh the task list
      }
    } catch (e) {
      developer.log('Error reviewing task: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedStaffName = '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'.trim();
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            
            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray600,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Info Row
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedStaffName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(task.deadline),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
            
            if (showActions) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              // Actions Row
              Row(
                children: [
                  // For submitted tasks: show download, approve and reject
                  if (task.status.toLowerCase() == 'submitted') ...[
                    // Download button (if downloadUrl is available)
                    if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty)
                      Expanded(
                        child: CustomButton(
                          text: 'Download',
                          onPressed: () => _downloadTaskFile(context),
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.download, size: 16),
                        ),
                      ),
                    if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty)
                      const SizedBox(width: 8),
                    // Approve button
                    Expanded(
                      child: CustomButton(
                        text: 'Approve',
                        onPressed: () => _showApproveDialog(context),
                        variant: ButtonVariant.default_,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.check, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reject button
                    Expanded(
                      child: CustomButton(
                        text: 'Reject',
                        onPressed: () => _showRejectDialog(context),
                        variant: ButtonVariant.destructive,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ] else ...[
                    // For non-submitted tasks: show other actions
                    // Download button (if downloadUrl is available or has attachments)
                    if ((task.downloadUrl != null && task.downloadUrl!.isNotEmpty) ||
                        (task.attachments != null && task.attachments!.isNotEmpty))
                      Expanded(
                        child: CustomButton(
                          text: 'Download',
                          onPressed: () => _downloadTaskFile(context),
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.download, size: 16),
                        ),
                      ),
                    if ((task.downloadUrl != null && task.downloadUrl!.isNotEmpty) ||
                        (task.attachments != null && task.attachments!.isNotEmpty))
                      const SizedBox(width: 8),
                    
                    // Edit button (only for pending and in progress tasks)
                    if (task.status.toLowerCase() != 'completed' && 
                        task.status.toLowerCase() != 'approved' && 
                        task.status.toLowerCase() != 'rejected')
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: onEdit,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.edit, size: 16),
                        ),
                      ),
                    if (task.status.toLowerCase() != 'completed' && 
                        task.status.toLowerCase() != 'approved' && 
                        task.status.toLowerCase() != 'rejected')
                      const SizedBox(width: 8),
                    
                    // Delete button
                    Expanded(
                      child: CustomButton(
                        text: 'Delete',
                        onPressed: onDelete,
                        variant: ButtonVariant.destructive,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.delete, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}