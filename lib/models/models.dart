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
    );
  }
}

enum ActivityStatus {
  notStarted,
  inProgress,
  completed,
}

extension ActivityStatusExtension on ActivityStatus {
  String get displayName {
    switch (this) {
      case ActivityStatus.notStarted:
        return 'Not Started';
      case ActivityStatus.inProgress:
        return 'In Progress';
      case ActivityStatus.completed:
        return 'Completed';
    }
  }

  static ActivityStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'not started':
      case 'pending':
        return ActivityStatus.notStarted;
      case 'in progress':
      case 'ongoing':
        return ActivityStatus.inProgress;
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

  Phase({
    required this.id,
    required this.name,
    required this.activities,
  });

  Phase copyWith({
    String? id,
    String? name,
    List<Activity>? activities,
  }) {
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
      teamLeaderAuthorization: teamLeaderAuthorization ?? this.teamLeaderAuthorization,
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

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
  });
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
    return {
      'name': name,
      'status': status,
    };
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
    return {
      'name': name,
      'status': status,
    };
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
    return {
      'name': name,
      'status': status,
    };
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
    return {
      'name': name,
      'status': status,
    };
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
    return {
      'name': name,
      'status': status,
    };
  }
}
