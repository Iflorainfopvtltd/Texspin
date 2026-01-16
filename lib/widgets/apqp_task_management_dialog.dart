import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../models/staff_apqp_project.dart';
import '../utils/shared_preferences_manager.dart';
import 'staff_apqp_task_submission_dialog.dart';
import 'dart:developer' as developer;

class ApqpTaskManagementDialog extends StatefulWidget {
  const ApqpTaskManagementDialog({super.key});

  @override
  State<ApqpTaskManagementDialog> createState() =>
      _ApqpTaskManagementDialogState();
}

class _ApqpTaskManagementDialogState extends State<ApqpTaskManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Admin/Manager View State
  List<Map<String, dynamic>> _approvals = [];
  List<Map<String, dynamic>> _filteredApprovals = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  // My Tasks View State
  List<StaffApqpProject> _myProjects = [];
  bool _isLoadingMyTasks = false;
  String? _myTasksError;
  String? _currentStaffId;

  final TextEditingController _myTasksSearchController =
      TextEditingController();
  String _myTasksSelectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadApprovals();
    _loadMyTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _myTasksSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getProjectApprovals();
      setState(() {
        _approvals = (response['approvals'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        _filterTasks(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      developer.log(
        'Error loading New Project tasks: $e',
        name: 'ApqpTaskManagement',
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyTasks() async {
    setState(() {
      _isLoadingMyTasks = true;
      _myTasksError = null;
    });

    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null) throw Exception('Staff ID not found');
      _currentStaffId = staffId;

      final response = await _apiService.getStaffApqpProjects(staffId: staffId);
      final projectResponse = StaffApqpProjectResponse.fromJson(response);

      if (mounted) {
        setState(() {
          final List<StaffApqpProject> projects = projectResponse.apqpProjects;
          projects.sort((a, b) => b.id.compareTo(a.id));
          _myProjects = projects;
          _isLoadingMyTasks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myTasksError = e.toString();
          _isLoadingMyTasks = false;
        });
      }
    }
  }

  void _filterTasks(String query) {
    setState(() {
      _applyFilters(query, _selectedFilter);
    });
  }

  void _applyFilters(String query, String statusFilter) {
    var filtered = _approvals;

    // Apply status filter
    if (statusFilter != 'all') {
      filtered = filtered.where((approval) {
        final status = (approval['activityStatus']?.toString() ?? 'pending')
            .toLowerCase();
        switch (statusFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'completed':
            return status == 'approved' || status == 'completed';
          case 'rejected':
            return status == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Apply text filter
    if (query.isNotEmpty) {
      filtered = filtered.where((approval) {
        final activityName = (approval['activityName']?.toString() ?? '')
            .toLowerCase();
        final projectName = (approval['projectName']?.toString() ?? '')
            .toLowerCase();
        final phaseName = (approval['phaseName']?.toString() ?? '')
            .toLowerCase();
        final searchLower = query.toLowerCase();
        return activityName.contains(searchLower) ||
            projectName.contains(searchLower) ||
            phaseName.contains(searchLower);
      }).toList();
    }

    _filteredApprovals = filtered;
  }

  Widget _buildFilterChip(
    String label,
    String value, {
    bool isMyTasks = false,
  }) {
    final isSelected = isMyTasks
        ? _myTasksSelectedFilter == value
        : _selectedFilter == value;
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
          if (isMyTasks) {
            _myTasksSelectedFilter = value;
          } else {
            _selectedFilter = value;
            _applyFilters(_searchController.text, _selectedFilter);
          }
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
    );
  }

  // ... (Keep existing helpers like _getStatusColor, _formatDate, _downloadFile, _showApproveDialog, _showRejectDialog, _sendReminder, _updateTaskStatus, _buildTaskDataRow) ...
  // Wait, I need to make sure I don't delete them or I duplicate what I need.
  // The tool instructions say: "Replace Content".
  // I should be careful not to delete existing methods if I reuse them or if they are in the block I'm replacing.
  // Since I am replacing a huge chunk, I should include the existing methods AND the new ones.
  // Actually, I can use `multi_replace_file_content` or just targeted replacements.

  // Let's look at the existing code again. Accessing `_buildMyTasksView` is my main goal.
  // It is currently:
  /*
  Widget _buildMyTasksView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.assignment_ind, size: 64, color: AppTheme.gray300),
          SizedBox(height: 16),
          Text(
            'No personal tasks assigned',
            style: TextStyle(fontSize: 18, color: AppTheme.gray600),
          ),
        ],
      ),
    );
  }
  */
  // I should replace THAT method specifically.
  // And also `initState`, `dispose`, and add new helper methods.

  Widget _buildMyTasksView() {
    if (_isLoadingMyTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myTasksError != null) {
      return Center(child: Text('Error: $_myTasksError'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        // Filter Section
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextInput(
                hint: 'Search by project, part, or activity...',
                controller: _myTasksSearchController,
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', isMyTasks: true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending', isMyTasks: true),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Submitted',
                        'submitted',
                        isMyTasks: true,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Completed',
                        'completed',
                        isMyTasks: true,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected', isMyTasks: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: _myProjects.isEmpty
              ? const Center(child: Text('No APQP projects assigned'))
              : SingleChildScrollView(
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
                          DataColumn(label: Text('Project Name')),
                          DataColumn(label: Text('Part Name')),
                          DataColumn(label: Text('Phase')),
                          DataColumn(label: Text('Activity')),
                          DataColumn(label: Text('Deadline')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Approval')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _buildMyTasksFlattenedRows(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<DataRow> _buildMyTasksFlattenedRows() {
    final List<Map<String, dynamic>> rowData = [];
    final searchText = _myTasksSearchController.text.toLowerCase();

    for (var project in _myProjects) {
      for (var phase in project.phases) {
        for (var activity in phase.activities) {
          // Filter by assigned staff (Double check if current staff is assigned)
          // The API supposedly returns projects where staff is assigned, but
          // we should double check activity level assignment if necessary.
          // StaffApqpProjectsDialog does:
          /*
          if (_currentStaffId != null &&
              activity.staff?.staffId != _currentStaffId &&
              activity.staff?.id != _currentStaffId) {
            continue;
          }
          */
          // I'll include it for safety.
          if (_currentStaffId != null &&
              activity.staff?.staffId != _currentStaffId &&
              activity.staff?.id != _currentStaffId) {
            // Maybe continue? But sometimes manager sees all?
            // "My Tasks" implies explicitly assigned to me.
            // Let's keep the filter.
            continue;
          }

          // Apply Search Filter
          if (searchText.isNotEmpty) {
            final matchesName = project.customerName.toLowerCase().contains(
              searchText,
            );
            final matchesPart = project.partName.toLowerCase().contains(
              searchText,
            );
            final matchesActivity = activity.activity.name
                .toLowerCase()
                .contains(searchText);
            if (!matchesName && !matchesPart && !matchesActivity) continue;
          }

          // Apply Status Filter
          if (_myTasksSelectedFilter != 'all') {
            final status = activity.activityStatus.toLowerCase();
            final approval = activity.activityApprovalStatus.toLowerCase();

            bool matches = false;

            if (_myTasksSelectedFilter == 'pending') {
              if (status == 'pending' ||
                  (approval == 'pending' && status != 'rejected'))
                matches = true;
            } else if (_myTasksSelectedFilter == 'submitted') {
              if (status == 'submitted' || approval == 'submitted')
                matches = true;
            } else if (_myTasksSelectedFilter == 'completed') {
              if (status == 'completed') matches = true;
            } else if (_myTasksSelectedFilter == 'rejected') {
              if (status == 'rejected' || approval == 'rejected')
                matches = true;
            }

            if (!matches) continue;
          }

          rowData.add({
            'project': project,
            'phase': phase,
            'activity': activity,
            'isPending':
                activity.activityStatus.toLowerCase() == 'pending' ||
                activity.activityApprovalStatus.toLowerCase() == 'pending',
          });
        }
      }
    }

    rowData.sort((a, b) {
      if (a['isPending'] && !b['isPending']) return -1;
      if (!a['isPending'] && b['isPending']) return 1;
      return 0;
    });

    final List<DataRow> rows = [];
    for (var data in rowData) {
      final project = data['project'] as StaffApqpProject;
      final phase = data['phase'] as StaffApqpPhase;
      final activity = data['activity'] as StaffApqpActivityWrapper;

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(project.customerName)),
            DataCell(Text(project.partName)),
            DataCell(Text(phase.phase.name)),
            DataCell(Text(activity.activity.name)),
            DataCell(Text(_formatDate(activity.endDate))),
            DataCell(_buildMyTasksStatusBadge(activity)),
            DataCell(_buildMyTasksApprovalBadge(activity)),
            DataCell(_buildMyTasksActions(project, phase, activity)),
          ],
        ),
      );
    }
    return rows;
  }

  Widget _buildMyTasksActions(
    StaffApqpProject project,
    StaffApqpPhase phase,
    StaffApqpActivityWrapper activity,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activity.fileUrl != null && activity.fileUrl!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.blue600),
            tooltip: 'Download Instructions',
            onPressed: () =>
                _downloadFile(activity.fileUrl!, 'activity_instructions'),
          ),

        if ((activity.activityStatus.toLowerCase() == 'ongoing' ||
                activity.activityStatus.toLowerCase() == 'accepted' ||
                activity.activityApprovalStatus.toLowerCase() == 'accepted') &&
            activity.activityStatus.toLowerCase() != 'submitted' &&
            activity.activityStatus.toLowerCase() != 'completed') ...[
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppTheme.blue600),
            tooltip: 'Update Work',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StaffApqpTaskSubmissionDialog(
                  projectId: project.id,
                  phaseId: phase.phase.id,
                  activityWrapper: activity,
                  onTaskUpdated: _loadMyTasks,
                ),
              );
            },
          ),
        ] else if (activity.activityStatus.toLowerCase() == 'pending' &&
            activity.activityApprovalStatus.toLowerCase() == 'pending') ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppTheme.green600),
            tooltip: 'Accept Task',
            onPressed: () => _updateMyTaskActivityStatus(
              project.id,
              phase.phase.id,
              activity.activity.id,
              'ongoing',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppTheme.red600),
            tooltip: 'Reject Task',
            onPressed: () =>
                _showMyTaskRejectDialog(project.id, phase.phase.id, activity),
          ),
        ],
      ],
    );
  }

  Widget _buildMyTasksStatusBadge(StaffApqpActivityWrapper activity) {
    final status = activity.activityStatus;
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.green500;
        break;
      case 'in progress':
      case 'ongoing':
      case 'accepted':
        color = AppTheme.blue500;
        break;
      case 'pending':
        color = AppTheme.yellow500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      default:
        color = AppTheme.yellow500;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (activity.managerReason != null && activity.managerReason!.isNotEmpty) {
      return Tooltip(message: activity.managerReason!, child: badge);
    }

    return badge;
  }

  Widget _buildMyTasksApprovalBadge(StaffApqpActivityWrapper activity) {
    final status = activity.activityApprovalStatus;
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        color = AppTheme.green500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      case 'submitted':
      case 'under review':
        color = AppTheme.blue500;
        break;
      case 'pending':
      default:
        color = AppTheme.gray500;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (activity.staffReason != null && activity.staffReason!.isNotEmpty) {
      return Tooltip(message: activity.staffReason!, child: badge);
    }

    return badge;
  }

  Future<void> _updateMyTaskActivityStatus(
    String projectId,
    String phaseId,
    String activityId,
    String status, {
    String? reason,
  }) async {
    try {
      String paramAssignmentAction;
      if (status == 'ongoing') {
        paramAssignmentAction = 'accept';
      } else if (status == 'rejected') {
        paramAssignmentAction = 'reject';
      } else {
        paramAssignmentAction = status;
      }

      await ApiService().staffRespondToActivity(
        projectId: projectId,
        phaseId: phaseId,
        activityId: activityId,
        assignmentAction: paramAssignmentAction,
        rejectionReason: reason,
      );

      if (!mounted) return;
      _loadMyTasks();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task status updated to $status')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  void _showMyTaskRejectDialog(
    String projectId,
    String phaseId,
    StaffApqpActivityWrapper activity,
  ) {
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this task:'),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => reason = value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter reason...',
              ),
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
              if (reason.isNotEmpty) {
                Navigator.pop(context);
                _updateMyTaskActivityStatus(
                  projectId,
                  phaseId,
                  activity.activity.id,
                  'rejected',
                  reason: reason,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red600),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return AppTheme.green500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
      case 'submitted':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
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

      // Construct full URL using ApiService baseUrl
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

  void _showApproveDialog(Map<String, dynamic> approval) {
    final activityName = approval['activityName']?.toString() ?? 'Task';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: Text('Are you sure you want to approve "$activityName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Approve',
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus(approval, 'approve');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> approval) {
    final activityName = approval['activityName']?.toString() ?? 'Task';
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "$activityName"?'),
            const SizedBox(height: 16),
            CustomTextInput(
              label: 'Rejection Reason',
              hint: 'Please provide a reason for rejection',
              controller: reasonController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a rejection reason';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Reject',
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppTheme.red500,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateTaskStatus(
                approval,
                'reject',
                rejectionReason: reasonController.text.trim(),
              );
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(Map<String, dynamic> approval) async {
    try {
      final projectId = approval['projectId']?.toString() ?? '';
      final response = await _apiService.sendApqpTaskReminder(
        projectId: projectId,
      );

      if (mounted) {
        final successMessage =
            response['message']?.toString() ?? 'Reminder sent successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
      }
    } catch (e) {
      developer.log('Error sending reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error sending reminder: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(
    Map<String, dynamic> approval,
    String action, {
    String? rejectionReason,
  }) async {
    try {
      final projectId = approval['projectId']?.toString() ?? '';
      final phaseId = approval['phaseId']?.toString() ?? '';
      final activityId = approval['activityId']?.toString() ?? '';

      final response = await _apiService.updateApqpActivityStatus(
        projectId: projectId,
        phaseId: phaseId,
        activityId: activityId,
        fileAction: action, // 'approve' or 'reject'
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        // Use the message from API response if available, otherwise use default
        final successMessage =
            response['message']?.toString() ??
            (action == 'approve'
                ? 'Task approved successfully'
                : 'Task rejected successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: action == 'approve'
                ? AppTheme.green500
                : AppTheme.red500,
          ),
        );
        _loadApprovals(); // Refresh the list
      }
    } catch (e) {
      developer.log('Error updating task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  DataRow _buildTaskDataRow(Map<String, dynamic> approval) {
    final activityName =
        approval['activityName']?.toString() ?? 'Unknown Activity';
    final projectName =
        approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final status =
        approval['activityStatus']?.toString() ??
        approval['status']?.toString() ??
        'pending';
    final submittedDate = approval['submittedDate']?.toString();
    final fileUrl = approval['fileUrl']?.toString();
    final fileName = approval['fileName']?.toString();

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              activityName,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              projectName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              phaseName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: AppTheme.gray600),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(submittedDate),
            style: const TextStyle(color: AppTheme.gray700),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // For pending/submitted tasks: show reminder, download, approve and reject
              if (status.toLowerCase().trim() == 'pending' ||
                  status.toLowerCase().trim() == 'submitted') ...[
                // Reminder button (only for pending tasks)
                if (status.toLowerCase().trim() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.send_outlined,
                      color: AppTheme.yellow500,
                    ),
                    onPressed: () => _sendReminder(approval),
                    tooltip: 'Send Reminder',
                  ),
                // Download button (if file is available)
                if (fileUrl != null && fileUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () {
                      final name = fileName ?? fileUrl.split('/').last;
                      _downloadFile(fileUrl, name);
                    },
                    tooltip: 'Download File',
                  ),
                // Approve button
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.green600,
                  ),
                  onPressed: () => _showApproveDialog(approval),
                  tooltip: 'Approve',
                ),
                // Reject button
                IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.red500,
                  ),
                  onPressed: () => _showRejectDialog(approval),
                  tooltip: 'Reject',
                ),
              ] else ...[
                // For approved/rejected tasks: show download only
                if (fileUrl != null && fileUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () {
                      final name = fileName ?? fileUrl.split('/').last;
                      _downloadFile(fileUrl, name);
                    },
                    tooltip: 'Download File',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.red500),
              const SizedBox(height: 16),
              const Text(
                'Error loading New Project Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.gray600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retry',
                onPressed: _loadApprovals,
                variant: ButtonVariant.default_,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar and Filters
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              CustomTextInput(
                controller: _searchController,
                hint: 'Search by activity, project, or phase name...',
                onChanged: _filterTasks,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterTasks('');
                        },
                      )
                    : const Icon(Icons.search),
              ),
              const SizedBox(height: 16),
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Submitted', 'submitted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Task List
        Expanded(
          child: _filteredApprovals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _approvals.isEmpty ? Icons.task_alt : Icons.search_off,
                        size: 64,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _approvals.isEmpty
                            ? 'No New Project Tasks yet'
                            : 'No tasks found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                              'Activity Name',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Project',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Phase',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Submitted On',
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
                        rows: _filteredApprovals
                            .map((approval) => _buildTaskDataRow(approval))
                            .toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      children: [
        const Icon(Icons.task_alt, color: AppTheme.gray600, size: 24),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'New Project Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppTheme.gray600),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
