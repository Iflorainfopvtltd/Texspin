import '../models/models.dart';

class ProjectConverter {
  static Project fromApiJson(Map<String, dynamic> json) {
    // Extract team leader name
    final teamLeaderObj = json['teamLeader'] as Map<String, dynamic>?;
    final teamLeaderName = teamLeaderObj != null
        ? '${teamLeaderObj['firstName'] ?? ''} ${teamLeaderObj['lastName'] ?? ''}'
              .trim()
        : '';

    // Extract team members names
    final teamMembersList = json['teamMembers'] as List<dynamic>? ?? [];
    final teamMembersNames = teamMembersList
        .map((member) {
          final memberObj = member as Map<String, dynamic>;
          return '${memberObj['firstName'] ?? ''} ${memberObj['lastName'] ?? ''}'
              .trim();
        })
        .where((name) => name.isNotEmpty)
        .toList();

    // Extract phases
    final phasesList = json['phases'] as List<dynamic>? ?? [];
    final phases = phasesList.map((phaseData) {
      final phaseObj = phaseData as Map<String, dynamic>;
      final phase = phaseObj['phase'] as Map<String, dynamic>?;
      final phaseId = phase?['_id'] ?? '';
      final phaseName = phase?['name'] ?? '';

      // Extract activities
      final activitiesList = phaseObj['activities'] as List<dynamic>? ?? [];
      final activities = activitiesList.map((activityData) {
        final activityObj = activityData as Map<String, dynamic>;
        final activity = activityObj['activity'] as Map<String, dynamic>?;
        final activityId = activity?['_id'] ?? '';
        final activityName = activity?['name'] ?? '';
        final statusStr =
            activityObj['activityStatus'] as String? ??
            activityObj['status'] as String? ??
            'pending';
        final staffObj = activityObj['staff'] as Map<String, dynamic>?;
        final responsiblePerson = staffObj != null
            ? '${staffObj['firstName'] ?? ''} ${staffObj['lastName'] ?? ''}'
                  .trim()
            : '';
        final staffId =
            staffObj?['_id']?.toString() ?? staffObj?['id']?.toString();
        final reviewDate = activityObj['reviewDate'] as String?;
        final approvingStaffObj =
            activityObj['approvingStaff'] as Map<String, dynamic>?;
        final approvingStaff = approvingStaffObj != null
            ? '${approvingStaffObj['firstName'] ?? ''} ${approvingStaffObj['lastName'] ?? ''}'
                  .trim()
            : null;

        // Get technical remarks and approval status
        final technicalRemarks = activityObj['technicalRemarks'] as String?;
        final approvalStatus =
            activityObj['activityApprovalStatus'] as String? ??
            activityObj['approvalStatus'] as String?;

        // Get start and end weeks from API
        final startWeek = activityObj['startWeek'] as int? ?? 1;
        final endWeek =
            activityObj['endWeek'] as int? ??
            activityObj['numberOfWeeks'] as int? ??
            1;

        // Get start and end dates from API
        final startDate = activityObj['startDate'] as String?;
        final endDate = activityObj['endDate'] as String?;

        return Activity(
          id: activityId,
          name: activityName,
          responsiblePerson: responsiblePerson,
          staffId: staffId,
          startWeek: startWeek,
          endWeek: endWeek,
          startDate: startDate,
          endDate: endDate,
          status: ActivityStatusExtension.fromString(statusStr),
          reviewDate: reviewDate,
          approvingStaff: approvingStaff,
          technicalRemarks: technicalRemarks,
          approvalStatus: approvalStatus,
          managerReason: activityObj['managerReason'] as String?,
          reminderDays: activityObj['reminderDays'] is List
              ? (activityObj['reminderDays'] as List).isNotEmpty
                    ? (activityObj['reminderDays'] as List).first as int?
                    : null
              : activityObj['reminderDays'] as int?,
        );
      }).toList();

      return Phase(id: phaseId, name: phaseName, activities: activities);
    }).toList();

    // Get project progress from API or calculate
    final projectProgress = json['projectProgress'] as int? ?? 0;

    // Format revision date
    final revisionDateStr = json['revisionDate'] as String? ?? '';
    final revisionDate = revisionDateStr.isNotEmpty
        ? revisionDateStr.split('T')[0]
        : '';

    // Format date of issue
    final dateOfIssueStr = json['dateOfIssue'] as String? ?? '';
    final dateOfIssue = dateOfIssueStr.isNotEmpty
        ? dateOfIssueStr.split('T')[0]
        : '';

    // Format created at
    final createdAtStr = json['createdAt'] as String? ?? '';
    final createdAt = createdAtStr.isNotEmpty ? createdAtStr.split('T')[0] : '';

    return Project(
      id: json['_id'] ?? '',
      customerName: json['customerName'] ?? '',
      location: json['location'] ?? '',
      partName: json['partName'] ?? '',
      partNumber: json['partNumber'] ?? '',
      revisionNumber: json['revisionNumber'] ?? '',
      revisionDate: revisionDate,
      teamLeader: teamLeaderName,
      teamMembers: teamMembersNames,
      planNumber: json['planNumber'] ?? '',
      dateOfIssue: dateOfIssue,
      teamLeaderAuthorization: json['teamLeaderAuthorization'] ?? '',
      totalWeeks: json['totalNumberOfWeeks'] as int? ?? 0,
      phases: phases,
      createdAt: createdAt,
      progress: projectProgress,
      projectStatus: json['projectStatus'] ?? 'ongoing',
    );
  }

  static List<Project> fromApiResponse(Map<String, dynamic> response) {
    final projectsList = response['apqpProjects'] as List<dynamic>? ?? [];
    return projectsList
        .map((projectJson) => fromApiJson(projectJson as Map<String, dynamic>))
        .toList();
  }
}
