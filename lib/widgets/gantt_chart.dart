import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/assign_staff_dialog.dart';
import '../widgets/end_phase_form_dialog.dart';

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
  Set<String> _unlockedPhases = {};

  @override
  void initState() {
    super.initState();
    _loadUnlockedPhases();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadUnlockedPhases() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'unlocked_phases_${widget.project.id}';
    final unlockedList = prefs.getStringList(key) ?? [];
    setState(() {
      _unlockedPhases = unlockedList.toSet();
    });
  }

  Future<void> _markPhaseAsUnlocked(String phaseId) async {
    _unlockedPhases.add(phaseId);
    final prefs = await SharedPreferences.getInstance();
    final key = 'unlocked_phases_${widget.project.id}';
    await prefs.setStringList(key, _unlockedPhases.toList());
    setState(() {});
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.notStarted:
        return AppTheme.red500;
      case ActivityStatus.inProgress:
        return AppTheme.yellow500;
      case ActivityStatus.submitted:
        return AppTheme.yellow500;
      case ActivityStatus.completed:
        return AppTheme.green500;
      case ActivityStatus.pending:
        return AppTheme.red500;
    }
  }

  BadgeVariant _getStatusBadgeVariant(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.completed:
        return BadgeVariant.default_;
      case ActivityStatus.inProgress:
        return BadgeVariant.secondary;
      case ActivityStatus.submitted:
        return BadgeVariant.secondary;
      case ActivityStatus.notStarted:
        return BadgeVariant.outline;
      case ActivityStatus.pending:
        return BadgeVariant.outline;
    }
  }

  String _getStatusString(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.notStarted:
        return 'pending';
      case ActivityStatus.inProgress:
        return 'in progress';
      case ActivityStatus.submitted:
        return 'submitted';
      case ActivityStatus.completed:
        return 'completed';
      case ActivityStatus.pending:
        return 'pending';
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

  String _formatReviewDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isPreviousPhaseUnlocked(int currentPhaseIndex) {
    if (currentPhaseIndex == 0) {
      return true; // Phase 1 is always unlocked
    }

    final previousPhase = widget.project.phases[currentPhaseIndex - 1];

    // Check if previous phase was unlocked via end phase form
    return _unlockedPhases.contains(previousPhase.id);
  }

  bool _areAllActivitiesCompletedAndAccepted(int phaseIndex) {
    final phase = widget.project.phases[phaseIndex];

    // Check if all activities in phase are completed and accepted
    for (final activity in phase.activities) {
      final isCompleted = activity.status == ActivityStatus.completed;
      final isAccepted = activity.approvalStatus?.toLowerCase() == 'accepted';

      if (!isCompleted || !isAccepted) {
        return false;
      }
    }

    return true;
  }

  void _handlePhaseLockClick(
    BuildContext context,
    int phaseIndex,
    String phaseName,
    String phaseId,
  ) {
    final previousPhaseIndex = phaseIndex - 1;
    final areActivitiesComplete = _areAllActivitiesCompletedAndAccepted(
      previousPhaseIndex,
    );

    if (!areActivitiesComplete) {
      // Show dialog that previous phase activities must be completed first
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.red50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.red600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Phase Locked',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.red50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.red200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.red600,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please complete all activities in Phase ${phaseIndex} first.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All activities must have:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RequirementItem(text: 'Status: Completed'),
                      const SizedBox(height: 4),
                      _RequirementItem(text: 'Acceptance Status: Accepted'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                      'Understood',
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
    } else {
      // All activities are complete - show end phase form for previous phase
      final previousPhase = widget.project.phases[previousPhaseIndex];
      _showEndPhaseForm(context, previousPhase.id, previousPhase.name);
    }
  }

  void _showEndPhaseForm(
    BuildContext context,
    String phaseId,
    String phaseName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => EndPhaseFormDialog(
        projectId: widget.project.id,
        phaseId: phaseId,
        phaseName: phaseName,
        project: widget.project,
        onSuccess: () async {
          // Mark this phase as unlocked so next phase can be accessed
          await _markPhaseAsUnlocked(phaseId);

          // Refresh the project data to get updated phase status
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        },
      ),
    );
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
    int? currentReminderDays,
  }) {
    final isAssigned = currentStaffName != null && currentStaffName.isNotEmpty;

    if (isAssigned) {
      // Show attractive confirmation dialog for reassignment
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                            currentReminderDays: currentReminderDays,
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
        currentReminderDays: currentReminderDays,
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
    int? currentReminderDays,
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
        currentReminderDays: currentReminderDays,
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

  Future<void> _showTechnicalRemarkDialog(
    BuildContext context,
    String phaseId,
    String activityId,
    String activityName,
  ) async {
    final TextEditingController remarkController = TextEditingController();

    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.blue50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_add_outlined,
                      color: AppTheme.blue600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Technical Remark',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.gray500),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Input
              CustomTextInput(
                label: 'Remark',
                controller: remarkController,
                hint: 'Enter technical remark...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a remark';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.gray600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    text: 'Save Remark',
                    onPressed: () async {
                      if (remarkController.text.trim().isEmpty) return;

                      Navigator.pop(dialogContext);

                      // Show loading
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving remark...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      try {
                        final apiService = ApiService();
                        await apiService.assignProjectActivityStaff(
                          projectId: widget.project.id,
                          phase: phaseId,
                          activity: activityId,
                          technicalRemarks: remarkController.text.trim(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Technical remark updated successfully',
                              ),
                              backgroundColor: AppTheme.green500,
                            ),
                          );
                          if (widget.onRefresh != null) {
                            widget.onRefresh!();
                          }
                        }
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating remark: $e'),
                              backgroundColor: AppTheme.red500,
                            ),
                          );
                        }
                      }
                    },
                    variant: ButtonVariant.default_,
                    size: ButtonSize.default_,
                  ),
                ],
              ),
            ],
          ),
        ),
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
                    ...phase.activities.asMap().entries.map((activityEntry) {
                      final activityIndex = activityEntry.key;
                      final activity = activityEntry.value;

                      // Check Phase-Level Lock
                      final isPrevPhaseUnlocked = _isPreviousPhaseUnlocked(
                        phaseIndex,
                      );
                      final isPhaseLocked =
                          phaseIndex > 0 && !isPrevPhaseUnlocked;

                      // Check Intra-Phase Sequential Lock
                      bool isSequentialLocked = false;
                      if (activityIndex > 0) {
                        final prevActivity =
                            phase.activities[activityIndex - 1];
                        final isPrevDone =
                            prevActivity.status == ActivityStatus.completed &&
                            prevActivity.approvalStatus?.toLowerCase() ==
                                'accepted';
                        if (!isPrevDone) {
                          isSequentialLocked = true;
                        }
                      }

                      // Combine Locks
                      final isLocked = isPhaseLocked || isSequentialLocked;

                      // Determine Lock Color / Type
                      bool isRedLock = true;
                      bool isPhaseLockInteractable = false;

                      if (isPhaseLocked) {
                        final previousPhaseIndex = phaseIndex - 1;
                        final arePreviousActivitiesComplete =
                            _areAllActivitiesCompletedAndAccepted(
                              previousPhaseIndex,
                            );

                        if (arePreviousActivitiesComplete) {
                          // Green Lock: Ready for Form
                          isRedLock = false;
                        } else {
                          // Red Lock: Not ready
                          isRedLock = true;
                        }

                        // Only the FIRST activity lock is the gatekeeper for the Phase Form
                        if (activityIndex == 0) {
                          isPhaseLockInteractable = true;
                        }
                      } else if (isSequentialLocked) {
                        // Sequential Lock Logic
                        // Waiting on previous activity -> Red Lock
                        isRedLock = true;
                        isPhaseLockInteractable =
                            false; // Just a sequential lock
                      }

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
                                      currentReminderDays:
                                          activity.reminderDays,
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
                                          color:
                                              activity.responsiblePerson.isEmpty
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
                            _Cell(
                              _formatReviewDate(activity.reviewDate),
                              width: 150,
                            ),

                            // Approval Staff
                            _Cell(activity.approvingStaff ?? '-', width: 180),

                            // Status
                            Container(
                              width: 120,
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  if (isLocked)
                                    InkWell(
                                      onTap: () {
                                        if (isPhaseLockInteractable) {
                                          _handlePhaseLockClick(
                                            context,
                                            phaseIndex,
                                            phase.name,
                                            phase.id,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isSequentialLocked
                                                    ? 'Please complete the previous activity first.'
                                                    : 'Phase is currently locked.',
                                              ),
                                              backgroundColor: AppTheme.gray900,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isRedLock
                                              ? AppTheme.red50
                                              : AppTheme.green50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          size: 16,
                                          color: isRedLock
                                              ? AppTheme.red600
                                              : AppTheme.green600,
                                        ),
                                      ),
                                    )
                                  else
                                    activity.managerReason != null &&
                                            activity.managerReason!.isNotEmpty
                                        ? Tooltip(
                                            message:
                                                activity.managerReason ?? '',
                                            child: CustomBadge(
                                              text: _capitalizeFirst(
                                                _getStatusString(
                                                  activity.status,
                                                ),
                                              ),
                                              variant: _getStatusBadgeVariant(
                                                activity.status,
                                              ),
                                            ),
                                          )
                                        : CustomBadge(
                                            text: _capitalizeFirst(
                                              _getStatusString(activity.status),
                                            ),
                                            variant: _getStatusBadgeVariant(
                                              activity.status,
                                            ),
                                          ),
                                ],
                              ),
                            ),

                            // Technical Remarks
                            Container(
                              width: 200,
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              alignment: Alignment.centerLeft,
                              child:
                                  activity.technicalRemarks == null ||
                                      activity.technicalRemarks!.isEmpty
                                  ? !isLocked
                                        ? CustomButton(
                                            text: 'Add Remark',
                                            onPressed: () =>
                                                _showTechnicalRemarkDialog(
                                                  context,
                                                  phase.id,
                                                  activity.id,
                                                  activity.name,
                                                ),
                                            variant: ButtonVariant.outline,
                                            size: ButtonSize.sm,
                                          )
                                        : Center(
                                            child: Text(
                                              '-',
                                              style: TextStyle(
                                                color: AppTheme.gray500,
                                              ),
                                            ),
                                          )
                                  : Text(
                                      activity.technicalRemarks!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.gray900,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),

                            // Acceptance Status
                            _Cell(
                              activity.approvalStatus != null
                                  ? _capitalizeFirst(activity.approvalStatus!)
                                  : '-',
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _showDateTooltip(context, activity);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: !isLocked
                                                  ? _getStatusColor(
                                                      activity.status,
                                                    )
                                                  : Colors.grey.shade400,
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
          child: Icon(icon, size: 18, color: color),
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

class _RequirementItem extends StatelessWidget {
  final String text;

  const _RequirementItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: AppTheme.green600),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
        ),
      ],
    );
  }
}
