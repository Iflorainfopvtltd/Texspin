import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class StaffTaskCard extends StatelessWidget {
  final DepartmentTask task;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;
  final VoidCallback? onSubmit;

  const StaffTaskCard({
    super.key,
    required this.task,
    required this.onAccept,
    required this.onReject,
    required this.onViewDetails,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = task.status.toLowerCase() == 'pending';
    final bool isAccepted = task.status.toLowerCase() == 'accepted';
    final bool isRevision = task.status.toLowerCase() == 'revision';

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
                    task.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(task),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.gray600),
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
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
                if ((isAccepted || isRevision) && onSubmit != null) ...[
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

    if (task.status.toLowerCase() == 'rejected' ||
        task.status.toLowerCase() == 'revision') {
      return Tooltip(
        message: task.rejectionReason ?? 'No reason provided',
        triggerMode: TooltipTriggerMode.tap,
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
