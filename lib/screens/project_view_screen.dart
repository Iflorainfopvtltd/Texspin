import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../widgets/gantt_chart.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../utils/pdf_export.dart';

class ProjectViewScreen extends StatelessWidget {
  final Project project;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final Function(String phaseId, String activityId, ActivityStatus status)
  onUpdateActivityStatus;
  final String? userRole;
  final VoidCallback? onRefresh;

  const ProjectViewScreen({
    super.key,
    required this.project,
    required this.onBack,
    required this.onEdit,
    this.onDelete,
    required this.onUpdateActivityStatus,
    this.userRole,
    this.onRefresh,
  });

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            _ExportOption(
              icon: Icons.picture_as_pdf,
              title: 'Export as PDF',
              description:
                  'Generate a PDF report with project details and Gantt chart',
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(context);
              },
            ),
            // const SizedBox(height: 12),
            // _ExportOption(
            //   icon: Icons.table_chart,
            //   title: 'Export as Excel',
            //   description: 'Export project data to Excel spreadsheet',
            //   onTap: () {
            //     Navigator.pop(context);
            //     _exportToExcel(context);
            //   },
            // ),
            // const SizedBox(height: 12),
            // _ExportOption(
            //   icon: Icons.description,
            //   title: 'Export as CSV',
            //   description: 'Export project data as CSV file',
            //   onTap: () {
            //     Navigator.pop(context);
            //     _exportToCSV(context);
            //   },
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate and export PDF
      await PdfExportService.exportProjectToPdf(project);

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF exported successfully!'),
              ],
            ),
            backgroundColor: AppTheme.green500,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error exporting PDF: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this project?',
              style: TextStyle(fontSize: 16, color: AppTheme.gray900),
            ),
            const SizedBox(height: 8),
            Text(
              'Project: ${project.partName}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.red500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) {
                onDelete!();
              }
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalActivities = project.phases.fold<int>(
      0,
      (sum, phase) => sum + phase.activities.length,
    );
    final completedActivities = project.phases.fold<int>(
      0,
      (sum, phase) =>
          sum +
          phase.activities
              .where((a) => a.status == ActivityStatus.completed)
              .length,
    );
    final inProgressActivities = project.phases.fold<int>(
      0,
      (sum, phase) =>
          sum +
          phase.activities
              .where((a) => a.status == ActivityStatus.inProgress)
              .length,
    );

    return Scaffold(
      backgroundColor: AppTheme.gray50,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: onBack,
          color: AppTheme.gray900,
        ),
        title: Text(
          project.partName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (userRole != 'manager') ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              color: AppTheme.gray900,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete != null
                  ? () => _showDeleteConfirmation(context)
                  : null,
              color: AppTheme.red500,
              tooltip: 'Delete',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () => _showExportDialog(context),
            color: AppTheme.gray900,
            tooltip: 'Export',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Details Card
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Project Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gray900,
                            ),
                          ),
                          // CustomBadge(
                          //   text: project.partNumber,
                          //   variant: BadgeVariant.outline,
                          // ),
                          const SizedBox(width: 8),
                          CustomBadge(text: '${project.progress}% Complete'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          
                          if (isMobile) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.person,
                                        label: 'Customer',
                                        value: project.customerName,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.location_on,
                                        label: 'Customer Zone',
                                        value: project.location,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.people,
                                        label: 'Team Leader',
                                        value: project.teamLeader,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.calendar_today,
                                        label: 'Date of Issue',
                                        value: DateFormat('MMM dd, yyyy')
                                            .format(DateTime.parse(project.dateOfIssue)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.description,
                                        label: 'Plan Number',
                                        value: project.planNumber.isEmpty
                                            ? 'N/A'
                                            : project.planNumber,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.edit_note,
                                        label: 'Revision',
                                        value: project.revisionNumber.isEmpty
                                            ? 'N/A'
                                            : '${project.revisionNumber} (${DateFormat('MMM dd, yyyy').format(DateTime.parse(project.revisionDate))})',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.access_time,
                                        label: 'Duration',
                                        value: '${project.totalWeeks} weeks',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons.layers,
                                        label: 'Total Phases',
                                        value: '${project.phases.length} phases',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.person,
                                      label: 'Customer',
                                      value: project.customerName,
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.location_on,
                                      label: 'Customer Zone',
                                      value: project.location,
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.people,
                                      label: 'Team Leader',
                                      value: project.teamLeader,
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.calendar_today,
                                      label: 'Date of Issue',
                                      value: DateFormat('MMM dd, yyyy')
                                          .format(DateTime.parse(project.dateOfIssue)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.description,
                                      label: 'Plan Number',
                                      value: project.planNumber.isEmpty
                                          ? 'N/A'
                                          : project.planNumber,
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.edit_note,
                                      label: 'Revision',
                                      value: project.revisionNumber.isEmpty
                                          ? 'N/A'
                                          : '${project.revisionNumber} (${DateFormat('MMM dd, yyyy').format(DateTime.parse(project.revisionDate))})',
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.access_time,
                                      label: 'Duration',
                                      value: '${project.totalWeeks} weeks',
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      icon: Icons.layers,
                                      label: 'Total Phases',
                                      value: '${project.phases.length} phases',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      if (project.teamMembers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Team Members',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: project.teamMembers.map((member) {
                            return CustomBadge(
                              text: member,
                              variant: BadgeVariant.secondary,
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Authorized by',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray600,
                        ),
                      ),
                      const SizedBox(height: 16),
                   Text(
                          project.teamLeader,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Gantt Chart Card
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APQP Gantt Chart',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Project timeline and activity tracking',
                        style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 24),
                      GanttChartWidget(
                        project: project,
                        onUpdateActivityStatus: onUpdateActivityStatus,
                        canAssignStaff: userRole == 'manager',
                        onRefresh: onRefresh,
                        onNavigateBack: onBack,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Status Legend',
                        style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          
                          if (isMobile) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _LegendItem(
                                        color: AppTheme.red500,
                                        label: 'Not Started',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _LegendItem(
                                        color: AppTheme.yellow500,
                                        label: 'In Progress',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _LegendItem(
                                        color: AppTheme.green500,
                                        label: 'Completed',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ],
                            );
                          }
                          
                          return Row(
                            children: [
                              _LegendItem(
                                color: AppTheme.red500,
                                label: 'Not Started',
                              ),
                              const SizedBox(width: 24),
                              _LegendItem(
                                color: AppTheme.yellow500,
                                label: 'In Progress',
                              ),
                              const SizedBox(width: 24),
                              _LegendItem(
                                color: AppTheme.green500,
                                label: 'Completed',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Activity Summary
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    if (isMobile) {
                      return Column(
                        children: [
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Activities',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                Text(
                                  '$totalActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Completed Activities',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                Text(
                                  '$completedActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.green600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'In Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                Text(
                                  '$inProgressActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.yellow600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return Row(
                      children: [
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Activities',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$totalActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Completed Activities',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$completedActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.green600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'In Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$inProgressActivities',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.yellow600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.gray600),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.gray700),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppTheme.blue600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
