class StaffApqpProjectResponse {
  final String message;
  final int count;
  final List<StaffApqpProject> apqpProjects;

  StaffApqpProjectResponse({
    required this.message,
    required this.count,
    required this.apqpProjects,
  });

  factory StaffApqpProjectResponse.fromJson(Map<String, dynamic> json) {
    return StaffApqpProjectResponse(
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      apqpProjects: (json['apqpProjects'] as List? ?? [])
          .map((e) => StaffApqpProject.fromJson(e))
          .toList(),
    );
  }
}

class StaffApqpProject {
  final String id;
  final String customerName;
  final String partName;
  final String partNumber;
  final String projectStatus;
  final List<StaffApqpPhase> phases;

  StaffApqpProject({
    required this.id,
    required this.customerName,
    required this.partName,
    required this.partNumber,
    required this.projectStatus,
    required this.phases,
  });

  factory StaffApqpProject.fromJson(Map<String, dynamic> json) {
    return StaffApqpProject(
      id: json['_id'] ?? '',
      customerName: json['customerName'] ?? '',
      partName: json['partName'] ?? '',
      partNumber: json['partNumber'] ?? '',
      projectStatus: json['projectStatus'] ?? '',
      phases: (json['phases'] as List? ?? [])
          .map((e) => StaffApqpPhase.fromJson(e))
          .toList(),
    );
  }
}

class StaffApqpPhase {
  final String id;
  final StaffApqpPhaseDetail phase;
  final List<StaffApqpActivityWrapper> activities;

  StaffApqpPhase({
    required this.id,
    required this.phase,
    required this.activities,
  });

  factory StaffApqpPhase.fromJson(Map<String, dynamic> json) {
    return StaffApqpPhase(
      id: json['_id'] ?? '',
      phase: StaffApqpPhaseDetail.fromJson(json['phase'] ?? {}),
      activities: (json['activities'] as List? ?? [])
          .map((e) => StaffApqpActivityWrapper.fromJson(e))
          .toList(),
    );
  }
}

class StaffApqpPhaseDetail {
  final String id;
  final String name;
  final String status;

  StaffApqpPhaseDetail({
    required this.id,
    required this.name,
    required this.status,
  });

  factory StaffApqpPhaseDetail.fromJson(Map<String, dynamic> json) {
    return StaffApqpPhaseDetail(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class StaffApqpActivityWrapper {
  final String id;
  final StaffApqpActivityDetail activity;
  final StaffApqpStaff? staff;
  final String? startDate;
  final String? endDate;
  final String activityStatus;
  final String activityApprovalStatus;
  final String? technicalRemarks;
  final String? managerReason;
  final String? fileUrl;
  final String? rejectionReason;
  final String? staffReason;

  StaffApqpActivityWrapper({
    required this.id,
    required this.activity,
    this.staff,
    this.startDate,
    this.endDate,
    required this.activityStatus,
    required this.activityApprovalStatus,
    this.technicalRemarks,
    this.managerReason,
    this.fileUrl,
    this.rejectionReason,
    this.staffReason,
  });

  factory StaffApqpActivityWrapper.fromJson(Map<String, dynamic> json) {
    return StaffApqpActivityWrapper(
      id: json['_id'] ?? '',
      activity: StaffApqpActivityDetail.fromJson(json['activity'] ?? {}),
      staff: json['staff'] != null
          ? StaffApqpStaff.fromJson(json['staff'])
          : null,
      startDate: json['startDate'],
      endDate: json['endDate'],
      activityStatus: json['activityStatus'] ?? 'pending',
      activityApprovalStatus: json['activityApprovalStatus'] ?? 'pending',
      technicalRemarks: json['technicalRemarks'],
      managerReason: json['managerReason'],
      fileUrl: json['fileUrl'],
      rejectionReason: json['rejectionReason'],
      staffReason: json['staffReason'],
    );
  }
}

class StaffApqpActivityDetail {
  final String id;
  final String name;

  StaffApqpActivityDetail({required this.id, required this.name});

  factory StaffApqpActivityDetail.fromJson(Map<String, dynamic> json) {
    return StaffApqpActivityDetail(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class StaffApqpStaff {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String staffId;

  StaffApqpStaff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.staffId,
  });

  factory StaffApqpStaff.fromJson(Map<String, dynamic> json) {
    return StaffApqpStaff(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      staffId: json['staffId'] ?? '',
    );
  }
}
