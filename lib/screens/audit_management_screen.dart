import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/create_audit_main_dialog.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class AuditManagementScreen extends StatefulWidget {
  const AuditManagementScreen({super.key});

  @override
  State<AuditManagementScreen> createState() => _AuditManagementScreenState();
}

class _AuditManagementScreenState extends State<AuditManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _audits = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchAudits();
  }

  Future<void> _fetchAudits() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAuditMains();
      if (response['audits'] != null) {
        setState(() {
          _audits = List<Map<String, dynamic>>.from(response['audits']);
        });
      }
    } catch (e) {
      developer.log('Error fetching audits: $e', name: 'AuditManagementScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audits: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAudits {
    if (_selectedFilter == 'all') return _audits;
    return _audits
        .where(
          (audit) => audit['auditStatus']?.toLowerCase() == _selectedFilter,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Management'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAudits),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CreateAuditMainDialog(
              onAuditCreated: () {
                _fetchAudits();
              },
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': _audits.length},
      {
        'key': 'open',
        'label': 'Open',
        'count': _audits.where((a) => a['auditStatus'] == 'open').length,
      },
      {
        'key': 'close',
        'label': 'Closed',
        'count': _audits.where((a) => a['auditStatus'] == 'close').length,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${filter['count']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAudits = _filteredAudits;

    if (filteredAudits.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAudits.length,
      itemBuilder: (context, index) {
        final audit = filteredAudits[index];
        return _buildAuditCard(audit);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppTheme.gray500),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No Audits Found'
                : 'No ${_selectedFilter.toUpperCase()} Audits',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first audit to get started',
            style: TextStyle(fontSize: 14, color: AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> audit) {
    final auditNumber = audit['auditNumber'] ?? 'N/A';
    final date = audit['date'] != null
        ? DateTime.parse(audit['date']).toString().split(' ')[0]
        : 'N/A';
    final template = audit['auditTemplate']?['name'] ?? 'N/A';
    final company = audit['companyName'] ?? 'N/A';
    final location = audit['location'] ?? 'N/A';
    final status = audit['auditStatus'] ?? 'open';
    final questions = audit['auditQuestions'] as List? ?? [];
    final createdBy = audit['createdBy']?['fullName'] ?? 'Unknown';

    // Calculate question status counts
    final pendingCount = questions
        .where((q) => q['status'] == 'Pending')
        .length;
    final completedCount = questions
        .where((q) => q['status'] == 'Approved')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAuditDetails(audit),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      auditNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),

              // Info Rows
              _buildInfoRow(Icons.calendar_today, 'Date', date),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.description, 'Template', template),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.business, 'Company', company),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Location', location),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Created By', createdBy),
              const SizedBox(height: 12),

              // Progress Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions Progress',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray700,
                          ),
                        ),
                        Text(
                          '$completedCount/${questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: questions.isNotEmpty
                          ? completedCount / questions.length
                          : 0,
                      backgroundColor: AppTheme.gray200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildProgressChip(
                          'Pending',
                          pendingCount,
                          AppTheme.orange100,
                          AppTheme.orange600,
                        ),
                        const SizedBox(width: 8),
                        _buildProgressChip(
                          'Completed',
                          completedCount,
                          AppTheme.green100,
                          AppTheme.green600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showQuestionsScreen(audit),
                    icon: const Icon(Icons.quiz, size: 16),
                    label: const Text('Questions'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _editAudit(audit),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gray600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppTheme.gray900),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'open':
        bgColor = AppTheme.green100;
        textColor = AppTheme.green600;
        break;
      case 'close':
      case 'closed':
        bgColor = AppTheme.red50;
        textColor = AppTheme.red600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressChip(
    String label,
    int count,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAuditDetails(Map<String, dynamic> audit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuditDetailsScreen(audit: audit)),
    );
  }

  void _showQuestionsScreen(Map<String, dynamic> audit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuditQuestionsScreen(audit: audit),
      ),
    );
  }

  void _editAudit(Map<String, dynamic> audit) {
    // TODO: Implement edit audit
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit audit - Coming soon')));
  }
}

