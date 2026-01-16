class User {
  final String id;
  final String email;
  final String name;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });
}

class Activity {
  final String id;
  final String name;
  final String responsiblePerson;
  final String? staffId;
  final int startWeek;
  final int endWeek;
  final String? startDate;
  final String? endDate;
  final ActivityStatus status;
  final String? reviewDate;
  final String? approvingStaff;
  final String? technicalRemarks;
  final String? approvalStatus;
  final String? managerReason;
  final int? reminderDays;

  Activity({
    required this.id,
    required this.name,
    required this.responsiblePerson,
    this.staffId,
    required this.startWeek,
    required this.endWeek,
    this.startDate,
    this.endDate,
    required this.status,
    this.reviewDate,
    this.approvingStaff,
    this.technicalRemarks,
    this.approvalStatus,
    this.managerReason,
    this.reminderDays,
  });

  Activity copyWith({
    String? id,
    String? name,
    String? responsiblePerson,
    String? staffId,
    int? startWeek,
    int? endWeek,
    String? startDate,
    String? endDate,
    ActivityStatus? status,
    String? reviewDate,
    String? approvingStaff,
    String? technicalRemarks,
    String? approvalStatus,
    String? managerReason,
    int? reminderDays,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      staffId: staffId ?? this.staffId,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      reviewDate: reviewDate ?? this.reviewDate,
      approvingStaff: approvingStaff ?? this.approvingStaff,
      technicalRemarks: technicalRemarks ?? this.technicalRemarks,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      managerReason: managerReason ?? this.managerReason,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }
}

enum ActivityStatus { notStarted, pending, inProgress, submitted, completed }

extension ActivityStatusExtension on ActivityStatus {
  String get displayName {
    switch (this) {
      case ActivityStatus.notStarted:
        return 'Not Started';
      case ActivityStatus.pending:
        return 'Pending';
      case ActivityStatus.inProgress:
        return 'In Progress';
      case ActivityStatus.submitted:
        return 'Submitted';
      case ActivityStatus.completed:
        return 'Completed';
    }
  }

  static ActivityStatus fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'not started':
        return ActivityStatus.notStarted;
      case 'pending':
        return ActivityStatus.pending;
      case 'in progress':
        return ActivityStatus
            .inProgress; // 'ongoing' mapped below if needed, but keeping simple
      case 'ongoing':
        return ActivityStatus.inProgress;
      case 'submitted':
        return ActivityStatus.submitted;
      case 'completed':
      case 'done':
        return ActivityStatus.completed;
      default:
        return ActivityStatus.notStarted;
    }
  }
}

class Phase {
  final String id;
  final String name;
  final List<Activity> activities;

  Phase({required this.id, required this.name, required this.activities});

  Phase copyWith({String? id, String? name, List<Activity>? activities}) {
    return Phase(
      id: id ?? this.id,
      name: name ?? this.name,
      activities: activities ?? this.activities,
    );
  }
}

class Project {
  final String id;
  final String customerName;
  final String location;
  final String partName;
  final String partNumber;
  final String revisionNumber;
  final String revisionDate;
  final String teamLeader;
  final List<String> teamMembers;
  final String planNumber;
  final String dateOfIssue;
  final String teamLeaderAuthorization;
  final int totalWeeks;
  final List<Phase> phases;
  final String createdAt;
  final int progress;
  final String projectStatus;
  final String? templateId;

  Project({
    required this.id,
    required this.customerName,
    required this.location,
    required this.partName,
    required this.partNumber,
    required this.revisionNumber,
    required this.revisionDate,
    required this.teamLeader,
    required this.teamMembers,
    required this.planNumber,
    required this.dateOfIssue,
    required this.teamLeaderAuthorization,
    required this.totalWeeks,
    required this.phases,
    required this.createdAt,
    required this.progress,
    required this.projectStatus,
    this.templateId,
  });

  Project copyWith({
    String? id,
    String? customerName,
    String? location,
    String? partName,
    String? partNumber,
    String? revisionNumber,
    String? revisionDate,
    String? teamLeader,
    List<String>? teamMembers,
    String? planNumber,
    String? dateOfIssue,
    String? teamLeaderAuthorization,
    int? totalWeeks,
    List<Phase>? phases,
    String? createdAt,
    int? progress,
    String? projectStatus,
  }) {
    return Project(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      location: location ?? this.location,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      revisionDate: revisionDate ?? this.revisionDate,
      teamLeader: teamLeader ?? this.teamLeader,
      teamMembers: teamMembers ?? this.teamMembers,
      planNumber: planNumber ?? this.planNumber,
      dateOfIssue: dateOfIssue ?? this.dateOfIssue,
      teamLeaderAuthorization:
          teamLeaderAuthorization ?? this.teamLeaderAuthorization,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      phases: phases ?? this.phases,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      projectStatus: projectStatus ?? this.projectStatus,
    );
  }
}

