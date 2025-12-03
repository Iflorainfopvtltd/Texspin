import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_badge.dart';
import '../widgets/assign_staff_dialog.dart';

class GanttChartWidget extends StatefulWidget {
  final Project project;
  final Function(String phaseId, String activityId, ActivityStatus status)?
  onUpdateActivityStatus;
  final bool canAssignStaff;
  final VoidCallback? onRefresh;
  final VoidCallback? onNavigateBack;

  const GanttChartWidget({
    super.key,
    required this.project,
    this.onUpdateActivityStatus,
    this.canAssignStaff = false,
    this.onRefresh,
    this.onNavigateBack,
  });

  @override
  State<GanttChartWidget> createState() => _GanttChartWidgetState();
}

class _GanttChartWidgetState extends State<GanttChartWidget> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.notStarted:
        return AppTheme.red500;
      case ActivityStatus.inProgress:
        return AppTheme.yellow500;
      case ActivityStatus.completed:
        return AppTheme.green500;
    }
  }

  BadgeVariant _getStatusBadgeVariant(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.completed:
        return BadgeVariant.default_;
      case ActivityStatus.inProgress:
        return BadgeVariant.secondary;
      case ActivityStatus.notStarted:
        return BadgeVariant.outline;
    }
  }

  String _getStatusString(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.notStarted:
        return 'pending';
      case ActivityStatus.inProgress:
        return 'in progress';
      case ActivityStatus.completed:
        return 'completed';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getTooltipMessage(Activity activity) {
    final startDate = activity.startDate != null
        ? _formatDate(activity.startDate!)
        : 'N/A';
    final endDate = activity.endDate != null
        ? _formatDate(activity.endDate!)
        : 'N/A';
    
    return 'Start: $startDate\nEnd: $endDate';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showDateTooltip(BuildContext context, Activity activity) {
    final startDate = activity.startDate != null
        ? _formatDateLong(activity.startDate!)
        : 'Not set';
    final endDate = activity.endDate != null
        ? _formatDateLong(activity.endDate!)
        : 'Not set';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(activity.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: _getStatusColor(activity.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Start Date
              _DateInfoRow(
                icon: Icons.play_circle_outline,
                label: 'Start Date',
                date: startDate,
                color: AppTheme.green600,
              ),
              const SizedBox(height: 16),

              // End Date
              _DateInfoRow(
                icon: Icons.flag_outlined,
                label: 'End Date',
                date: endDate,
                color: AppTheme.red600,
              ),
              const SizedBox(height: 20),

              // Duration info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.blue200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.blue600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: Week ${activity.startWeek} - Week ${activity.endWeek}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.blue900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.blue600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateLong(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showAssignStaffDialog(
    BuildContext context,
    String phaseId,
    String activityId,
    String activityName,
    String? currentStaffName, {
    int? currentStartWeek,
    int? currentEndWeek,
    String? currentStaffId,
    String? currentStartDate,
    String? currentEndDate,
  }) {
    final isAssigned = currentStaffName != null && currentStaffName.isNotEmpty;

    if (isAssigned) {
      // Show attractive confirmation dialog for reassignment
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.blue50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: AppTheme.blue600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Reassign Staff Member',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Current assignment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.blue50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.blue200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Assignment',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.blue100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                currentStaffName.isNotEmpty
                                    ? currentStaffName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 14,
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
                                  currentStaffName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Activity: $activityName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Do you want to reassign this activity to a different staff member?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppTheme.gray300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _openAssignStaffDialog(
                            context,
                            phaseId,
                            activityId,
                            activityName,
                            currentStaffName,
                            isReassignment: true,
                            currentStartWeek: currentStartWeek,
                            currentEndWeek: currentEndWeek,
                            currentStaffId: currentStaffId,
                            currentStartDate: currentStartDate,
                            currentEndDate: currentEndDate,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.blue600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reassign',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Directly open assignment dialog for new assignment
      _openAssignStaffDialog(
        context,
        phaseId,
        activityId,
        activityName,
        currentStaffName,
        isReassignment: false,
        currentStartWeek: currentStartWeek,
        currentEndWeek: currentEndWeek,
        currentStaffId: currentStaffId,
        currentStartDate: currentStartDate,
        currentEndDate: currentEndDate,
      );
    }
  }

  void _openAssignStaffDialog(
    BuildContext context,
    String phaseId,
    String activityId,
    String activityName,
    String? currentStaffName, {
    required bool isReassignment,
    int? currentStartWeek,
    int? currentEndWeek,
    String? currentStaffId,
    String? currentStartDate,
    String? currentEndDate,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AssignStaffDialog(
        projectId: widget.project.id,
        phaseId: phaseId,
        activityId: activityId,
        activityName: activityName,
        templateId: widget.project.templateId ?? '',
        currentStaffId: currentStaffId,
        currentStaffName: currentStaffName,
        isReassignment: isReassignment,
        currentStartWeek: currentStartWeek,
        currentEndWeek: currentEndWeek,
        currentStartDate: currentStartDate,
        currentEndDate: currentEndDate,
        onAssigned: () {
          // Refresh the project data
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        },
        onNavigateBack: widget.onNavigateBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = List.generate(
      widget.project.totalWeeks,
      (index) => index + 1,
    );
    final project = widget.project;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Scrollbar(
        controller: _horizontalController,
        thickness: 10,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================= HEADER =========================
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.blue600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    _HeaderCell('Activity', width: 300),
                    _HeaderCell('Responsible', width: 200),
                    _HeaderCell('Review Date', width: 150),
                    _HeaderCell('Approving Member', width: 180),
                    _HeaderCell('Status', width: 120),
                    _HeaderCell('Technical Remarks', width: 200),
                    _HeaderCell('Acceptance Status', width: 150),
                    ...weeks.map((week) => _HeaderCell('W$week', width: 60)),
                  ],
                ),
              ),

              // ========================= PHASES & ACTIVITIES =========================
              ...project.phases.asMap().entries.map((phaseEntry) {
                final phaseIndex = phaseEntry.key;
                final phase = phaseEntry.value;

                return Column(
                  children: [
                    Container(
                      color: AppTheme.blue100,
                      child: Row(
                        children: [
                          Container(
                            width: 300 + 200 + 150 + 180 + 120 + 200 + 150,
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Phase ${phaseIndex + 1}: ${phase.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.blue900,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          ...weeks.map((_) => Container(width: 60)),
                        ],
                      ),
                    ),

                    // ---- Activities ----
                    ...phase.activities.map((activity) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.gray200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Activity Name
                            _Cell(activity.name, width: 300),

                            // Responsible (Clickable for managers only)
                            InkWell(
                              onTap: widget.canAssignStaff
                                  ? () => _showAssignStaffDialog(
                                        context,
                                        phase.id,
                                        activity.id,
                                        activity.name,
                                        activity.responsiblePerson,
                                        currentStartWeek: activity.startWeek,
                                        currentEndWeek: activity.endWeek,
                                        currentStaffId: activity.staffId,
                                        currentStartDate: activity.startDate,
                                        currentEndDate: activity.endDate,
                                      )
                                  : null,
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.all(12),
                                color: Colors.white,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activity.responsiblePerson.isEmpty
                                            ? 'Unassigned'
                                            : activity.responsiblePerson,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: activity.responsiblePerson.isEmpty
                                              ? AppTheme.gray500
                                              : AppTheme.gray900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    if (widget.canAssignStaff)
                                      const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: AppTheme.card,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Review Date
                            _Cell(activity.reviewDate ?? '-', width: 150),

                            // Approval Staff
                            _Cell(activity.approvingStaff ?? '-', width: 180),

                            // Status
                            Container(
                              width: 120,
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.centerLeft,
                              child: CustomBadge(
                                text: _capitalizeFirst(
                                  _getStatusString(activity.status),
                                ),
                                variant: _getStatusBadgeVariant(
                                  activity.status,
                                ),
                              ),
                            ),

                            // Technical Remarks
                            _Cell(
                              activity.technicalRemarks ?? '-',
                              width: 200,
                            ),

                            // Acceptance Status
                            _Cell(
                              activity.approvalStatus ?? '-',
                              width: 150,
                            ),

                            // ---- Gantt Week Cells ----
                            ...weeks.map((week) {
                              final isInRange =
                                  week >= activity.startWeek &&
                                  week <= activity.endWeek;
                              final isStart = week == activity.startWeek;
                              final isEnd = week == activity.endWeek;

                              return Container(
                                width: 60,
                                height: 40,
                                padding: const EdgeInsets.all(4),
                                child: isInRange
                                    ? Tooltip(
                                        message: _getTooltipMessage(activity),
                                        preferBelow: false,
                                        verticalOffset: 20,
                                        decoration: BoxDecoration(
                                          color: AppTheme.gray900,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _showDateTooltip(
                                              context,
                                              activity,
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                activity.status,
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: isStart
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                bottomLeft: isStart
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                topRight: isEnd
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                bottomRight: isEnd
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER & CELL COMPONENTS
// ============================================================

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final double width;
  final Alignment alignment;

  const _Cell(
    this.text, {
    required this.width,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppTheme.gray900),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _DateInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  final Color color;

  const _DateInfoRow({
    required this.icon,
    required this.label,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
