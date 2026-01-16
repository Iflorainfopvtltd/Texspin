import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/profile_dialog.dart';
import '../screens/staff_department_tasks_screen.dart';
import '../widgets/staff_department_tasks_dialog.dart';

import '../screens/staff_individual_tasks_screen.dart';
import '../widgets/staff_individual_tasks_dialog.dart';

import '../screens/staff_audit_tasks_screen.dart';
import '../widgets/staff_audit_tasks_dialog.dart';

import '../widgets/staff_apqp_projects_dialog.dart';
import '../screens/staff_apqp_projects_screen.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/staff_performance_entry_dialog.dart';

class StaffDashboardScreen extends StatefulWidget {
  final Function(Project project) onViewProject;
  final VoidCallback? onLogout;
  final String? userName;

  const StaffDashboardScreen({
    super.key,
    required this.onViewProject,
    this.onLogout,
    this.userName,
  });

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;

  // Recent Tasks State
  String _selectedFilter =
      'new_projects'; // new_projects, individual_tasks, department_tasks, audit_tasks
  List<dynamic> _recentTasks = [];
  bool _isRecentTasksLoading = false;
  String? _recentTasksError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _fetchRecentTasks(); // Initial load for default filter
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null || staffId.isEmpty) {
        throw Exception('Staff ID not found');
      }

      final data = await ApiService().getStaffDashboardData(staffId: staffId);

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchRecentTasks() async {
    if (_selectedFilter == 'other')
      return; // Do nothing for non-clickable cards

    setState(() {
      _isRecentTasksLoading = true;
      _recentTasksError = null;
      _recentTasks = [];
    });

    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null || staffId.isEmpty) {
        throw Exception('Staff ID not found');
      }

      final apiService = ApiService();
      Map<String, dynamic> response;

      switch (_selectedFilter) {
        case 'new_projects':
          response = await apiService.getStaffApqpProjects(staffId: staffId);
          if (response['apqpProjects'] != null) {
            _recentTasks = response['apqpProjects'];
          }
          break;
        case 'individual_tasks':
          // Assuming this returns tasks assigned to the user or we filter them if needed
          // based on user request, endpoint is /texspin/api/task
          response = await apiService.getTasks();
          // The response has "tasks" list confirmed by user
          // Filter tasks where assignedStaff.staffId == staffId if the API returns all
          // or just show them if the backend filters.
          // User JSON sample shows assignedStaff matches staffId.
          if (response['tasks'] != null) {
            final tasks = response['tasks'] as List;
            // Client-side filter to be safe, assuming staffId is TEXSPINEMP-... or mongo ID
            // The staffId from shared prefs is likely the mongo ID or the custom ID.
            // Let's filter if we can match relevant ID.
            // If uncertain, just show response['tasks'] as user requested specific endpoint.
            _recentTasks = tasks;
          }
          break;
        case 'department_tasks':
          response = await apiService.getDepartmentTasks();
          if (response['tasks'] != null) {
            _recentTasks = response['tasks'];
          }
          break;
        case 'audit_tasks':
          response = await apiService.getStaffAuditMains(staffId: staffId);
          if (response['audits'] != null) {
            _recentTasks = response['audits'];
          }
          break;
      }

      if (mounted) {
        setState(() {
          _isRecentTasksLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentTasksError = e.toString();
          _isRecentTasksLoading = false;
        });
      }
    }
  }

  void _onFilterSelected(String filterKey) {
    if (_selectedFilter == filterKey) return;
    setState(() {
      _selectedFilter = filterKey;
    });
    _fetchRecentTasks();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1200;

    return DashboardLayout(
      title: 'Staff Dashboard',
      subtitle: 'Staff Member',
      userName: widget.userName ?? 'Staff',
      navigationItems: [
        NavigationItem(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),
        NavigationItem(
          icon: Icons.folder_outlined,
          label: 'New Projects',
          onTap: () {
            if (screenWidth < 1200) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffApqpProjectsScreen(),
                ),
              ).then((_) => _loadDashboardData());
            } else {
              showDialog(
                context: context,
                builder: (_) => const StaffApqpProjectsDialog(),
              ).then((_) => _loadDashboardData());
            }
          },
        ),
        NavigationItem(
          icon: Icons.check_circle_outline,
          label: 'Audit Tasks',
          onTap: () {
            if (screenWidth < 1200) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffAuditTasksScreen(),
                ),
              ).then((_) => _loadDashboardData());
            } else {
              showDialog(
                context: context,
                builder: (_) => const StaffAuditTasksDialog(),
              ).then((_) => _loadDashboardData());
            }
          },
        ),
        NavigationItem(
          icon: Icons.assignment_outlined,
          label: 'Department Tasks',
          onTap: () {
            if (screenWidth < 1200) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffDepartmentTasksScreen(),
                ),
              ).then((_) => _loadDashboardData());
            } else {
              showDialog(
                context: context,
                builder: (_) => const StaffDepartmentTasksDialog(),
              ).then((_) => _loadDashboardData());
            }
          },
        ),

        NavigationItem(
          icon: Icons.person_outline,
          label: 'Individual Tasks',
          onTap: () {
            if (screenWidth < 1200) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffIndividualTasksScreen(),
                ),
              ).then((_) => _loadDashboardData());
            } else {
              showDialog(
                context: context,
                builder: (_) => const StaffIndividualTasksDialog(),
              ).then((_) => _loadDashboardData());
            }
          },
        ),
        NavigationItem(
          icon: Icons.insights,
          label: 'My Performance',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const StaffPerformanceEntryDialog(),
            );
          },
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
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      CustomCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.red500,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading dashboard: $_error',
                              style: const TextStyle(color: AppTheme.red500),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDashboardData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          _buildDashboardCards(isMobile),
                          const SizedBox(height: 32),
                          _buildRecentTasksSection(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardCards(bool isMobile) {
    if (_dashboardData == null) return const SizedBox.shrink();

    final data = _dashboardData!;

    final cards = [
      _DashboardCardData(
        title: 'New Projects',
        value: data['newProjectsCount']?.toString() ?? '0',
        icon: Icons.folder_open,
        color: AppTheme.blue600,
        bgColor: AppTheme.blue100,
        filterKey: 'new_projects',
      ),
      _DashboardCardData(
        title: 'Total Audit Tasks',
        value: data['totalAuditTasksAssigned']?.toString() ?? '0',
        icon: Icons.check_circle_outline,
        color: AppTheme.purple600,
        bgColor: AppTheme.purple100,
        filterKey: 'audit_tasks',
      ),
      _DashboardCardData(
        title: 'Department Tasks Pending',
        value: data['totalDeptTasksAssigned']?.toString() ?? '0',
        icon: Icons.business,
        color: AppTheme.indigo600,
        bgColor: AppTheme.indigo100,
        filterKey: 'department_tasks',
      ),
      _DashboardCardData(
        title: 'Individual Tasks',
        value: data['totalTasksAssigned']?.toString() ?? '0',
        icon: Icons.person_outline,
        color: AppTheme.teal600,
        bgColor: AppTheme.teal100,
        filterKey: 'individual_tasks',
      ),
      // _DashboardCardData(
      //   title: 'Task Help Pending',
      //   value: '0',
      //   icon: Icons.help_outline,
      //   color: AppTheme.orange600,
      //   bgColor: AppTheme.orange100,
      //   filterKey: 'other',
      // ),
      _DashboardCardData(
        title: 'Tasks Submitted for Review',
        value: data['totalTasksSubmitted']?.toString() ?? '0',
        icon: Icons.file_present,
        color: AppTheme.orange600,
        bgColor: AppTheme.orange100,
        filterKey: 'other',
      ),
      _DashboardCardData(
        title: 'Rejected Tasks',
        value: data['totalTasksRejected']?.toString() ?? '0',
        icon: Icons.cancel_outlined,
        color: AppTheme.red600,
        bgColor: AppTheme.red100,
        filterKey: 'other',
      ),
      _DashboardCardData(
        title: 'Completed Tasks',
        value: data['totalTasksApproved']?.toString() ?? '0',
        icon: Icons.check_circle_outline,
        color: AppTheme.green600,
        bgColor: AppTheme.green100,
        filterKey: 'other',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 100,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return _buildStatCard(cards[index]);
          },
        );
      },
    );
  }

  Widget _buildStatCard(_DashboardCardData card) {
    return InkWell(
      onTap: card.filterKey != 'other'
          ? () => _onFilterSelected(card.filterKey)
          : null,
      borderRadius: BorderRadius.circular(10),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: card.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, color: card.color, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recent Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 16),
        CustomCard(
          padding: EdgeInsets.zero,
          child: _isRecentTasksLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _recentTasksError != null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.red500),
                        const SizedBox(height: 8),
                        Text('Error: $_recentTasksError'),
                        TextButton(
                          onPressed: _fetchRecentTasks,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : _recentTasks.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(child: Text("No tasks found.")),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTasks.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppTheme.gray200),
                  itemBuilder: (context, index) {
                    return _buildTaskItem(_recentTasks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(dynamic item) {
    String title = '';
    String subtitle = '';
    String dateStr = '';
    String status = '';
    Color statusColor = AppTheme.gray500;
    Color statusBgColor = AppTheme.gray100;

    // Determine type based on fields
    if (_selectedFilter == 'new_projects') {
      // APQP Project
      title = item['partName'] ?? 'Unknown Project';
      subtitle = item['customerName'] ?? '';
      dateStr = item['dateOfIssue'] ?? '';
      status = item['projectStatus'] ?? 'Unknown';

      if (status == 'new') {
        statusColor = AppTheme.blue600;
        statusBgColor = AppTheme.blue100;
      } else if (status == 'ongoing') {
        statusColor = AppTheme.yellow600;
        statusBgColor = AppTheme.yellow100;
      } else if (status == 'completed') {
        statusColor = AppTheme.green600;
        statusBgColor = AppTheme.green100;
      }
    } else if (_selectedFilter == 'individual_tasks' ||
        _selectedFilter == 'department_tasks') {
      // Task
      title = item['name'] ?? 'Untitled Task';
      subtitle = item['description'] ?? '';
      dateStr = item['deadline'] ?? '';
      status = item['status'] ?? 'Unknown';

      if (status == 'submitted') {
        statusColor = AppTheme.orange600;
        statusBgColor = AppTheme.orange100;
      } else if (status == 'approved' || status == 'completed') {
        statusColor = AppTheme.green600;
        statusBgColor = AppTheme.green100;
      } else if (status == 'rejected') {
        statusColor = AppTheme.red600;
        statusBgColor = AppTheme.red100;
      } else if (status == 'pending' ||
          status == 'revision' ||
          status == 'open') {
        statusColor = AppTheme.yellow600;
        statusBgColor = AppTheme.yellow100;
      } else if (status == 'accepted') {
        // Seen in department tasks
        statusColor = AppTheme.blue600;
        statusBgColor = AppTheme.blue100;
      }
    } else if (_selectedFilter == 'audit_tasks') {
      // Audit
      // Use template name or company name as title
      String templateName = '';
      if (item['auditTemplate'] != null && item['auditTemplate'] is Map) {
        templateName = item['auditTemplate']['name'] ?? '';
      }
      title = templateName.isNotEmpty
          ? templateName
          : (item['auditNumber'] ?? 'Audit');
      subtitle = item['companyName'] ?? '';
      dateStr = item['date'] ?? '';
      status = item['auditStatus'] ?? 'Unknown';
      if (status == 'open') {
        statusColor = AppTheme.blue600;
        statusBgColor = AppTheme.blue100;
      } else if (status == 'closed') {
        statusColor = AppTheme.green600;
        statusBgColor = AppTheme.green100;
      }
    }

    // Format date field
    String formattedDate = dateStr;
    try {
      if (dateStr.isNotEmpty) {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status.toUpperCase(), // Capitalize status
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
          ),
        ],
      ),
    );
  }
}

class _DashboardCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String filterKey;

  _DashboardCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.filterKey,
  });
}