class TeamMember {
  final String id;
  final String name;
  final String role;

  TeamMember({required this.id, required this.name, required this.role});
}

// API Entity Models
class Designation {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Designation({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }
}

class Zone {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Zone({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }
}

class Department {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }
}

class PhaseEntity {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  PhaseEntity({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PhaseEntity.fromJson(Map<String, dynamic> json) {
    return PhaseEntity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }
}

class WorkCategory {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  WorkCategory({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkCategory.fromJson(Map<String, dynamic> json) {
    return WorkCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }
}

class Staff {
  final String id;
  final String staffId;
  final String fullName;
  final String email;
  final String? mobile;
  final String? designation;
  final String? department;
  final String? zone;
  final String? workCategory;
  final String role;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Staff({
    required this.id,
    required this.staffId,
    required this.fullName,
    required this.email,
    this.mobile,
    this.designation,
    this.department,
    this.zone,
    this.workCategory,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? json['id'] ?? '',
      staffId: json['staffId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      designation: json['designation'],
      department: json['department'],
      zone: json['zone'],
      workCategory: json['workCategory'],
      role: json['role'] ?? 'staff',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'designation': designation,
      'department': department,
      'zone': zone,
      'workCategory': workCategory,
      'role': role,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class Task {
  final String id;
  final String name;
  final String description;
  final String? deadline;
  final Map<String, dynamic> assignedStaff;
  final Map<String, dynamic> createdBy;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? fileName;
  final String? fileUrl;
  final String? viewUrl;
  final String? downloadUrl;
  final List<Map<String, dynamic>>? attachments;
  final String? rejectionReason;
  final bool? isRecurringActive;
  final int? frequency;
  final String? lastOccurrence;
  final List<int>? reminderDays;

  Task({
    required this.id,
    required this.name,
    required this.description,
    this.deadline,
    required this.assignedStaff,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fileName,
    this.fileUrl,
    this.viewUrl,
    this.downloadUrl,
    this.attachments,
    this.rejectionReason,
    this.isRecurringActive,
    this.frequency,
    this.lastOccurrence,
    this.reminderDays,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'],
      assignedStaff: json['assignedStaff'] ?? {},
      createdBy: json['createdBy'] ?? {},
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      viewUrl: json['viewUrl'],
      downloadUrl: json['downloadUrl'],
      attachments: json['attachments'] != null
          ? List<Map<String, dynamic>>.from(json['attachments'])
          : null,
      rejectionReason: json['rejectionReason'],
      isRecurringActive: json['isRecurringActive'],
      frequency: json['frequency'],
      lastOccurrence: json['lastOccurrence'],
      reminderDays: (json['reminderDays'] ?? json['reminder_days']) == null
          ? null
          : (json['reminderDays'] ?? json['reminder_days']) is List
          ? ((json['reminderDays'] ?? json['reminder_days']) as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : [
              int.tryParse(
                    (json['reminderDays'] ?? json['reminder_days']).toString(),
                  ) ??
                  0,
            ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (deadline != null) 'deadline': deadline,
      'assignedStaff': assignedStaff,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (fileName != null) 'fileName': fileName,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (viewUrl != null) 'viewUrl': viewUrl,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (attachments != null) 'attachments': attachments,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (isRecurringActive != null) 'isRecurringActive': isRecurringActive,
      if (frequency != null) 'frequency': frequency,
      if (lastOccurrence != null) 'lastOccurrence': lastOccurrence,
      if (reminderDays != null) 'reminderDays': reminderDays,
    };
  }
}

class DepartmentTask {
  final String id;
  final String name;
  final String description;
  final String? deadline;
  final Map<String, dynamic> assignedStaff;
  final Map<String, dynamic> createdBy;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? fileName;
  final String? fileUrl;
  final String? viewUrl;
  final String? downloadUrl;
  final List<Map<String, dynamic>>? attachments;
  final String? rejectionReason;
  final bool? isRecurringActive;
  final int? frequency;
  final String? lastOccurrence;
  final List<int>? reminderDays;

  DepartmentTask({
    required this.id,
    required this.name,
    required this.description,
    this.deadline,
    required this.assignedStaff,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fileName,
    this.fileUrl,
    this.viewUrl,
    this.downloadUrl,
    this.attachments,
    this.rejectionReason,
    this.isRecurringActive,
    this.frequency,
    this.lastOccurrence,
    this.reminderDays,
  });

  DepartmentTask copyWith({
    String? id,
    String? name,
    String? description,
    String? deadline,
    Map<String, dynamic>? assignedStaff,
    Map<String, dynamic>? createdBy,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? fileName,
    String? fileUrl,
    String? viewUrl,
    String? downloadUrl,
    List<Map<String, dynamic>>? attachments,
    String? rejectionReason,
    bool? isRecurringActive,
    int? frequency,
    String? lastOccurrence,
    List<int>? reminderDays,
  }) {
    return DepartmentTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      viewUrl: viewUrl ?? this.viewUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      attachments: attachments ?? this.attachments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isRecurringActive: isRecurringActive ?? this.isRecurringActive,
      frequency: frequency ?? this.frequency,
      lastOccurrence: lastOccurrence ?? this.lastOccurrence,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }

  factory DepartmentTask.fromJson(Map<String, dynamic> json) {
    return DepartmentTask(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'],
      assignedStaff: json['assignedStaff'] ?? {},
      createdBy: json['createdBy'] ?? {},
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      viewUrl: json['viewUrl'],
      downloadUrl: json['downloadUrl'],
      attachments: json['attachments'] != null
          ? List<Map<String, dynamic>>.from(json['attachments'])
          : null,
      rejectionReason: json['rejectionReason'],
      isRecurringActive: json['isRecurringActive'],
      frequency: json['frequency'],
      lastOccurrence: json['lastOccurrence'],
      reminderDays: (json['reminderDays'] ?? json['reminder_days']) == null
          ? null
          : (json['reminderDays'] ?? json['reminder_days']) is List
          ? ((json['reminderDays'] ?? json['reminder_days']) as List)
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .toList()
          : [
              int.tryParse(
                    (json['reminderDays'] ?? json['reminder_days']).toString(),
                  ) ??
                  0,
            ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (deadline != null) 'deadline': deadline,
      'assignedStaff': assignedStaff,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (fileName != null) 'fileName': fileName,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (viewUrl != null) 'viewUrl': viewUrl,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (attachments != null) 'attachments': attachments,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (isRecurringActive != null) 'isRecurringActive': isRecurringActive,
      if (frequency != null) 'frequency': frequency,
      if (lastOccurrence != null) 'lastOccurrence': lastOccurrence,
      if (reminderDays != null) 'reminderDays': reminderDays,
    };
  }
}

// Audit Models
class AuditType {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  AuditType({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AuditType.fromJson(Map<String, dynamic> json) {
    return AuditType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AuditSegment {
  final String id;
  final String name;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  AuditSegment({
    required this.id,
    required this.name,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AuditSegment.fromJson(Map<String, dynamic> json) {
    return AuditSegment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'status': status};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditSegment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AuditQuestion {
  final String id;
  final String question;
  final String? answer;
  final String? auditQueCategory;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  AuditQuestion({
    required this.id,
    required this.question,
    this.answer,
    this.auditQueCategory,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AuditQuestion.fromJson(Map<String, dynamic> json) {
    return AuditQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'],
      auditQueCategory: json['auditQueCategory'] is Map
          ? (json['auditQueCategory']['_id'] ?? json['auditQueCategory']['id'])
          : json['auditQueCategory'],
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      if (answer != null) 'answer': answer,
      if (auditQueCategory != null) 'auditQueCategory': auditQueCategory,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AuditTemplate {
  final String id;
  final String name;
  final AuditSegment auditSegment;
  final AuditType auditType;
  final List<AuditQuestion> auditQuestions;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  AuditTemplate({
    required this.id,
    required this.name,
    required this.auditSegment,
    required this.auditType,
    required this.auditQuestions,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AuditTemplate.fromJson(Map<String, dynamic> json) {
    return AuditTemplate(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      auditSegment: AuditSegment.fromJson({
        'id': json['auditSegment']['_id'] ?? json['auditSegment']['id'] ?? '',
        'name': json['auditSegment']['name'] ?? '',
        'status': 'active', // Default status for nested objects
      }),
      auditType: AuditType.fromJson({
        'id': json['auditType']['_id'] ?? json['auditType']['id'] ?? '',
        'name': json['auditType']['name'] ?? '',
        'status': 'active', // Default status for nested objects
      }),
      auditQuestions: (json['auditQuestions'] as List? ?? [])
          .map(
            (q) => AuditQuestion.fromJson({
              'id': q['_id'] ?? q['id'] ?? '',
              'question': q['question'] ?? '',
              'answer': q['answer'],
              'status': 'active', // Default status for nested objects
            }),
          )
          .toList(),
      status: json['status'] ?? 'active',
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'auditSegment': auditSegment.id,
      'auditType': auditType.id,
      'auditQuestions': auditQuestions.map((q) => q.id).toList(),
    };
  }
}
