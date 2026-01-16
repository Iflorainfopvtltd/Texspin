
import 'package:Texspin/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffAuditTaskDetailsDialog extends StatelessWidget {
  final AuditMain task;

  // Base URL for viewing/downloading files.
  // Assuming files are served from the API base + /uploads or similar.
  // Standard Texspin practice seems to rely on the backend returning full URLs or we append to base.
  // Usually the file string is just the filename.
  // Based on other parts of the app (e.g. ApiService), we might need to prepend base URL.
  // For now I'll use a placeholder or assume ApiService.baseUrl + '/uploads/' + filename
  // BUT: check ApiService for getDownloadUrl logic? ApiService doesn't expose it directly publicly here.
  // Helper:
  // Adjust path if needed. The User didn't specify, so I'll try to use a standard patterns or just show filename.

  const StaffAuditTaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Audit Task Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Info'),
                    _buildDetailRow(
                      'Audit Name',
                      task.auditTemplate?['name'] ?? 'N/A',
                    ),
                    _buildDetailRow('Audit Number', task.auditNumber ?? 'N/A'),
                    _buildDetailRow('Company', task.companyName ?? 'N/A'),
                    _buildDetailRow('Location', task.location ?? 'N/A'),
                    _buildDetailRow('Scheduled Date', _formatDate(task.date)),
                    _buildDetailRow('Status', task.status.toUpperCase()),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Participants'),
                    if (task.texspinStaffMember != null &&
                        task.texspinStaffMember!.isNotEmpty)
                      ...task.texspinStaffMember!
                          .map(
                            (staff) => _buildDetailRow(
                              'Auditor',
                              '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                                  .trim(),
                            ),
                          )
                          .toList(),
                    if (task.visitCompanyMemberName != null &&
                        task.visitCompanyMemberName!.isNotEmpty)
                      ...task.visitCompanyMemberName!
                          .map(
                            (visitor) => _buildDetailRow(
                              'Auditee',
                              visitor['name'] ?? 'N/A',
                            ),
                          )
                          .toList(),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Audit Scope'),
                    _buildDetailRow(
                      'Audit Type',
                      task.auditTemplate?['auditType']?['name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Audit Segment',
                      task.auditTemplate?['auditSegment']?['name'] ?? 'N/A',
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Documents'),
                    _buildFileRow(context, 'Previous Doc', task.previousDoc),
                    _buildFileRow(
                      context,
                      'Audit Methodology',
                      task.auditMethodology,
                    ),
                    _buildFileRow(
                      context,
                      'Audit Observation',
                      task.auditObservation,
                    ),
                    _buildFileRow(context, 'Action Plan', task.actionPlan),
                    _buildFileRow(
                      context,
                      'Action Evidence',
                      task.actionEvidence,
                    ),
                    _buildFileRow(context, 'Other Doc', task.otherDoc),

                    if (task.otherDocs != null && task.otherDocs!.isNotEmpty)
                      ...task.otherDocs!
                          .map(
                            (doc) =>
                                _buildFileRow(context, 'Additional Doc', doc),
                          )
                          .toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, String label, String? fileName) {
    if (fileName == null || fileName.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.attach_file, size: 16, color: AppTheme.blue600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.blue600,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20, color: AppTheme.primary),
            // Assuming a download/view action.
            // Since we don't have full URLs in the JSON, we construct one or just try opening it (if it happened to be a full URL).
            // If it's a relative path/filename, we prepend the base URL.
            onPressed: () {
              String url = fileName;
              if (!url.startsWith('http')) {
                url = '${ApiService.baseUrl}/uploads/$fileName';
              }
              _launchUrl(context, url);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch url: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching url: $e')));
      }
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
}
