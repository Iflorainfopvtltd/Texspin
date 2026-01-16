import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/shared_preferences_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/create_audit_main_dialog.dart';
import '../widgets/assign_question_dialog.dart';
import '../widgets/review_question_dialog.dart';
import '../widgets/audit_transaction_dialog.dart';
import '../widgets/mom_form_dialog.dart';
import '../widgets/custom_text_input.dart';
import '../services/api_service.dart';
import '../models/audit_main.dart';
import 'staff_audit_task_submission_dialog.dart';
import 'dart:developer' as developer;

class AllAuditsDialog extends StatefulWidget {
  final bool isFullScreen;

  const AllAuditsDialog({super.key, this.isFullScreen = false});

  @override
  State<AllAuditsDialog> createState() => _AllAuditsDialogState();
}

class _AllAuditsDialogState extends State<AllAuditsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _audits = [];
  List<Map<String, dynamic>> _filteredAudits = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // My Tasks State
  final TextEditingController _myTasksSearchController =
      TextEditingController();
  String _myTasksSelectedFilter = 'all';
  List<Map<String, dynamic>> _myAudits = [];
  String? _currentStaffId;
  bool _isLoadingMyTasks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchAudits();
    _loadMyTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _myTasksSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterAudits();
    });
  }

  void _filterAudits() {
    if (_searchQuery.isEmpty) {
      _filteredAudits = List.from(_audits);
    } else {
      _filteredAudits = _audits.where((audit) {
        final auditNumber = (audit['auditNumber'] ?? '')
            .toString()
            .toLowerCase();
        final company = (audit['companyName'] ?? '').toString().toLowerCase();
        final location = (audit['location'] ?? '').toString().toLowerCase();
        final template = (audit['auditTemplate']?['name'] ?? '')
            .toString()
            .toLowerCase();
        final status = (audit['auditStatus'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return auditNumber.contains(query) ||
            company.contains(query) ||
            location.contains(query) ||
            template.contains(query) ||
            status.contains(query);
      }).toList();
    }
  }

  Future<void> _fetchAudits() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAuditMains();
      if (response['audits'] != null) {
        setState(() {
          _audits = List<Map<String, dynamic>>.from(response['audits']);
          _filterAudits();
        });
      }
    } catch (e) {
      developer.log('Error fetching audits: $e', name: 'AllAuditsDialog');
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

  Future<void> _loadMyTasks() async {
    setState(() => _isLoadingMyTasks = true);
    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId != null) {
        _currentStaffId = staffId;
        final response = await _apiService.getStaffAuditMains(staffId: staffId);
        if (response['audits'] != null) {
          setState(() {
            _myAudits = List<Map<String, dynamic>>.from(response['audits']);
          });
        } else if (response['auditMains'] != null) {
          setState(() {
            _myAudits = List<Map<String, dynamic>>.from(response['auditMains']);
          });
        }
      }
    } catch (e) {
      developer.log('Error loading my tasks: $e', name: 'AllAuditsDialog');
    } finally {
      setState(() => _isLoadingMyTasks = false);
    }
  }

  void _showCreateAudit(BuildContext context, bool isMobile) {
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateAuditMainDialog(
            onAuditCreated: _fetchAudits,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            CreateAuditMainDialog(onAuditCreated: _fetchAudits),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'All Audits (${_filteredAudits.length}${_searchQuery.isNotEmpty ? ' of ${_audits.length}' : ''})',
            style: const TextStyle(fontSize: 18),
          ),
          // backgroundColor: AppTheme.primary,
          // foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchAudits,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStaffAssignedTasksView(isMobile),
                  _buildMyTasksView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: () => _showCreateAudit(context, isMobile),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 1200,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, isMobile),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffAssignedTasksView(isMobile),
                      _buildMyTasksView(),
                    ],
                  ),
                ),
              ],
            ),
            if (_tabController.index == 0)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () => _showCreateAudit(context, isMobile),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      // decoration: const BoxDecoration(
      //   border: Border(bottom: BorderSide(color: AppTheme.border)),
      // ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.gray600,
        indicatorColor: AppTheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Staff Assigned Task'),
          Tab(text: 'My Tasks'),
        ],
      ),
    );
  }

  Widget _buildStaffAssignedTasksView(bool isMobile) {
    return Column(
      children: [
        _buildSearchBar(isMobile),
        Expanded(child: _buildContent(isMobile)),
      ],
    );
  }

  Widget _buildMyTasksView() {
    if (_isLoadingMyTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Flatten audits into questions assigned to current user
    final List<Map<String, dynamic>> myQuestions = [];
    if (_currentStaffId != null) {
      for (var audit in _myAudits) {
        final questions = audit['auditQuestions'] as List? ?? [];
        final staffList = audit['texspinStaffMember'] as List? ?? [];
        for (var q in questions) {
          if (q['assignedTo'] == _currentStaffId) {
            final questionMap = Map<String, dynamic>.from(q);
            questionMap['auditName'] = audit['auditTemplate']?['name'] ?? 'N/A';
            questionMap['auditDate'] = audit['date'];
            questionMap['auditId'] = audit['_id'] ?? audit['id'];

            final assignedToId = q['assignedTo'];
            final staff = staffList.firstWhere(
              (s) => (s['_id'] ?? s['id']) == assignedToId,
              orElse: () => null,
            );
            final assignedName = staff != null
                ? '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                      .trim()
                : 'Me';
            questionMap['assignedToName'] = assignedName;

            myQuestions.add(questionMap);
          }
        }
      }
    }

    // Filter Logic
    final filteredQuestions = myQuestions.where((q) {
      final status = (q['status'] ?? '').toString().toLowerCase();
      final query = _myTasksSearchController.text.toLowerCase();

      // Status Filter
      bool matchesStatus = false;
      if (_myTasksSelectedFilter == 'all') {
        matchesStatus = true;
      } else if (_myTasksSelectedFilter == 'approved') {
        matchesStatus = status == 'approved' || status == 'accepted';
      } else {
        matchesStatus = status == _myTasksSelectedFilter;
      }

      if (!matchesStatus) return false;

      // Search Filter
      final qText = (q['question'] ?? '').toString().toLowerCase();
      final aName = (q['auditName'] ?? '').toString().toLowerCase();

      return query.isEmpty || qText.contains(query) || aName.contains(query);
    }).toList();

    return Column(
      children: [
        // Filter Section
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomTextInput(
                hint: 'Search by audit name or question...',
                controller: _myTasksSearchController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMyTasksFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Assigned', 'assigned'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Revision', 'revision'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Accepted', 'approved'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Table or List
        Expanded(
          child: filteredQuestions.isEmpty
              ? const Center(child: Text('No personal tasks assigned'))
              : isMobile
              ? RefreshIndicator(
                  onRefresh: _loadMyTasks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQuestions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildMyAuditTaskCard(filteredQuestions[index]);
                    },
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyTasks,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: isMobile ? 16 : 24,
                      right: isMobile ? 16 : 24,
                      bottom: isMobile ? 16 : 24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: isMobile ? 16 : 24,
                          headingRowColor: WidgetStateProperty.all(
                            AppTheme.blue50,
                          ),
                          dataRowColor: WidgetStateProperty.all(Colors.white),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Audit Name',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Scheduled Date',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Assigned Question',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Assigned To',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          rows: filteredQuestions
                              .map((q) => _buildMyTasksDataRow(q))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMyAuditTaskCard(Map<String, dynamic> question) {
    final status = (question['status'] ?? 'pending').toString().toLowerCase();
    final dateStr = question['auditDate'] != null
        ? DateTime.parse(question['auditDate']).toString().split(' ')[0]
        : 'N/A';
    final auditName = question['auditName'] ?? 'N/A';
    final qText = question['question'] ?? '';
    final assignedTo = question['assignedToName'] ?? 'Me';

    // Action Logic Variables
    final auditId = question['auditId'];
    final questionId = question['_id'] ?? question['questionId'];
    final auditMap = _myAudits.firstWhere(
      (a) => (a['_id'] ?? a['id']) == auditId,
      orElse: () => {},
    );
    final AuditMain? auditMain = auditMap.isNotEmpty
        ? AuditMain.fromJson(auditMap)
        : null;

    final isPending = status == 'pending' || status == 'assigned';
    final isApproved =
        status == 'approved' || status == 'accepted' || status == 'ongoing';
    final isRevision = status == 'revision';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.assignment, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auditName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text (Content)
            Text(
              qText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.gray700,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Metadata
            _buildInfoRow(Icons.calendar_today, dateStr),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, assignedTo),
            const SizedBox(height: 16),

            // Actions
            if ((isApproved || isRevision) && auditMain != null)
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: isRevision ? 'Submit Revision' : 'Submit Audit',
                  icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                  variant: ButtonVariant.default_,
                  size: ButtonSize.sm,
                  isFullWidth: true,
                  onPressed: () {
                    final isMobile = MediaQuery.of(context).size.width < 600;
                    if (isMobile) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffAuditTaskSubmissionDialog(
                            task: auditMain,
                            question: question,
                            onSubmitted: _loadMyTasks,
                          ),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => StaffAuditTaskSubmissionDialog(
                          task: auditMain,
                          question: question,
                          onSubmitted: _loadMyTasks,
                        ),
                      );
                    }
                  },
                ),
              ),

            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Accept',
                      icon: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                      variant: ButtonVariant.default_,
                      size: ButtonSize.sm,
                      isFullWidth: true,
                      onPressed: () => _handleTaskResponse(
                        auditId,
                        'approved',
                        questionId: questionId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      icon: const Icon(
                        Icons.cancel,
                        size: 16,
                        color: AppTheme.primaryForeground,
                      ),
                      variant: ButtonVariant.destructive,
                      size: ButtonSize.sm,
                      isFullWidth: true,
                      onPressed: () => _showRejectDialog(auditId, questionId),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksFilterChip(String label, String value) {
    final isSelected = _myTasksSelectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.gray700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _myTasksSelectedFilter = value;
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
    );
  }

  DataRow _buildMyTasksDataRow(Map<String, dynamic> question) {
    final status = question['status'] ?? 'pending';
    final dateStr = question['auditDate'] != null
        ? DateTime.parse(question['auditDate']).toString().split(' ')[0]
        : 'N/A';

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              question['auditName'] ?? 'N/A',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
          ),
        ),
        DataCell(
          Text(dateStr, style: const TextStyle(color: AppTheme.gray700)),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              question['question'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              question['assignedToName'] ?? 'Me',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(_buildStatusBadge(status)),
        DataCell(_buildMyTasksActions(question)),
      ],
    );
  }

  Widget _buildMyTasksActions(Map<String, dynamic> question) {
    final status = (question['status'] ?? 'pending').toString().toLowerCase();
    final auditId = question['auditId'];
    final questionId = question['_id'] ?? question['questionId'];

    // Find the full audit object for submission dialog context
    final auditMap = _myAudits.firstWhere(
      (a) => (a['_id'] ?? a['id']) == auditId,
      orElse: () => {},
    );

    // Convert to AuditMain if valid audit found
    final AuditMain? auditMain = auditMap.isNotEmpty
        ? AuditMain.fromJson(auditMap)
        : null;

    final isPending = status == 'pending' || status == 'assigned';
    final isApproved =
        status == 'approved' || status == 'accepted' || status == 'ongoing';
    final isRevision = status == 'revision';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((isApproved || isRevision) && auditMain != null)
          IconButton(
            icon: const Icon(Icons.upload, color: AppTheme.blue600),
            tooltip: isRevision ? 'Submit Revision' : 'Submit Audit',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StaffAuditTaskSubmissionDialog(
                  task: auditMain,
                  question: question,
                  onSubmitted: _loadMyTasks,
                ),
              );
            },
          ),
        if (isPending) ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppTheme.green600),
            tooltip: 'Accept',
            onPressed: () => _handleTaskResponse(
              auditId,
              'approved',
              questionId: questionId,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppTheme.red500),
            tooltip: 'Reject',
            onPressed: () => _showRejectDialog(auditId, questionId),
          ),
        ],
      ],
    );
  }

  Future<void> _handleTaskResponse(
    String auditId,
    String status, {
    String? reason,
    String? questionId,
  }) async {
    try {
      if (questionId == null) return;

      final action = status == 'approved' ? 'approve' : 'reject';

      await _apiService.respondToAuditQuestion(
        auditId: auditId,
        questionId: questionId,
        action: action,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task $status successfully')));
        _loadMyTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String auditId, String? questionId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            CustomTextInput(
              label: 'Reason',
              controller: reasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleTaskResponse(
                  auditId,
                  'rejected',
                  reason: reasonController.text,
                  questionId: questionId,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.list_alt_outlined,
            color: AppTheme.gray600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All Audits (${_filteredAudits.length}${_searchQuery.isNotEmpty ? ' of ${_audits.length}' : ''})',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                // fontWeight: FontWeight.w500,
                // color: AppTheme.gray900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gray600),
            onPressed: _fetchAudits,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.gray600),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
              'Search audits by number, company, location, template, or status...',
          filled: true,
          fillColor: AppTheme.inputBackground,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppTheme.border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppTheme.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppTheme.ring, width: 2),
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.gray600),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.gray600),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredAudits.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    if (_filteredAudits.isEmpty) {
      return _buildEmptyState();
    }

    return isMobile ? _buildMobileView() : _buildDesktopView();
  }

  Widget _buildNoSearchResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: CustomCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppTheme.gray500),
              const SizedBox(height: 24),
              const Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No audits match your search for "${_searchQuery}"',
                style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: CustomCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppTheme.gray500,
              ),
              SizedBox(height: 24),
              Text(
                'No Audits Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Click the + button to create your first audit',
                style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
          columns: const [
            DataColumn(
              label: Text(
                'Audit Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Template',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Company',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Questions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          rows: _filteredAudits.map((audit) => _buildDataRow(audit)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> audit) {
    final auditNumber = audit['auditNumber'] ?? 'N/A';
    final date = audit['date'] != null
        ? DateTime.parse(audit['date']).toString().split(' ')[0]
        : 'N/A';
    final template = audit['auditTemplate']?['name'] ?? 'N/A';
    final company = audit['companyName'] ?? 'N/A';
    final location = audit['location'] ?? 'N/A';
    final status = audit['auditStatus'] ?? 'open';
    final questions = audit['auditQuestions'] as List? ?? [];

    return DataRow(
      cells: [
        DataCell(Text(auditNumber)),
        DataCell(Text(date)),
        DataCell(Text(template)),
        DataCell(Text(company)),
        DataCell(Text(location)),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          InkWell(
            onTap: () => _showQuestionsDialog(audit),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${questions.length} Questions',
                style: const TextStyle(
                  color: AppTheme.blue600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        DataCell(_buildActionButtons(audit)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> audit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          onPressed: () => _showAuditDetails(audit),
          tooltip: 'View Details',
          color: AppTheme.blue600,
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _editAudit(audit),
          tooltip: 'Edit',
          color: AppTheme.green600,
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: () => _deleteAudit(audit),
          tooltip: 'Delete',
          color: AppTheme.red500,
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return RefreshIndicator(
      onRefresh: _fetchAudits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAudits.length,
        itemBuilder: (context, index) {
          final audit = _filteredAudits[index];
          return _buildMobileAuditCard(audit);
        },
      ),
    );
  }

  Widget _buildMobileAuditCard(Map<String, dynamic> audit) {
    final auditNumber = audit['auditNumber'] ?? 'N/A';
    final date = audit['date'] != null
        ? DateTime.parse(audit['date']).toString().split(' ')[0]
        : 'N/A';
    final template = audit['auditTemplate']?['name'] ?? 'N/A';
    final company = audit['companyName'] ?? 'N/A';
    final location = audit['location'] ?? 'N/A';
    final status = audit['auditStatus'] ?? 'open';
    final questions = audit['auditQuestions'] as List? ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.assignment, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auditNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // Description (Template Name)
            Text(
              template,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.gray700,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Meta Info Rows
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$company, $location',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.gray500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 16,
                        color: AppTheme.gray500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${questions.length} Questions',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Actions
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'View Details',
                        onPressed: () => _showAuditDetails(audit),
                        variant: ButtonVariant.default_,
                        size: ButtonSize.sm,
                        icon: const Icon(
                          Icons.visibility,
                          size: 16,
                          color: Colors.white,
                        ),
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Questions',
                        onPressed: () => _showQuestionsDialog(audit),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.list, size: 16),
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Edit',
                        onPressed: () => _editAudit(audit),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.edit, size: 16),
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Delete',
                        onPressed: () => _deleteAudit(audit),
                        variant: ButtonVariant.destructive,
                        size: ButtonSize.sm,
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: AppTheme.primaryForeground,
                        ),
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gray600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.gray700),
          ),
        ),
      ],
    );
  }

  void _showQuestionsDialog(Map<String, dynamic> audit) async {
    await showDialog(
      context: context,
      builder: (context) => _AuditQuestionsDialog(audit: audit),
    );
    _fetchAudits();
  }

  void _showAuditDetails(Map<String, dynamic> audit) async {
    await showDialog(
      context: context,
      builder: (context) => _AuditDetailsDialog(audit: audit),
    );
    _fetchAudits();
  }

  void _editAudit(Map<String, dynamic> audit) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateAuditMainDialog(
            onAuditCreated: _fetchAudits,
            isEditing: true,
            auditData: audit,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => CreateAuditMainDialog(
          onAuditCreated: _fetchAudits,
          isEditing: true,
          auditData: audit,
        ),
      );
    }
  }

  void _deleteAudit(Map<String, dynamic> audit) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.red50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 32,
                  color: AppTheme.red600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delete Audit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete this audit?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.gray600),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeleteSummaryRow(
                      'Audit No',
                      audit['auditNumber'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteSummaryRow(
                      'Company',
                      audit['companyName'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteSummaryRow(
                      'Location',
                      audit['location'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: AppTheme.gray700,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _performDeleteAudit(audit);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.red600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Delete'),
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

  Widget _buildDeleteSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.gray900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performDeleteAudit(Map<String, dynamic> audit) async {
    try {
      final auditId = audit['_id'] ?? audit['id'];
      await _apiService.deleteAuditMain(auditId: auditId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit deleted successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
        // Refresh the audits list
        _fetchAudits();
      }
    } catch (e) {
      developer.log('Error deleting audit: $e', name: 'AllAuditsDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting audit: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }
}

// Audit Details Dialog
class _AuditDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> audit;

  const _AuditDetailsDialog({super.key, required this.audit});

  @override
  State<_AuditDetailsDialog> createState() => _AuditDetailsDialogState();
}

class _AuditDetailsDialogState extends State<_AuditDetailsDialog> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> audit;

  @override
  void initState() {
    super.initState();
    audit = widget.audit;
  }

  Future<void> _refreshAudit() async {
    try {
      final auditId = audit['_id'] ?? audit['id'];
      final response = await _apiService.getAuditMainById(id: auditId);
      if (mounted) {
        setState(() {
          if (response.containsKey('audit')) {
            audit = response['audit'];
          } else {
            audit = response;
          }
        });
      }
    } catch (e) {
      developer.log('Error refreshing audit: $e', name: 'AuditDetailsDialog');
    }
  }

  Future<void> _editMom(BuildContext context, Map<String, dynamic> mom) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MomFormDialog(audit: audit, mom: mom),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => MomFormDialog(audit: audit, mom: mom),
      );
    }
    _refreshAudit();
  }

  Future<void> _deleteMom(String? momId) async {
    if (momId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete MOM'),
        content: const Text('Are you sure you want to delete this MOM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final auditId = audit['_id'] ?? audit['id'];
      await _apiService.deleteMom(auditId: auditId, momId: momId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MOM deleted successfully')),
        );
        _refreshAudit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting MOM: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(context, isMobile),
            Expanded(child: _buildContent(context, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.blue100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: AppTheme.blue600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audit Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  audit['auditNumber'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          // Refresh Button

          // MOM Button
          Tooltip(
            message: 'MOM',
            child: IconButton(
              icon: const Icon(Icons.description),
              onPressed: () async {
                if (isMobile) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MomFormDialog(audit: audit),
                    ),
                  );
                } else {
                  await showDialog(
                    context: context,
                    builder: (context) => MomFormDialog(audit: audit),
                  );
                }
                _refreshAudit();
              },
              color: AppTheme.primary,
            ),
          ),
          // Audit Transaction Button
          Tooltip(
            message: 'Audit Transaction',
            child: IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _showAuditTransactionDialog(context),
              color: AppTheme.green600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.gray600,
          ),
        ],
      ),
    );
  }

  void _showAuditTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AuditTransactionDialog(
        audit: audit,
        onTransactionUpdated: () {
          _refreshAudit();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(isMobile),
          const SizedBox(height: 24),
          _buildTemplateInfoSection(isMobile),
          const SizedBox(height: 24),
          _buildTeamInfoSection(isMobile),
          const SizedBox(height: 24),
          _buildQuestionsOverviewSection(isMobile),
          const SizedBox(height: 24),
          _buildMomInfoSection(context, isMobile),
          const SizedBox(height: 24),
          _buildFilesSection(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isMobile) {
    return _buildSection('Basic Information', Icons.info_outline, [
      _buildInfoRowDetail('Audit Number', audit['auditNumber']),
      _buildInfoRowDetail(
        'Date',
        audit['date'] != null
            ? DateTime.parse(audit['date']).toString().split(' ')[0]
            : 'N/A',
      ),
      _buildInfoRowDetail('Company', audit['companyName']),
      _buildInfoRowDetail('Location', audit['location']),
      _buildInfoRowDetail('Status', audit['auditStatus'], isStatus: true),
      _buildInfoRowDetail('Created By', audit['createdBy']?['fullName']),
      _buildInfoRowDetail(
        'Created At',
        audit['createdAt'] != null
            ? DateTime.parse(audit['createdAt']).toString().split(' ')[0]
            : 'N/A',
      ),
    ], isMobile);
  }

  Widget _buildTemplateInfoSection(bool isMobile) {
    final template = audit['auditTemplate'];
    if (template == null) {
      return _buildSection('Template Information', Icons.description_outlined, [
        const Text(
          'No template information available',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ], isMobile);
    }

    return _buildSection('Template Information', Icons.description_outlined, [
      _buildInfoRowDetail('Template Name', template['name']),
      _buildInfoRowDetail('Segment', template['auditSegment']?['name']),
      _buildInfoRowDetail('Type', template['auditType']?['name']),
      _buildInfoRowDetail('Template Status', template['status']),
    ], isMobile);
  }

  Widget _buildTeamInfoSection(bool isMobile) {
    final staff = audit['texspinStaffMember'] as List? ?? [];
    final visitors = audit['visitCompanyMemberName'] as List? ?? [];

    return _buildSection('Team Information', Icons.people_outline, [
      if (staff.isNotEmpty) ...[
        const Text(
          'Texspin Staff Members:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        ...staff
            .map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.blue100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          (member['firstName']?[0] ?? '') +
                              (member['lastName']?[0] ?? ''),
                          style: const TextStyle(
                            fontSize: 12,
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
                            '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gray900,
                            ),
                          ),
                          Text(
                            member['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        const SizedBox(height: 16),
      ] else ...[
        const Text(
          'No Texspin staff members assigned',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
      ],

      if (visitors.isNotEmpty) ...[
        const Text(
          'Visitor Company Members:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        ...visitors
            .map(
              (visitor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.green100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.green600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        visitor['name'] ?? 'Unknown Visitor',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ] else ...[
        const Text(
          'No visitor company members',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ], isMobile);
  }

  Widget _buildQuestionsOverviewSection(bool isMobile) {
    final questions = audit['auditQuestions'] as List? ?? [];

    if (questions.isEmpty) {
      return _buildSection('Questions Overview', Icons.quiz_outlined, [
        const Text(
          'No questions available',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ], isMobile);
    }

    // Calculate status counts
    final statusCounts = <String, int>{};
    for (final question in questions) {
      final status = question['status'] ?? 'Pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final totalQuestions = questions.length;
    final completedQuestions = statusCounts['Approved'] ?? 0;
    final progress = totalQuestions > 0
        ? completedQuestions / totalQuestions
        : 0.0;

    return _buildSection('Questions Overview', Icons.quiz_outlined, [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Questions: $totalQuestions',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          Text(
            'Completed: $completedQuestions',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.green600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.gray200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.green500),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: statusCounts.entries.map((entry) {
          return _buildStatusChip(entry.key, entry.value);
        }).toList(),
      ),
    ], isMobile);
  }

  Widget _buildFilesSection(BuildContext context, bool isMobile) {
    String? getFilePath(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isNotEmpty ? value : null;
      // Handle case where file might be an object (e.g. from population)
      if (value is Map) {
        if (value['path'] != null) return value['path'].toString();
        if (value['url'] != null) return value['url'].toString();
        if (value['filename'] != null) return value['filename'].toString();
        return null;
      }
      return value.toString();
    }

    final files = <String, dynamic>{
      'Audit Methodology': audit['auditMethodology'],
      'Audit Observation': audit['auditObservation'],
      'Action Plan': audit['actionPlan'],
      'Action Evidence': audit['actionEvidence'],
      'Previous Document': audit['previousDoc'],
      'Other Document': audit['otherDoc'],
    };

    final otherDocs = audit['otherDocs'] as List? ?? [];

    return _buildSection('Files & Documents', Icons.folder_outlined, [
      ...files.entries.map((entry) {
        final filePath = getFilePath(entry.value);
        final hasFile = filePath != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: hasFile ? AppTheme.green600 : AppTheme.gray500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasFile ? AppTheme.gray900 : AppTheme.gray600,
                  ),
                ),
              ),
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.download, size: 16),
                  onPressed: () {
                    String url = filePath;
                    if (!url.startsWith('http')) {
                      if (url.startsWith('/texspin/api')) {
                        url = '${ApiService.baseUrl}$url';
                      } else if (url.startsWith('uploads/') ||
                          url.startsWith('/uploads/')) {
                        if (url.startsWith('/')) url = url.substring(1);
                        url = '${ApiService.baseUrl}/texspin/api/$url';
                      } else {
                        url = '${ApiService.baseUrl}/texspin/api/uploads/$url';
                      }
                    }
                    _launchUrl(context, url);
                  },
                  color: AppTheme.blue600,
                  tooltip: 'Download',
                ),
            ],
          ),
        );
      }).toList(),

      if (otherDocs.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text(
          'Other Documents:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        ...otherDocs.asMap().entries.map((entry) {
          final index = entry.key;
          final filePath = getFilePath(entry.value);
          final hasFile = filePath != null;

          if (!hasFile) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 16,
                  color: AppTheme.gray600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 16),
                  onPressed: () {
                    String url = filePath;
                    if (!url.startsWith('http')) {
                      if (url.startsWith('/texspin/api')) {
                        url = '${ApiService.baseUrl}$url';
                      } else if (url.startsWith('uploads/') ||
                          url.startsWith('/uploads/')) {
                        if (url.startsWith('/')) url = url.substring(1);
                        url = '${ApiService.baseUrl}/texspin/api/$url';
                      } else {
                        url = '${ApiService.baseUrl}/texspin/api/uploads/$url';
                      }
                    }
                    _launchUrl(context, url);
                  },
                  color: AppTheme.blue600,
                  tooltip: 'Download',
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ], isMobile);
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.gray600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRowDetail(
    String label,
    dynamic value, {
    bool isStatus = false,
  }) {
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
            child: isStatus
                ? _buildStatusBadgeDetail(value?.toString() ?? 'N/A')
                : Text(
                    value?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeDetail(String status) {
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
      case 'active':
        bgColor = AppTheme.blue50;
        textColor = AppTheme.blue600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, int count) {
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
        '$status: $count',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMomInfoSection(BuildContext context, bool isMobile) {
    final moms = audit['mom'] as List? ?? [];

    if (moms.isEmpty) {
      return _buildSection('MOM Details', Icons.description_outlined, [
        const Text(
          'No MOM details available',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ], isMobile);
    }

    return _buildSection('MOM Details', Icons.description_outlined, [
      ...moms.asMap().entries.map((entry) {
        final index = entry.key;
        final mom = entry.value;
        return _buildMomCard(context, mom, index);
      }),
    ], isMobile);
  }

  Widget _buildMomCard(
    BuildContext context,
    Map<String, dynamic> mom,
    int index,
  ) {
    final title = mom['momTitle'] ?? 'No Title';
    final date = mom['date'] != null
        ? DateTime.parse(mom['date']).toString().split(' ')[0]
        : 'N/A';
    final time = mom['time'] ?? 'N/A';
    final venue = mom['venue'] ?? 'N/A';
    final type = mom['selectType'] ?? 'N/A';
    final observations = mom['discussionAndObservation'] as List? ?? [];
    final docs = mom['otherDocuments'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.gray50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.blue600,
                    ),
                    onPressed: () => _editMom(context, mom),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.red500,
                    ),
                    onPressed: () => _deleteMom(mom['_id'] ?? mom['id']),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMiniInfo(Icons.calendar_today, date),
              _buildMiniInfo(Icons.access_time, time),
              _buildMiniInfo(Icons.location_on, venue),
              _buildMiniInfo(Icons.category, type),
            ],
          ),
          if (observations.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Observations:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...observations.map(
              (obs) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        obs['observationName'] ?? obs['observation'] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (docs.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Documents:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppTheme.blue600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doc.toString().split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.blue600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      onPressed: () {
                        String url = doc.toString();
                        if (!url.startsWith('http')) {
                          if (url.startsWith('/texspin/api')) {
                            url = '${ApiService.baseUrl}$url';
                          } else if (doc.toString().startsWith('uploads/')) {
                            url = '${ApiService.baseUrl}/texspin/api/$doc';
                          } else {
                            url =
                                '${ApiService.baseUrl}/texspin/api/uploads/mom/$doc';
                          }
                        }
                        _launchUrl(context, url);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.gray600),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
        ),
      ],
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch url: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching url: $e')));
      }
    }
  }
}

// Audit Questions Dialog with Action Buttons
class _AuditQuestionsDialog extends StatefulWidget {
  final Map<String, dynamic> audit;

  const _AuditQuestionsDialog({required this.audit});

  @override
  State<_AuditQuestionsDialog> createState() => _AuditQuestionsDialogState();
}

class _AuditQuestionsDialogState extends State<_AuditQuestionsDialog> {
  final ApiService _apiService = ApiService();
  bool _isClosingAudit = false;
  late Map<String, dynamic> _audit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audit = widget.audit;
  }

  Future<void> _refreshAudit() async {
    // Don't show loading spinner for refresh to avoid flicker
    try {
      final auditId = _audit['_id'] ?? _audit['id'];
      final response = await _apiService.getAuditMainById(id: auditId);
      if (mounted) {
        setState(() {
          if (response.containsKey('audit')) {
            _audit = response['audit'];
          } else {
            _audit = response;
          }
        });
      }
    } catch (e) {
      developer.log('Error refreshing audit: $e', name: 'AuditQuestionsDialog');
    }
  }

  // Check if all questions are approved and audit is not already closed
  bool _shouldShowCloseButton() {
    final questions = _audit['auditQuestions'] as List? ?? [];
    final auditStatus =
        _audit['auditStatus']?.toString().toLowerCase() ?? 'open';

    // Don't show if audit is already closed
    if (auditStatus == 'close' || auditStatus == 'closed') {
      return false;
    }

    // Don't show if no questions
    if (questions.isEmpty) return false;

    // Only show if all questions are approved
    return questions.every(
      (question) => question['status']?.toString().toLowerCase() == 'approved',
    );
  }

  // Close audit method
  Future<void> _closeAudit() async {
    setState(() => _isClosingAudit = true);

    try {
      final auditId = _audit['_id'] ?? _audit['id'];
      await _apiService.closeAuditMain(id: auditId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit closed successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
      }
    } catch (e) {
      developer.log('Error closing audit: $e', name: 'AuditQuestionsDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing audit: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClosingAudit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _audit['auditQuestions'] as List? ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final shouldShowCloseButton = _shouldShowCloseButton();

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isMobile),
                Expanded(child: _buildQuestionsList(questions, isMobile)),
              ],
            ),
            // Floating Action Button - only show if all questions are approved and audit is not closed
            if (shouldShowCloseButton)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: _isClosingAudit ? null : _closeAudit,
                  backgroundColor: AppTheme.green600,
                  foregroundColor: Colors.white,
                  icon: _isClosingAudit
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isClosingAudit ? 'Closing...' : 'Close Audit'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz, color: AppTheme.gray600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Audit Questions',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List questions, bool isMobile) {
    if (questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    return isMobile
        ? _buildMobileQuestionsList(questions)
        : _buildDesktopQuestionsTable(questions);
  }

  Widget _buildDesktopQuestionsTable(List questions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
          columns: const [
            DataColumn(
              label: Text(
                'Question',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Assigned To',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Deadline',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          rows: questions.map((q) => _buildQuestionRow(q)).toList(),
        ),
      ),
    );
  }

  DataRow _buildQuestionRow(Map<String, dynamic> question) {
    final questionText = question['question'] ?? 'N/A';
    final status = question['status'] ?? 'Pending';
    final assignedToId = question['assignedTo'];
    final deadline = question['deadline'] != null
        ? DateTime.parse(question['deadline']).toString().split(' ')[0]
        : 'N/A';

    return DataRow(
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(questionText),
          ),
        ),
        DataCell(_buildQuestionStatusBadgeWithData(status, question)),
        DataCell(Text(_getStaffName(assignedToId))),
        DataCell(Text(deadline)),
        DataCell(_buildQuestionActionButtons(question, status)),
      ],
    );
  }

  String _getStaffName(String? staffId) {
    if (staffId == null || staffId.isEmpty) return 'Not Assigned';

    final staffMembers = (_audit['texspinStaffMember'] as List?) ?? [];

    // Look for member with matching ID
    final member = staffMembers.firstWhere(
      (m) => (m['_id'] ?? m['id']) == staffId,
      orElse: () => null,
    );

    if (member != null) {
      return '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'.trim();
    }

    return 'Assigned'; // Fallback if name not found but ID exists
  }

  Widget _buildMobileQuestionsList(List questions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildMobileQuestionCard(question);
      },
    );
  }

  Widget _buildMobileQuestionCard(Map<String, dynamic> question) {
    final questionText = question['question'] ?? 'N/A';
    final status = question['status'] ?? 'Pending';
    final deadline = question['deadline'] != null
        ? DateTime.parse(question['deadline']).toString().split(' ')[0]
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildQuestionStatusBadgeWithData(status, question),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Deadline: $deadline',
              style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildMobileActionButtons(question, status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStatusBadgeWithData(
    String status,
    Map<String, dynamic> question,
  ) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
        break;
      case 'assigned':
        bgColor = AppTheme.blue50;
        textColor = AppTheme.blue600;
        break;
      case 'accepted':
        bgColor = AppTheme.purple100;
        textColor = AppTheme.purple600;
        break;
      case 'rejected':
        bgColor = AppTheme.red50;
        textColor = AppTheme.red600;
        break;
      case 'submitted':
        bgColor = AppTheme.orange100;
        textColor = AppTheme.orange600;
        break;
      case 'approved':
      case 'completed':
        bgColor = AppTheme.green100;
        textColor = AppTheme.green600;
        break;
      case 'revision':
        bgColor = AppTheme.yellow100;
        textColor = AppTheme.yellow600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    Widget statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Add tooltip for rejected and revision statuses
    if (status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'revision') {
      return Tooltip(
        message: _getRejectionReasonFromQuestion(status, question),
        child: statusBadge,
      );
    }

    return statusBadge;
  }

  Widget _buildQuestionStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
        break;
      case 'assigned':
        bgColor = AppTheme.blue50;
        textColor = AppTheme.blue600;
        break;
      case 'accepted':
        bgColor = AppTheme.purple100;
        textColor = AppTheme.purple600;
        break;
      case 'rejected':
        bgColor = AppTheme.red50;
        textColor = AppTheme.red600;
        break;
      case 'submitted':
        bgColor = AppTheme.orange100;
        textColor = AppTheme.orange600;
        break;
      case 'approved':
      case 'completed':
        bgColor = AppTheme.green100;
        textColor = AppTheme.green600;
        break;
      case 'revision':
        bgColor = AppTheme.yellow100;
        textColor = AppTheme.yellow600;
        break;
      default:
        bgColor = AppTheme.gray100;
        textColor = AppTheme.gray600;
    }

    Widget statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Add tooltip for rejected and revision statuses
    if (status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'revision') {
      return Tooltip(message: _getRejectionReason(status), child: statusBadge);
    }

    return statusBadge;
  }

  Widget _buildQuestionActionButtons(
    Map<String, dynamic> question,
    String status,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _getActionButtonsForStatus(question, status),
    );
  }

  List<Widget> _getActionButtonsForStatus(
    Map<String, dynamic> question,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return [
          _buildActionButton(
            Icons.person_add,
            'Assign',
            AppTheme.blue600,
            () => _assignStaff(question),
          ),
        ];

      case 'accepted':
        return [
          _buildActionButton(
            Icons.send,
            'Send Reminder',
            AppTheme.blue600,
            () => _sendReminder(question),
          ),
        ];

      case 'rejected':
        return [
          _buildActionButton(
            Icons.swap_horiz,
            'Reassign Staff',
            AppTheme.blue600,
            () => _reassignStaff(question),
          ),
        ];

      case 'submitted':
        return [
          _buildActionButton(
            Icons.download,
            'Download',
            AppTheme.green600,
            () => _downloadFile(question),
          ),
          _buildActionButton(
            Icons.check,
            'Approve',
            AppTheme.green600,
            () => _approveSubmission(question),
          ),
          _buildActionButton(
            Icons.close,
            'Reject',
            AppTheme.red500,
            () => _rejectSubmission(question),
          ),
        ];

      case 'approved':
      case 'completed':
        return [
          _buildActionButton(
            Icons.download,
            'Download',
            AppTheme.green600,
            () => _downloadFile(question),
          ),
        ];

      case 'revision':
        return []; // No action buttons for revision status

      default:
        return [];
    }
  }

  List<Widget> _buildMobileActionButtons(
    Map<String, dynamic> question,
    String status,
  ) {
    final buttons = _getActionButtonsForStatus(question, status);
    return buttons.map((btn) {
      if (btn is IconButton) {
        return ElevatedButton.icon(
          onPressed: btn.onPressed,
          icon: btn.icon,
          label: Text(btn.tooltip ?? ''),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      }
      return btn;
    }).toList();
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
    );
  }

  // Action Methods
  void _assignStaff(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AssignQuestionDialog(
        audit: _audit,
        question: question,
        isReassign: false,
        onAssignmentChanged: () {
          // Refresh the questions list
          _refreshAudit();
        },
      ),
    );
  }

  void _reassignStaff(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AssignQuestionDialog(
        audit: _audit,
        question: question,
        isReassign: true,
        onAssignmentChanged: () {
          // Refresh the questions list
          _refreshAudit();
        },
      ),
    );
  }

  void _sendReminder(Map<String, dynamic> question) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a reminder note for the staff member:',
              style: TextStyle(fontSize: 14, color: AppTheme.gray600),
            ),
            const SizedBox(height: 12),
            CustomTextInput(
              controller: noteController,
              label: 'Reminder Note',
              hint: 'e.g. Please complete this audit question by tomorrow EOD.',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.gray600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reminder note'),
                    backgroundColor: AppTheme.red500,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              try {
                final auditId = _audit['_id'] ?? _audit['id'];
                // Check for question ID using multiple possible keys
                final questionId =
                    question['id'] ?? question['_id'] ?? question['questionId'];

                if (auditId == null || questionId == null) {
                  throw Exception('Missing audit or question ID');
                }

                final response = await _apiService.sendAuditQuestionReminder(
                  auditId: auditId,
                  questionId: questionId,
                  reminderNote: noteController.text.trim(),
                );

                if (mounted) {
                  final message =
                      response['message'] as String? ??
                      'Reminder sent successfully';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: AppTheme.green500,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending reminder: $e'),
                      backgroundColor: AppTheme.red500,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blue600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> question) async {
    String? fileUrl;
    String? fileName;

    // Try to extract file URL from various possible locations
    final answerFiles = question['answerFiles'];
    if (answerFiles is List && answerFiles.isNotEmpty) {
      final firstFile = answerFiles.first;
      if (firstFile is String) {
        fileUrl = firstFile;
      } else if (firstFile is Map) {
        fileUrl = firstFile['url'] ?? firstFile['fileUrl'] ?? firstFile['path'];
        fileName = firstFile['name'] ?? firstFile['fileName'];
      }
    }

    // Fallback to direct properties
    if (fileUrl == null || fileUrl.isEmpty) {
      fileUrl =
          question['fileUrl'] ??
          question['downloadUrl'] ??
          question['attachmentUrl'] ??
          question['uploadedFile'];
    }

    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file available for download'),
          backgroundColor: AppTheme.yellow500,
        ),
      );
      return;
    }

    fileName ??= fileUrl.split('/').last;
    if (fileName.isEmpty) fileName = 'audit_task_file';

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Downloading $fileName...')),
            ],
          ),
          backgroundColor: AppTheme.blue600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Construct full URL
      final String fullUrl = fileUrl.startsWith('http')
          ? fileUrl
          : ApiService.baseUrl + fileUrl;
      final Uri url = Uri.parse(fullUrl);

      developer.log('Downloading file from: $fullUrl');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$fileName download started')),
                ],
              ),
              backgroundColor: AppTheme.green500,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error downloading $fileName: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _approveSubmission(Map<String, dynamic> question) async {
    await showDialog(
      context: context,
      builder: (context) => ReviewQuestionDialog(
        audit: _audit,
        question: question,
        action: 'approve',
        onReviewCompleted: () {},
      ),
    );
    await _refreshAudit();
  }

  Future<void> _rejectSubmission(Map<String, dynamic> question) async {
    await showDialog(
      context: context,
      builder: (context) => ReviewQuestionDialog(
        audit: _audit,
        question: question,
        action: 'reject',
        onReviewCompleted: () {},
      ),
    );
    await _refreshAudit();
  }

  // Helper method to get rejection reason from API data
  String _getRejectionReason(String status) {
    // This should be replaced with actual API data from the question object
    // For now, returning a placeholder
    if (status.toLowerCase() == 'rejected') {
      return 'Rejection reason available in details';
    } else if (status.toLowerCase() == 'revision') {
      return 'Revision reason available in details';
    }
    return '';
  }

  // Helper method to get rejection reason from question data
  String _getRejectionReasonFromQuestion(
    String status,
    Map<String, dynamic> question,
  ) {
    // Extract rejection reason from question data
    if (status.toLowerCase() == 'rejected') {
      return question['rejectionReason'] ?? 'No rejection reason provided';
    } else if (status.toLowerCase() == 'revision') {
      return question['reviewRejectionReason'] ?? 'No revision reason provided';
    }
    return '';
  }
}
