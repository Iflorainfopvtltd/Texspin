class AuditMain {
  final String id;
  final String date;
  final String status;
  final Map<String, dynamic>? auditor;
  final Map<String, dynamic>? auditee;
  final Map<String, dynamic>? auditTemplate;
  final Map<String, dynamic>? department;
  final String? createdAt;
  final String? updatedAt;
  final String? auditMethodology;
  final String? auditObservation;
  final String? actionPlan;
  final String? actionEvidence;
  final int? auditScore;

  AuditMain({
    required this.id,
    required this.date,
    required this.status,
    this.auditor,
    this.auditee,
    this.auditTemplate,
    this.department,
    this.createdAt,
    this.updatedAt,
    this.auditMethodology,
    this.auditObservation,
    this.actionPlan,
    this.actionEvidence,
    this.auditScore,
  });

  factory AuditMain.fromJson(Map<String, dynamic> json) {
    return AuditMain(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      auditor: json['auditor'] is Map ? json['auditor'] : null,
      auditee: json['auditee'] is Map ? json['auditee'] : null,
      auditTemplate: json['auditTemplate'] is Map
          ? json['auditTemplate']
          : null,
      department: json['department'] is Map ? json['department'] : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      auditMethodology: json['auditMethodology'],
      auditObservation: json['auditObservation'],
      actionPlan: json['actionPlan'],
      actionEvidence: json['actionEvidence'],
      auditScore: json['auditScore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'auditor': auditor,
      'auditee': auditee,
      'auditTemplate': auditTemplate,
      'department': department,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'auditMethodology': auditMethodology,
      'auditObservation': auditObservation,
      'actionPlan': actionPlan,
      'actionEvidence': actionEvidence,
      'auditScore': auditScore,
    };
  }
}
