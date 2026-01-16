class AuditMain {
  final String id;
  final String date;
  final String status;
  final Map<String, dynamic>? createdBy;
  final List<Map<String, dynamic>>? texspinStaffMember; // For Auditors
  final List<Map<String, dynamic>>? visitCompanyMemberName; // For Auditees
  final Map<String, dynamic>? auditTemplate;
  final Map<String, dynamic>?
  department; // Note: JSON shows department as null mostly or not present? JSON doesn't show department at root in provided snippet (inside auditTemplate maybe? No).
  // The JSON provided has "companyName", "location", "onModel".
  // It does NOT have "department" key in the example.
  // But our previous model had "department". I will keep it optional.

  final String? createdAt;
  final String? updatedAt;

  // Doc fields from JSON
  final String? previousDoc;
  final String? otherDoc;
  final String? auditMethodology;
  final String? auditObservation;
  final String? actionPlan;
  final String? actionEvidence;
  final List<String>? otherDocs;
  final int? auditScore;
  final String? auditNumber;
  final String? companyName;
  final String? location;
  final List<Map<String, dynamic>>? auditQuestions;

  AuditMain({
    required this.id,
    required this.date,
    required this.status,
    this.createdBy,
    this.texspinStaffMember,
    this.visitCompanyMemberName,
    this.auditTemplate,
    this.department,
    this.createdAt,
    this.updatedAt,
    this.previousDoc,
    this.otherDoc,
    this.auditMethodology,
    this.auditObservation,
    this.actionPlan,
    this.actionEvidence,
    this.otherDocs,
    this.auditScore,
    this.auditNumber,
    this.companyName,
    this.location,
    this.auditQuestions,
  });

  factory AuditMain.fromJson(Map<String, dynamic> json) {
    return AuditMain(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] ?? '',
      status:
          json['auditStatus'] ??
          json['status'] ??
          'pending', // JSON uses 'auditStatus': 'open' but also has 'date' etc. Let's check status field. The JSON has "auditStatus": "open". It doesn't have a root "status". Wait.
      // The provided JSON has "auditStatus": "open".
      // Our previous code used "status". I should map "auditStatus" to "status" if "status" is missing.
      createdBy: json['createdBy'] is Map ? json['createdBy'] : null,

      texspinStaffMember: json['texspinStaffMember'] != null
          ? List<Map<String, dynamic>>.from(json['texspinStaffMember'])
          : null,

      visitCompanyMemberName: json['visitCompanyMemberName'] != null
          ? List<Map<String, dynamic>>.from(json['visitCompanyMemberName'])
          : null,

      auditTemplate: json['auditTemplate'] is Map
          ? json['auditTemplate']
          : null,
      department: json['department'] is Map ? json['department'] : null,

      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],

      previousDoc: json['previousDoc'],
      otherDoc: json['otherDoc'],
      auditMethodology: json['auditMethodology'],
      auditObservation: json['auditObservation'],
      actionPlan: json['actionPlan'],
      actionEvidence: json['actionEvidence'],
      otherDocs: json['otherDocs'] != null
          ? List<String>.from(json['otherDocs'])
          : null,

      auditScore: json['auditScore'],
      auditNumber: json['auditNumber'],
      companyName: json['companyName'],
      location: json['location'],
      auditQuestions: json['auditQuestions'] != null
          ? List<Map<String, dynamic>>.from(json['auditQuestions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'createdBy': createdBy,
      'texspinStaffMember': texspinStaffMember,
      'visitCompanyMemberName': visitCompanyMemberName,
      'auditTemplate': auditTemplate,
      'department': department,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'previousDoc': previousDoc,
      'otherDoc': otherDoc,
      'auditMethodology': auditMethodology,
      'auditObservation': auditObservation,
      'actionPlan': actionPlan,
      'actionEvidence': actionEvidence,
      'otherDocs': otherDocs,
      'auditScore': auditScore,
      'auditNumber': auditNumber,
      'companyName': companyName,
      'location': location,
    };
  }
}
