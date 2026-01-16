import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:developer' as developer;

class StaffTaskDetailsDialog extends StatelessWidget {
  final DepartmentTask task;

  const StaffTaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(context, isMobile),
            Expanded(child: _buildContent(context, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.blue100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: AppTheme.blue600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  task.name,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.gray600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.gray600,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(isMobile),
          const SizedBox(height: 24),
          _buildDescriptionSection(isMobile),
          const SizedBox(height: 24),
          _buildTeamInfoSection(isMobile),
          const SizedBox(height: 24),
          _buildFilesSection(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isMobile) {
    return _buildSection('Basic Information', Icons.info_outline, [
      _buildInfoRowDetail('Task Name', task.name),
      _buildInfoRowDetail(
        'Deadline',
        task.deadline != null ? _formatDate(task.deadline!) : 'N/A',
      ),
      _buildInfoRowDetail('Status', task.status, isStatus: true),
      _buildInfoRowDetail(
        'Created By',
        '${task.createdBy['firstName'] ?? ''} ${task.createdBy['lastName'] ?? ''}',
      ),
      _buildInfoRowDetail('Created At', _formatDate(task.createdAt)),
      _buildInfoRowDetail('Updated At', _formatDate(task.updatedAt)),
      if (task.status.toLowerCase() == 'rejected' &&
          task.rejectionReason != null)
        _buildInfoRowDetail('Rejection Reason', task.rejectionReason),
      if (task.status.toLowerCase() == 'revision' &&
          task.rejectionReason != null)
        _buildInfoRowDetail('Revision Reason', task.rejectionReason),
    ], isMobile);
  }

  Widget _buildDescriptionSection(bool isMobile) {
    return _buildSection('Description', Icons.description_outlined, [
      Text(
        task.description,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.gray900,
          height: 1.5,
        ),
      ),
    ], isMobile);
  }

  Widget _buildTeamInfoSection(bool isMobile) {
    final Map<String, dynamic> staff = task.assignedStaff;

    return _buildSection('Assigned Staff', Icons.people_outline, [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.blue100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  ((staff['firstName'] ?? '?')[0] as String).toUpperCase() +
                      ((staff['lastName'] ?? '?')[0] as String).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.blue600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                  if (staff['email'] != null)
                    Text(
                      staff['email'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ], isMobile);
  }

  Widget _buildFilesSection(BuildContext context, bool isMobile) {
    final hasMainFile = task.fileName != null && task.fileName!.isNotEmpty;
    List<Map<String, dynamic>> attachments = task.attachments ?? [];

    return _buildSection('Files & Documents', Icons.folder_outlined, [
      if (!hasMainFile && attachments.isEmpty)
        const Text(
          'No files attached',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),

      if (hasMainFile) ...[
        _buildFileRow(
          context,
          'Main Task File',
          task.fileName!,
          task.downloadUrl,
        ),
        if (attachments.isNotEmpty) const SizedBox(height: 12),
      ],

      if (attachments.isNotEmpty) ...[
        const Text(
          'Attachments:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        ...attachments.map((attachment) {
          final name =
              attachment['originalName'] ??
              attachment['filename'] ??
              'Attachment';
          final url = attachment['path'] ?? attachment['url'];
          return _buildFileRow(context, name, '', url);
        }).toList(),
      ],
    ], isMobile);
  }

  Widget _buildFileRow(
    BuildContext context,
    String label,
    String fileName,
    String? downloadUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.green600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                if (fileName.isNotEmpty)
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
              ],
            ),
          ),
          if (downloadUrl != null && downloadUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () => _downloadFile(context, downloadUrl, fileName),
              color: AppTheme.blue600,
              tooltip: 'Download',
            ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(
    BuildContext context,
    String fileUrl,
    String fileName,
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
              Expanded(child: Text('Downloading $fileName...')),
            ],
          ),
          backgroundColor: AppTheme.blue600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Construct full URL using ApiService baseUrl
      final String fullUrl = fileUrl.startsWith('http')
          ? fileUrl
          : ApiService.baseUrl + fileUrl;

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
                  Expanded(child: Text('$fileName download started')),
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
                Expanded(child: Text('Error downloading $fileName: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.gray600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRowDetail(
    String label,
    dynamic value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray600,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? _buildStatusBadgeDetail(value?.toString() ?? 'N/A')
                : Text(
                    value?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeDetail(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        bgColor = AppTheme.green100;
        textColor = AppTheme.green600;
        break;
      case 'rejected':
        bgColor = AppTheme.red50;
        textColor = AppTheme.red600;
        break;
      case 'pending':
        bgColor = AppTheme
            .yellow100; // Using yellow for pending based on typical conventions, closest to 'active' or 'open'
        textColor = AppTheme.yellow600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
