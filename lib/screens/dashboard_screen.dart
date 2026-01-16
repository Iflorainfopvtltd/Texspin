import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../models/models.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_progress.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_theme.dart';
import '../bloc/entity/entity_bloc.dart';
import '../services/api_service.dart';
import '../utils/project_converter.dart';
import 'search_dialog.dart';
import 'entity_detail_dialog.dart';
import 'inquiry_screen.dart';
import 'audit_dialog.dart';
import 'audit_type_management_screen.dart';
import 'audit_segment_management_screen.dart';
import 'audit_questions_management_screen.dart';
import 'all_audits_screen.dart';
import 'create_audit_template_screen.dart';
import '../widgets/audit_type_management_dialog.dart';
import '../widgets/audit_segment_management_dialog.dart';
import '../widgets/audit_questions_management_dialog.dart';
import '../widgets/all_audits_dialog.dart';
import '../widgets/create_audit_template_dialog.dart';
import '../widgets/create_audit_main_dialog.dart';
import '../widgets/staff_performance_entry_dialog.dart';
import 'audit_question_category_management_screen.dart';
import '../widgets/audit_question_category_management_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final List<Project> projects;
  final VoidCallback onCreateProject;
  final VoidCallback onInquiry;
  final Function(Project project) onViewProject;
  final VoidCallback? onLogout;
  final String? userName;
  final VoidCallback? onRefresh;

  const DashboardScreen({
    super.key,
    required this.projects,
    required this.onCreateProject,
    required this.onInquiry,
    required this.onViewProject,
    this.onLogout,
    this.userName,
    this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  bool _isTableView = true;
  String _filterText = '';
  String?
  _statusFilter; // null = all, 'ongoing' = active, 'completed' = completed

  @override
  void initState() {
    super.initState();
    _projects = widget.projects;
    _fetchProjects();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      _fetchProjects();
    }
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getProjects();
      final projects = ProjectConverter.fromApiResponse(response);
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching projects: $e', name: 'DashboardScreen');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Keep existing projects if available
        if (_projects.isEmpty) {
          _projects = widget.projects;
        }
      });
    }
  }

  List<Project> get _filteredProjects {
    var filtered = _projects;

    // Apply status filter
    if (_statusFilter == 'ongoing') {
      filtered = filtered
          .where((p) => p.progress > 0 && p.progress < 100)
          .toList();
    } else if (_statusFilter == 'completed') {
      filtered = filtered.where((p) => p.progress == 100).toList();
    }

    // Apply text filter
    if (_filterText.isNotEmpty) {
      filtered = filtered
          .where(
            (project) =>
                project.customerName.toLowerCase().contains(
                  _filterText.toLowerCase(),
                ) ||
                project.partName.toLowerCase().contains(
                  _filterText.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _handleSearch(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => SearchDialog(
        onEntitySelected: (entityType) async {
          await showDialog(
            context: context,
            builder: (detailContext) => BlocProvider.value(
              value: context.read<EntityBloc>(),
              child: EntityDetailDialog(entityType: entityType),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAudit(BuildContext context) async {
    final auditOption = await showDialog<AuditOption>(
      context: context,
      builder: (dialogContext) => AuditDialog(
        onAuditSelected: (auditOption) {
          Navigator.of(dialogContext).pop(auditOption);
        },
      ),
    );

    if (auditOption != null) {
      await _showAuditManagement(context, auditOption);
    }
  }

  Future<void> _showAuditManagement(
    BuildContext context,
    AuditOption auditOption,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: Navigate to full screen
      Widget screen;

      switch (auditOption) {
        case AuditOption.createTemplate:
          screen = const CreateAuditTemplateScreen();
          break;
        case AuditOption.auditSegment:
          screen = const AuditSegmentManagementScreen();
          break;
        case AuditOption.auditType:
          screen = const AuditTypeManagementScreen();
          break;
        case AuditOption.auditQuestionCategory:
          screen = const AuditQuestionCategoryManagementScreen();
          break;
        case AuditOption.auditQuestions:
          screen = const AuditQuestionsManagementScreen();
          break;
        case AuditOption.getAllAudits:
          screen = const AllAuditsScreen();
          break;
        case AuditOption.createAudit:
          // For mobile, we'll show the dialog in a full screen
          // For mobile, we'll show the dialog in a full screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateAuditMainDialog(
                onAuditCreated: () {
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                },
                isFullScreen: true,
              ),
            ),
          );
          return; // Don't navigate to a screen
      }

      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    } else {
      // Web/Desktop: Show dialog
      Widget dialog;

      switch (auditOption) {
        case AuditOption.createTemplate:
          dialog = const CreateAuditTemplateDialog();
          break;
        case AuditOption.auditSegment:
          dialog = const AuditSegmentManagementDialog();
          break;
        case AuditOption.auditType:
          dialog = const AuditTypeManagementDialog();
          break;
        case AuditOption.auditQuestionCategory:
          dialog = const AuditQuestionCategoryManagementDialog();
          break;
        case AuditOption.auditQuestions:
          dialog = const AuditQuestionsManagementDialog();
          break;
        case AuditOption.getAllAudits:
          dialog = const AllAuditsDialog();
          break;
        case AuditOption.createAudit:
          dialog = CreateAuditMainDialog(
            onAuditCreated: () {
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
          );
          break;
      }

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => dialog,
      );
    }
  }

  Color _getProgressColor(int progress) {
    if (progress == 0) return AppTheme.red500;
    if (progress < 100) return AppTheme.yellow500;
    return AppTheme.green500;
  }

  String _getProjectId(Project project) {
    // Try to extract from planNumber or generate from partNumber
    if (project.planNumber.isNotEmpty) {
      return project.planNumber;
    }
    // Generate ID from part number and year
    final year = DateTime.now().year;
    final partPrefix = project.partNumber.length >= 2
        ? project.partNumber.substring(0, 2).toUpperCase()
        : 'PR';
    return '$partPrefix-${project.partNumber.substring(project.partNumber.length - 3).toUpperCase()}-$year-001';
  }

  String _getStatusText(Project project) {
    if (project.progress == 0) return 'New';
    if (project.progress < 100) return 'Ongoing';
    return 'Completed';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final filteredProjects = _filteredProjects;

    return DashboardLayout(
      title: 'Admin Dashboard',
      subtitle: 'Administrator',
      userName: widget.userName ?? 'Admin',
      navigationItems: [
        NavigationItem(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),
        NavigationItem(
          icon: Icons.search,
          label: 'Search',
          onTap: () => _handleSearch(context),
        ),
        NavigationItem(
          icon: Icons.add_circle_outline,
          label: 'Create Project',
          onTap: widget.onCreateProject,
        ),
        NavigationItem(
          icon: Icons.assignment_outlined,
          label: 'Audit',
          onTap: () => _handleAudit(context),
        ),
        NavigationItem(
          icon: Icons.insights,
          label: 'Staff Performance',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const StaffPerformanceEntryDialog(),
            );
          },
        ),
        NavigationItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: widget.onInquiry,
        ),
      ],
      onLogout: widget.onLogout,
      onNotification: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                InquiryScreen(onCancel: () => Navigator.of(context).pop()),
          ),
        );
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview
            isMobile
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _statusFilter = null),
                        child: CustomCard(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            padding: _statusFilter == null
                                ? const EdgeInsets.all(2)
                                : null,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blue100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: AppTheme.blue600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Projects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.gray600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_projects.length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _statusFilter = 'ongoing'),
                        child: CustomCard(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            // decoration: _statusFilter == 'ongoing'
                            //     ? BoxDecoration(
                            //         border: Border.all(
                            //           color: AppTheme.green600,
                            //           width: 2,
                            //         ),
                            //         borderRadius: BorderRadius.circular(8),
                            //       )
                            //     : null,
                            padding: _statusFilter == 'ongoing'
                                ? const EdgeInsets.all(2)
                                : null,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.green100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.green600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Active Projects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.gray600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_projects.where((p) => p.progress > 0 && p.progress < 100).length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _statusFilter = 'completed'),
                        child: CustomCard(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            // decoration: _statusFilter == 'completed'
                            //     ? BoxDecoration(
                            //         border: Border.all(
                            //           color: AppTheme.purple600,
                            //           width: 2,
                            //         ),
                            //         borderRadius: BorderRadius.circular(8),
                            //       )
                            //     : null,
                            padding: _statusFilter == 'completed'
                                ? const EdgeInsets.all(2)
                                : null,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.purple100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.people,
                                    color: AppTheme.purple600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Completed Projects',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.gray600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_projects.where((p) => p.progress == 100).length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = null),
                          child: CustomCard(
                            padding: EdgeInsets.all(isTablet ? 20 : 24),
                            child: Container(
                              // decoration: _statusFilter == null
                              //     ? BoxDecoration(
                              //         border: Border.all(
                              //           color: AppTheme.blue600,
                              //           width: 2,
                              //         ),
                              //         borderRadius: BorderRadius.circular(
                              //           8,
                              //         ),
                              //       )
                              //     : null,
                              padding: _statusFilter == null
                                  ? const EdgeInsets.all(2)
                                  : null,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.blue100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: AppTheme.blue600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Projects',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.gray600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_projects.length}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.gray900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _statusFilter = 'ongoing'),
                          child: CustomCard(
                            padding: EdgeInsets.all(isTablet ? 20 : 24),
                            child: Container(
                              // decoration: _statusFilter == 'ongoing'
                              //     ? BoxDecoration(
                              //         border: Border.all(
                              //           color: AppTheme.green600,
                              //           width: 2,
                              //         ),
                              //         borderRadius: BorderRadius.circular(
                              //           8,
                              //         ),
                              //       )
                              //     : null,
                              padding: _statusFilter == 'ongoing'
                                  ? const EdgeInsets.all(2)
                                  : null,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.green100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: AppTheme.green600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Active Projects',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.gray600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_projects.where((p) => p.progress > 0 && p.progress < 100).length}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.gray900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 12 : 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _statusFilter = 'completed'),
                          child: CustomCard(
                            padding: EdgeInsets.all(isTablet ? 20 : 24),
                            child: Container(
                              // decoration: _statusFilter == 'completed'
                              //     ? BoxDecoration(
                              //         border: Border.all(
                              //           color: AppTheme.purple600,
                              //           width: 2,
                              //         ),
                              //         borderRadius: BorderRadius.circular(
                              //           8,
                              //         ),
                              //       )
                              //     : null,
                              padding: _statusFilter == 'completed'
                                  ? const EdgeInsets.all(2)
                                  : null,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.purple100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      color: AppTheme.purple600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Completed Projects',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.gray600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_projects.where((p) => p.progress == 100).length}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.gray900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: isMobile ? 24 : 32),

            // Filter and View Toggle
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Projects',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) =>
                            setState(() => _filterText = value),
                        decoration: InputDecoration(
                          hintText: 'Search by customer or project name...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.gray500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          filled: true,
                          fillColor: AppTheme.gray50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            text: 'List',
                            onPressed: () =>
                                setState(() => _isTableView = false),
                            variant: !_isTableView
                                ? ButtonVariant.default_
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            icon: Icon(
                              Icons.view_list,
                              size: 16,
                              color: !_isTableView
                                  ? AppTheme.primaryForeground
                                  : AppTheme.foreground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomButton(
                            text: 'Table',
                            onPressed: () =>
                                setState(() => _isTableView = true),
                            variant: _isTableView
                                ? ButtonVariant.default_
                                : ButtonVariant.outline,
                            size: ButtonSize.sm,
                            icon: Icon(
                              Icons.table_chart,
                              size: 16,
                              color: _isTableView
                                  ? AppTheme.primaryForeground
                                  : AppTheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Projects',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (value) =>
                                  setState(() => _filterText = value),
                              decoration: InputDecoration(
                                hintText:
                                    'Search by customer or project name...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppTheme.gray500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppTheme.gray300,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.gray50,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          CustomButton(
                            text: 'Table View',
                            onPressed: () =>
                                setState(() => _isTableView = true),
                            variant: _isTableView
                                ? ButtonVariant.default_
                                : ButtonVariant.outline,
                            size: ButtonSize.lg,
                            icon: Icon(
                              Icons.table_chart,
                              size: 16,
                              color: _isTableView
                                  ? AppTheme.primaryForeground
                                  : AppTheme.foreground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomButton(
                            text: 'List View',
                            onPressed: () =>
                                setState(() => _isTableView = false),
                            variant: !_isTableView
                                ? ButtonVariant.default_
                                : ButtonVariant.outline,
                            size: ButtonSize.lg,
                            icon: Icon(
                              Icons.view_list,
                              size: 16,
                              color: !_isTableView
                                  ? AppTheme.primaryForeground
                                  : AppTheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            SizedBox(height: isMobile ? 24 : 32),

            // Projects List or Table
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _projects.isEmpty)
              CustomCard(
                padding: EdgeInsets.all(isMobile ? 32 : 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: isMobile ? 48 : 64,
                      color: AppTheme.red500,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Error Loading Projects',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppTheme.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _fetchProjects,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16,
                      ),
                      isFullWidth: isMobile,
                    ),
                  ],
                ),
              )
            else if (filteredProjects.isEmpty)
              CustomCard(
                padding: EdgeInsets.all(isMobile ? 32 : 48),
                child: Column(
                  children: [
                    Icon(
                      _filterText.isEmpty
                          ? Icons.inventory_2
                          : Icons.search_off,
                      size: isMobile ? 48 : 64,
                      color: _filterText.isEmpty
                          ? AppTheme.gray300
                          : AppTheme.gray500,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      _filterText.isEmpty
                          ? 'No Projects Yet'
                          : 'No Projects Found',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filterText.isEmpty
                          ? 'Get started by creating your first APQP project'
                          : 'Try adjusting your search terms.',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppTheme.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    if (_filterText.isEmpty)
                      CustomButton(
                        text: 'Create Your First Project',
                        onPressed: widget.onCreateProject,
                        icon: const Icon(Icons.add, size: 16),
                        isFullWidth: isMobile,
                      )
                    else
                      CustomButton(
                        text: 'Clear Filter',
                        onPressed: () => setState(() => _filterText = ''),
                        variant: ButtonVariant.outline,
                        isFullWidth: isMobile,
                      ),
                  ],
                ),
              )
            else if (!_isTableView)
              // List View (Current)
              ...filteredProjects.map((project) {
                final projectId = _getProjectId(project);
                return Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                  child: CustomCard(
                    padding: EdgeInsets.all(
                      isMobile ? 16 : (isTablet ? 20 : 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title, project ID badge, and View Details button
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                project.partName,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.gray900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomBadge(
                              text: projectId,
                              variant: BadgeVariant.outline,
                            ),
                            const SizedBox(width: 8),
                            CustomButton(
                              text: 'View Details',
                              onPressed: () => widget.onViewProject(project),
                              variant: ButtonVariant.outline,
                              size: ButtonSize.sm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Customer, Location, Team Leader, Team Size in two columns
                        isMobile
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Customer',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.gray500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              project.customerName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Location',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.gray500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              project.location,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Team Leader',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.gray500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              project.teamLeader,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Team Size',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.gray500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${project.teamMembers.length} ${project.teamMembers.length == 1 ? 'member' : 'members'}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Customer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          project.customerName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          project.location,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Team Leader',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          project.teamLeader,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Team Size',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${project.teamMembers.length} ${project.teamMembers.length == 1 ? 'member' : 'members'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        // Progress section
                        Row(
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${project.progress}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getProgressColor(project.progress),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CustomProgress(
                          value: project.progress.toDouble(),
                          valueColor: _getProgressColor(project.progress),
                        ),
                        const SizedBox(height: 16),
                        //
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (project.phases.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...project.phases.take(3).map((phase) {
                                      // Extract phase number or name
                                      final phaseName = phase.name.contains(':')
                                          ? phase.name.split(':')[0].trim()
                                          : phase.name.split('–')[0].trim();
                                      return CustomBadge(
                                        text: phaseName,
                                        variant: BadgeVariant.secondary,
                                      );
                                    }),
                                    if (project.phases.length > 3)
                                      CustomBadge(
                                        text:
                                            '+${project.phases.length - 3} more',
                                        variant: BadgeVariant.secondary,
                                      ),
                                  ],
                                ),
                              CustomBadge(
                                text: project.projectStatus.toUpperCase(),
                                variant: BadgeVariant.secondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()
            else
              // Table View
              CustomCard(
                padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columnSpacing: isMobile ? 16 : 24,
                          headingRowColor: MaterialStateProperty.all(
                            AppTheme.gray100,
                          ),
                          dataRowColor: MaterialStateProperty.all(
                            AppTheme.card,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Plan Number',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Product Name',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Customer Name',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          rows: filteredProjects.map((project) {
                            final projectId = _getProjectId(project);
                            final statusText = _getStatusText(project);
                            return DataRow(
                              cells: [
                                DataCell(Text(projectId)),
                                DataCell(Text(project.partName)),
                                DataCell(Text(project.customerName)),
                                DataCell(
                                  CustomBadge(
                                    text: statusText,
                                    variant: BadgeVariant.secondary,
                                  ),
                                ),
                                DataCell(
                                  CustomButton(
                                    text: 'View Details',
                                    onPressed: () =>
                                        widget.onViewProject(project),
                                    variant: ButtonVariant.outline,
                                    size: ButtonSize.sm,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension ListExtension<T> on List<T> {
  void addIf(bool condition, T item) {
    if (condition) add(item);
  }
}