// Audit Details Screen
class AuditDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> audit;

  const AuditDetailsScreen({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(audit['auditNumber'] ?? 'Audit Details'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard('Basic Information', [
              _buildDetailRow('Audit Number', audit['auditNumber']),
              _buildDetailRow(
                'Date',
                audit['date'] != null
                    ? DateTime.parse(audit['date']).toString().split(' ')[0]
                    : 'N/A',
              ),
              _buildDetailRow('Company', audit['companyName']),
              _buildDetailRow('Location', audit['location']),
              _buildDetailRow('Status', audit['auditStatus']),
            ]),
            const SizedBox(height: 16),

            if (audit['auditTemplate'] != null)
              _buildDetailCard('Template Information', [
                _buildDetailRow(
                  'Template Name',
                  audit['auditTemplate']['name'],
                ),
                _buildDetailRow(
                  'Segment',
                  audit['auditTemplate']['auditSegment']?['name'],
                ),
                _buildDetailRow(
                  'Type',
                  audit['auditTemplate']['auditType']?['name'],
                ),
              ]),
            const SizedBox(height: 16),

            _buildDetailCard('Team Information', [
              _buildDetailRow('Created By', audit['createdBy']?['fullName']),
              _buildStaffList('Team Members', audit['texspinStaffMember']),
              _buildVisitorList('Visitors', audit['visitCompanyMemberName']),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: AppTheme.gray900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(String label, List? staff) {
    if (staff == null || staff.isEmpty) {
      return _buildDetailRow(label, 'No staff assigned');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 8),
          ...staff
              .map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${member['firstName']} ${member['lastName']} (${member['email']})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildVisitorList(String label, List? visitors) {
    if (visitors == null || visitors.isEmpty) {
      return _buildDetailRow(label, 'No visitors');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 8),
          ...visitors
              .map(
                (visitor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${visitor['name']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

// Audit Questions Screen
class AuditQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic> audit;

  const AuditQuestionsScreen({super.key, required this.audit});

  @override
  State<AuditQuestionsScreen> createState() => _AuditQuestionsScreenState();
}

class _AuditQuestionsScreenState extends State<AuditQuestionsScreen> {
  String _selectedFilter = 'all';

  List<Map<String, dynamic>> get _questions {
    return List<Map<String, dynamic>>.from(
      widget.audit['auditQuestions'] ?? [],
    );
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_selectedFilter == 'all') return _questions;
    return _questions.where((q) => q['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Questions'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildQuestionsList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final statuses = [
      'all',
      'Pending',
      'Assigned',
      'Accepted',
      'Rejected',
      'Submitted',
      'Approved',
      'Revision',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _selectedFilter == status;
            final count = status == 'all'
                ? _questions.length
                : _questions.where((q) => q['status'] == status).length;

            if (count == 0 && status != 'all') return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('$status ($count)'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = status;
                  });
                },
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    final filteredQuestions = _filteredQuestions;

    if (filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: AppTheme.gray500),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No Questions'
                  : 'No $_selectedFilter Questions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = filteredQuestions[index];
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionText = question['question'] ?? 'N/A';
    final status = question['status'] ?? 'Pending';
    final deadline = question['deadline'] != null
        ? DateTime.parse(question['deadline']).toString().split(' ')[0]
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            if (deadline != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppTheme.gray600),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: $deadline',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildActionButtons(question, status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
        break;
      case 'Assigned':
        bgColor = AppTheme.blue50;
        textColor = AppTheme.blue600;
        break;
      case 'Accepted':
        bgColor = AppTheme.purple100;
        textColor = AppTheme.purple600;
        break;
      case 'Rejected':
        bgColor = AppTheme.red50;
        textColor = AppTheme.red600;
        break;
      case 'Submitted':
        bgColor = AppTheme.orange100;
        textColor = AppTheme.orange600;
        break;
      case 'Approved':
        bgColor = AppTheme.green100;
        textColor = AppTheme.green600;
        break;
      case 'Revision':
        bgColor = AppTheme.yellow100;
        textColor = AppTheme.yellow600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    Map<String, dynamic> question,
    String status,
  ) {
    switch (status) {
      case 'Pending':
        return [
          _buildActionButton(
            'Assign',
            Icons.person_add,
            AppTheme.blue600,
            () => _assignStaff(question),
          ),
          _buildActionButton(
            'Edit',
            Icons.edit,
            AppTheme.gray600,
            () => _editQuestion(question),
          ),
          _buildActionButton(
            'Delete',
            Icons.delete,
            AppTheme.red500,
            () => _deleteQuestion(question),
          ),
        ];

      case 'Assigned':
        return [
          _buildActionButton(
            'Reassign',
            Icons.swap_horiz,
            AppTheme.blue600,
            () => _reassignStaff(question),
          ),
          _buildActionButton(
            'Reminder',
            Icons.notifications,
            AppTheme.orange600,
            () => _sendReminder(question),
          ),
          _buildActionButton(
            'Edit',
            Icons.edit,
            AppTheme.gray600,
            () => _editQuestion(question),
          ),
        ];

      case 'Accepted':
        return [
          _buildActionButton(
            'Reassign',
            Icons.swap_horiz,
            AppTheme.blue600,
            () => _reassignStaff(question),
          ),
          _buildActionButton(
            'Reminder',
            Icons.notifications,
            AppTheme.orange600,
            () => _sendReminder(question),
          ),
        ];

      case 'Rejected':
        return [
          _buildActionButton(
            'Reassign',
            Icons.swap_horiz,
            AppTheme.blue600,
            () => _reassignStaff(question),
          ),
          _buildActionButton(
            'Edit',
            Icons.edit,
            AppTheme.gray600,
            () => _editQuestion(question),
          ),
        ];

      case 'Submitted':
        return [
          _buildActionButton(
            'Download',
            Icons.download,
            AppTheme.green600,
            () => _downloadFile(question),
          ),
          _buildActionButton(
            'Approve',
            Icons.check,
            AppTheme.green600,
            () => _approveSubmission(question),
          ),
          _buildActionButton(
            'Reject',
            Icons.close,
            AppTheme.red500,
            () => _rejectSubmission(question),
          ),
        ];

      case 'Approved':
        return [
          _buildActionButton(
            'Download',
            Icons.download,
            AppTheme.green600,
            () => _downloadFile(question),
          ),
        ];

      case 'Revision':
        return [
          _buildActionButton(
            'Download',
            Icons.download,
            AppTheme.green600,
            () => _downloadFile(question),
          ),
          _buildActionButton(
            'Reassign',
            Icons.swap_horiz,
            AppTheme.blue600,
            () => _reassignStaff(question),
          ),
          _buildActionButton(
            'Reminder',
            Icons.notifications,
            AppTheme.orange600,
            () => _sendReminder(question),
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Action Methods (same as in dialog)
  void _assignStaff(Map<String, dynamic> question) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assign staff - Coming soon')));
  }

  void _reassignStaff(Map<String, dynamic> question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reassign staff - Coming soon')),
    );
  }

  void _sendReminder(Map<String, dynamic> question) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder sent!')));
  }

  void _editQuestion(Map<String, dynamic> question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit question - Coming soon')),
    );
  }

  void _deleteQuestion(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete logic
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.red500),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadFile(Map<String, dynamic> question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download file - Coming soon')),
    );
  }

  void _approveSubmission(Map<String, dynamic> question) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Submission approved!')));
  }

  void _rejectSubmission(Map<String, dynamic> question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submission rejected - moved to Revision')),
    );
  }
}
