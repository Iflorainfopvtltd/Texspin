// Additional API entity models for Search & Manage flows

class StaffEntity {
  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String gender;
  final String designation;
  final String zone;
  final String department;
  final String? role;
  final String? workCategory;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  StaffEntity({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.gender,
    required this.designation,
    required this.zone,
    required this.department,
    this.role,
    this.workCategory,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffEntity.fromJson(Map<String, dynamic> json) {
    return StaffEntity(
      id: json['id'] ?? json['_id'] ?? '',
      staffId: json['staffId'] ?? json['employeeCode'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      gender: json['gender'] ?? '',
      designation: json['designation']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      role: json['role']?.toString(),
      workCategory: json['workCategory'] is Map 
          ? (json['workCategory']['_id']?.toString() ?? json['workCategory']['id']?.toString())
          : json['workCategory']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'designation': designation,
      'zone': zone,
      'department': department,
    };
  }
}

class ActivityEntity {
  final String id;
  final String name;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  ActivityEntity({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityEntity.fromJson(Map<String, dynamic> json) {
    return ActivityEntity(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
    };
  }
}

// Template models
class TemplateActivity {
  final String activityId;
  final String name;
  final String status;

  TemplateActivity({
    required this.activityId,
    required this.name,
    required this.status,
  });

  factory TemplateActivity.fromJson(Map<String, dynamic> json) {
    return TemplateActivity(
      activityId: json['activityId']?.toString() ?? 
                  json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'name': name,
      'status': status,
    };
  }
}

class TemplatePhase {
  final String phaseId;
  final String name;
  final String status;
  final List<TemplateActivity> activities;

  TemplatePhase({
    required this.phaseId,
    required this.name,
    required this.status,
    required this.activities,
  });

  factory TemplatePhase.fromJson(Map<String, dynamic> json) {
    // Handle phaseId - could be string, Map with _id, or _id directly
    String phaseId = '';
    if (json['phaseId'] != null) {
      if (json['phaseId'] is String) {
        phaseId = json['phaseId'] as String;
      } else if (json['phaseId'] is Map) {
        phaseId = (json['phaseId'] as Map)['_id']?.toString() ?? '';
      }
    } else if (json['_id'] != null) {
      phaseId = json['_id'].toString();
    }
    
    // Handle name - could be direct field or nested in phaseId Map
    String name = '';
    if (json['name'] != null) {
      name = json['name'].toString();
    } else if (json['phaseId'] is Map) {
      name = (json['phaseId'] as Map)['name']?.toString() ?? '';
    }
    
    return TemplatePhase(
      phaseId: phaseId,
      name: name,
      status: json['status']?.toString() ?? 'active',
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => TemplateActivity.fromJson(a))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phaseId': phaseId,
      'name': name,
      'status': status,
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }
}

class TemplateEntity {
  final String id;
  final String templateName;
  final List<TemplatePhase> phases;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  TemplateEntity({
    required this.id,
    required this.templateName,
    required this.phases,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory TemplateEntity.fromJson(Map<String, dynamic> json) {
    return TemplateEntity(
      id: json['id'] ?? json['_id'] ?? '',
      templateName: json['templateName'] ?? '',
      phases: (json['phases'] as List<dynamic>?)
              ?.map((p) => TemplatePhase.fromJson(p))
              .toList() ?? [],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'templateName': templateName,
      'phases': phases.map((phase) {
        return {
          'phaseId': phase.phaseId,
          'activities': phase.activities.map((a) => a.activityId).toList(),
        };
      }).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'templateName': templateName,
    };
  }
}
