import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../theme/app_theme.dart';

class StaffAuditTaskDetailsDialog extends StatelessWidget {
  final AuditMain task;

  const StaffAuditTaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
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
                    _buildDetailRow(
                      'Audit Name',
                      task.auditTemplate?['name'] ?? 'N/A',
                    ),
                    _buildDetailRow('Scheduled Date', _formatDate(task.date)),
                    _buildDetailRow('Status', task.status.toUpperCase()),
                    const SizedBox(height: 16),
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Auditor',
                      task.auditor?['fullName'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Auditee',
                      task.auditee?['fullName'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Department',
                      task.department?['name'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Audit Scope',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Audit Type',
                      task.auditTemplate?['auditType']?['name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Audit Segment',
                      task.auditTemplate?['auditSegment']?['name'] ?? 'N/A',
                    ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
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
