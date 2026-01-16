import 'package:Texspin/screens/inquiry_screen.dart';
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
import '../bloc/manager/manager_bloc.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/individual_task_management_dialog.dart';
import '../widgets/department_task_management_dialog.dart';
import '../widgets/apqp_task_management_dialog.dart';
import '../screens/apqp_task_grid_screen.dart';
import 'all_audits_screen.dart';
import '../widgets/all_audits_dialog.dart';
import '../widgets/staff_performance_entry_dialog.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final Function(Project project) onViewProject;
  final VoidCallback? onLogout;
  final VoidCallback onInquiry;
  final String? userName;

  const ManagerDashboardScreen({
    super.key,
    required this.onViewProject,
    required this.onInquiry,
    this.onLogout,
    this.userName,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  bool _isTableView = true;
  String _filterText = '';
  String? _staffId;
  String?
  _statusFilter; // null = all, 'ongoing' = active, 'completed' = completed

  @override
  void initState() {
    super.initState();
    _loadStaffIdAndFetchProjects();
  }

  Future<void> _loadStaffIdAndFetchProjects() async {
    final staffId = await SharedPreferencesManager.getStaffId();
    if (staffId != null && staffId.isNotEmpty) {
      setState(() {
        _staffId = staffId;
      });
      if (mounted) {
        context.read<ManagerBloc>().add(LoadManagerProjects(staffId));
      }
    } else {
      developer.log(
        'No staff ID found in storage',
        name: 'ManagerDashboardScreen',
      );
    }
  }

  List<Project> _filterProjects(List<Project> projects) {
    var filtered = projects;

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

  Color _getProgressColor(int progress) {
    if (progress == 0) return AppTheme.red500;
    if (progress < 100) return AppTheme.yellow500;
    return AppTheme.green500;
  }

  String _getProjectId(Project project) {
    if (project.planNumber.isNotEmpty) {
      return project.planNumber;
    }
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

    return DashboardLayout(
      title: 'Manager Dashboard',
      subtitle: 'Manager',
      userName: widget.userName ?? 'Manager',
      navigationItems: [
        NavigationItem(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),

        NavigationItem(
          icon: Icons.task_alt,
          label: 'New Project Tasks',
          onTap: () async {
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth < 600) {
              // Mobile: Open full screen
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApqpTaskGridScreen()),
              );
            } else {
              // Web/Tablet: Open dialog
              await showDialog(
                context: context,
                builder: (_) => const ApqpTaskManagementDialog(),
              );
            }
            // Refresh data after returning
            if (mounted && _staffId != null) {
              context.read<ManagerBloc>().add(LoadManagerProjects(_staffId!));
            }
          },
        ),
        NavigationItem(
          icon: Icons.person_outline,
          label: 'Individual Tasks',
          onTap: () {
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth < 600) {
              // Mobile: Open full screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const IndividualTaskManagementDialog(),
                ),
              );
            } else {
              // Web/Tablet: Open dialog
              showDialog(
                context: context,
                builder: (_) => const IndividualTaskManagementDialog(),
              );
            }
          },
        ),
        NavigationItem(
          icon: Icons.business,
          label: 'Department Tasks',
          onTap: () {
            final screenWidth = MediaQuery.of(context).size.width;
            if (screenWidth < 600) {
              // Mobile: Open full screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DepartmentTaskManagementDialog(),
                ),
              );
            } else {
              // Web/Tablet: Open dialog
              showDialog(
                context: context,
                builder: (_) => const DepartmentTaskManagementDialog(),
              );
            }
          },
        ),
        NavigationItem(
          icon: Icons.check_circle_outline,
          label: 'Audit Tasks',
          onTap: () => _handleAudit(context),
        ),

        NavigationItem(
          icon: Icons.insights, // Staff Performance
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
        NavigationItem(
          icon: Icons.account_circle_outlined,
          label: 'Profile',
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => ProfileDialog(onLogout: widget.onLogout),
            );
          },
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
      child: BlocBuilder<ManagerBloc, ManagerState>(
        builder: (context, state) {
          final isLoading = state is ManagerLoading;
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = state is ManagerLoaded
              ? state.projects
              : <Project>[];
          final filteredProjects = _filterProjects(projects);
          final error = state is ManagerError ? state.message : null;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                // _buildHeader(isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),

                // Stats Overview
                _buildStatsOverview(projects, isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),

                // Filter and View Toggle
                _buildFilterSection(isMobile),
                SizedBox(height: isMobile ? 24 : 32),

                // Projects List or Table
                if (error != null && projects.isEmpty)
                  _buildErrorCard(error, isMobile)
                else if (filteredProjects.isEmpty)
                  _buildEmptyCard(isMobile)
                else if (!_isTableView)
                  ..._buildListView(filteredProjects, isMobile, isTablet)
                else
                  _buildTableView(filteredProjects, isMobile, isTablet),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(
    List<Project> projects,
    bool isMobile,
    bool isTablet,
  ) {
    return isMobile
        ? Column(
            children: [
              _buildStatCard(
                'Total Projects',
                '${projects.length}',
                Icons.inventory_2,
                AppTheme.blue100,
                AppTheme.blue600,
                const EdgeInsets.all(20),
                null,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Active Projects',
                '${projects.where((p) => p.progress > 0 && p.progress < 100).length}',
                Icons.calendar_today,
                AppTheme.green100,
                AppTheme.green600,
                const EdgeInsets.all(20),
                'ongoing',
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Completed Projects',
                '${projects.where((p) => p.progress == 100).length}',
                Icons.people,
                AppTheme.purple100,
                AppTheme.purple600,
                const EdgeInsets.all(20),
                'completed',
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Projects',
                  '${projects.length}',
                  Icons.inventory_2,
                  AppTheme.blue100,
                  AppTheme.blue600,
                  EdgeInsets.all(isTablet ? 20 : 24),
                  null,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Active Projects',
                  '${projects.where((p) => p.progress > 0 && p.progress < 100).length}',
                  Icons.calendar_today,
                  AppTheme.green100,
                  AppTheme.green600,
                  EdgeInsets.all(isTablet ? 20 : 24),
                  'ongoing',
                ),
              ),
              SizedBox(width: isTablet ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Completed Projects',
                  '${projects.where((p) => p.progress == 100).length}',
                  Icons.people,
                  AppTheme.purple100,
                  AppTheme.purple600,
                  EdgeInsets.all(isTablet ? 20 : 24),
                  'completed',
                ),
              ),
            ],
          );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    EdgeInsets padding,
    String? filterValue,
  ) {
    final isSelected = _statusFilter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = filterValue),
      child: CustomCard(
        padding: padding,
        child: Container(
          padding: isSelected ? const EdgeInsets.all(2) : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
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
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return isMobile
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
                onChanged: (value) => setState(() => _filterText = value),
                decoration: InputDecoration(
                  hintText: 'Search by customer or project name...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gray500),
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
                    onPressed: () => setState(() => _isTableView = false),
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
                    onPressed: () => setState(() => _isTableView = true),
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
                      onChanged: (value) => setState(() => _filterText = value),
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
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  CustomButton(
                    text: 'Table View',
                    onPressed: () => setState(() => _isTableView = true),
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
                    onPressed: () => setState(() => _isTableView = false),
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
          );
  }

  Widget _buildErrorCard(String error, bool isMobile) {
    return CustomCard(
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
            error,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppTheme.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          CustomButton(
            text: 'Retry',
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
            isFullWidth: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(bool isMobile) {
    return CustomCard(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      child: Column(
        children: [
          Icon(
            _filterText.isEmpty ? Icons.inventory_2 : Icons.search_off,
            size: isMobile ? 48 : 64,
            color: _filterText.isEmpty ? AppTheme.gray300 : AppTheme.gray500,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            _filterText.isEmpty ? 'No Projects Yet' : 'No Projects Found',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterText.isEmpty
                ? 'You don\'t have any projects assigned yet'
                : 'Try adjusting your search terms.',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppTheme.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_filterText.isNotEmpty) ...[
            SizedBox(height: isMobile ? 20 : 24),
            CustomButton(
              text: 'Clear Filter',
              onPressed: () => setState(() => _filterText = ''),
              variant: ButtonVariant.outline,
              isFullWidth: isMobile,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildListView(
    List<Project> projects,
    bool isMobile,
    bool isTablet,
  ) {
    return projects.map((project) {
      final projectId = _getProjectId(project);
      return Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        child: CustomCard(
          padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  CustomBadge(text: projectId, variant: BadgeVariant.outline),
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
              isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn(
                                'Customer',
                                project.customerName,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoColumn(
                                'Location',
                                project.location,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn(
                                'Team Leader',
                                project.teamLeader,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoColumn(
                                'Team Size',
                                '${project.teamMembers.length} ${project.teamMembers.length == 1 ? 'member' : 'members'}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildInfoColumn(
                            'Customer',
                            project.customerName,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn('Location', project.location),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Team Leader',
                            project.teamLeader,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Team Size',
                            '${project.teamMembers.length} ${project.teamMembers.length == 1 ? 'member' : 'members'}',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(fontSize: 14, color: AppTheme.gray600),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (project.phases.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...project.phases.take(3).map((phase) {
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
                            text: '+${project.phases.length - 3} more',
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
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppTheme.gray900),
        ),
      ],
    );
  }

  Widget _buildTableView(List<Project> projects, bool isMobile, bool isTablet) {
    return CustomCard(
      padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: isMobile ? 16 : 24,
                headingRowColor: MaterialStateProperty.all(AppTheme.gray100),
                dataRowColor: MaterialStateProperty.all(AppTheme.card),
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
                rows: projects.map((project) {
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
                          onPressed: () => widget.onViewProject(project),
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
    );
  }

  void _refreshProjects() {
    if (_staffId != null) {
      context.read<ManagerBloc>().add(LoadManagerProjects(_staffId!));
    }
  }

  void _handleAudit(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: Navigate to full screen
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AllAuditsScreen()));
    } else {
      // Web/Desktop: Show dialog
      showDialog(context: context, builder: (_) => const AllAuditsDialog());
    }
  }
}
