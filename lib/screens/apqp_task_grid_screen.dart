import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../models/staff_apqp_project.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/staff_apqp_task_submission_dialog.dart';
import 'dart:developer' as developer;

class ApqpTaskGridScreen extends StatefulWidget {
  const ApqpTaskGridScreen({super.key});

  @override
  State<ApqpTaskGridScreen> createState() => _ApqpTaskGridScreenState();
}

class _ApqpTaskGridScreenState extends State<ApqpTaskGridScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
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
        _filteredApprovals = _approvals;
        _isLoading = false;
      });
    } catch (e) {
      developer.log(
        'Error loading New Project tasks: $e',
        name: 'ApqpTaskGrid',
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
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
          _selectedFilter = value;
          _applyFilters(_searchController.text, _selectedFilter);
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
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
      final String fullUrl = ApiService.baseUrl + fileUrl;
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
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason for rejection',
                border: OutlineInputBorder(),
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

  Widget _buildApqpTaskCard(Map<String, dynamic> approval) {
    final activityName =
        approval['activityName']?.toString() ?? 'Unknown Activity';
    final projectName =
        approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final status = approval['activityStatus']?.toString() ?? 'pending';
    final submittedDate = approval['submittedDate']?.toString();
    final fileUrl = approval['fileUrl']?.toString();
    final fileName = approval['fileName']?.toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(Icons.task_alt, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activityName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Project and Phase Info
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.layers_outlined, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    phaseName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(submittedDate)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions Row
            // Actions Column
            Column(
              children: [
                // Download Button (Full Width)
                if (fileUrl != null &&
                    fileUrl.isNotEmpty &&
                    fileName != null) ...[
                  CustomButton(
                    text: 'Download File',
                    onPressed: () => _downloadFile(fileUrl, fileName),
                    variant: ButtonVariant.outline,
                    size: ButtonSize.default_,
                    isFullWidth: true,
                    icon: const Icon(Icons.download, size: 18),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons Row (Approve/Reject/Remind)
                if (status.toLowerCase() == 'pending' ||
                    status.toLowerCase() == 'submitted')
                  Row(
                    children: [
                      // Remind Button (Only for pending)
                      if (status.toLowerCase() == 'pending') ...[
                        Expanded(
                          child: CustomButton(
                            text: 'Remind',
                            onPressed: () => _sendReminder(approval),
                            variant: ButtonVariant.outline,
                            size: ButtonSize.default_, // Match size
                            icon: const Icon(Icons.send, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Approve Button
                      Expanded(
                        child: CustomButton(
                          text: 'Accept', // User requested "Accept" text
                          onPressed: () => _showApproveDialog(approval),
                          // Use a dark color variant if available, else default (primary blue/black)
                          // Assuming ButtonVariant.default_ maps to primary color.
                          // If 'black' is needed, we might need a specific style or variant.
                          // Using default_ for now as it usually means primary action.
                          variant: ButtonVariant.default_,
                          size: ButtonSize.default_,
                          icon: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white, // White icon on dark button
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reject Button
                      Expanded(
                        child: CustomButton(
                          text: 'Reject',
                          onPressed: () => _showRejectDialog(approval),
                          variant: ButtonVariant.destructive,
                          size: ButtonSize.default_,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(
          MediaQuery.of(context).size.width < 600
              ? 'New Project'
              : 'New Project Tasks',
        ),
        bottom: TabBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStaffAssignedTasksView(), _buildMyTasksView()],
      ),
    );
  }

  Widget _buildStaffAssignedTasksView() {
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
                'Error loading New Project tasks',
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
          padding: const EdgeInsets.all(16),
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
        // Task Grid
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
                            ? 'No New Project tasks yet'
                            : 'No tasks found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApprovals,
                  child: ListView.builder(
                    itemCount: _filteredApprovals.length,
                    itemBuilder: (context, index) {
                      final approval = _filteredApprovals[index];
                      return _buildApqpTaskCard(approval);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMyTasksView() {
    if (_isLoadingMyTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myTasksError != null) {
      return Center(child: Text('Error: $_myTasksError'));
    }

    // Filter Logic
    List<Map<String, dynamic>> filteredTasks = [];
    final searchText = _myTasksSearchController.text.toLowerCase();

    for (var project in _myProjects) {
      for (var phase in project.phases) {
        for (var activity in phase.activities) {
          // Filter by assigned staff
          if (_currentStaffId != null &&
              activity.staff?.staffId != _currentStaffId &&
              activity.staff?.id != _currentStaffId) {
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
                  (approval == 'pending' && status != 'rejected')) {
                matches = true;
              }
            } else if (_myTasksSelectedFilter == 'submitted') {
              if (status == 'submitted' || approval == 'submitted') {
                matches = true;
              }
            } else if (_myTasksSelectedFilter == 'completed') {
              if (status == 'completed') matches = true;
            } else if (_myTasksSelectedFilter == 'rejected') {
              if (status == 'rejected' || approval == 'rejected') {
                matches = true;
              }
            }

            if (!matches) continue;
          }

          filteredTasks.add({
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

    filteredTasks.sort((a, b) {
      if (a['isPending'] && !b['isPending']) return -1;
      if (!a['isPending'] && b['isPending']) return 1;
      return 0;
    });

    return Column(
      children: [
        // Filter Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextInput(
                hint: 'Search by project, part, or activity...',
                controller: _myTasksSearchController,
                onChanged: (value) => setState(() {}),
                suffixIcon: _myTasksSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _myTasksSearchController.clear();
                          setState(() {});
                        },
                      )
                    : const Icon(Icons.search),
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
                    _buildMyTasksFilterChip('Submitted', 'submitted'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildMyTasksFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Task List
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.assignment_ind,
                        size: 64,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _myProjects.isEmpty
                            ? 'No personal tasks assigned'
                            : 'No tasks found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyTasks,
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final data = filteredTasks[index];
                      return _buildMyTaskCard(
                        data['project'] as StaffApqpProject,
                        data['phase'] as StaffApqpPhase,
                        data['activity'] as StaffApqpActivityWrapper,
                      );
                    },
                  ),
                ),
        ),
      ],
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

  Widget _buildMyTaskCard(
    StaffApqpProject project,
    StaffApqpPhase phase,
    StaffApqpActivityWrapper activity,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.assignment, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.activity.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMyTasksStatusBadge(activity),
              ],
            ),
            const SizedBox(height: 12),

            // Project/Phase Info
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.layers_outlined, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    phase.phase.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${_formatDate(activity.endDate)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions
            _buildMyTasksActions(project, phase, activity),
          ],
        ),
      ),
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
      case 'submitted':
        color = AppTheme.purple600;
        break;
      default:
        color = AppTheme.yellow500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMyTasksActions(
    StaffApqpProject project,
    StaffApqpPhase phase,
    StaffApqpActivityWrapper activity,
  ) {
    final status = activity.activityStatus.toLowerCase();
    // final approval = activity.activityApprovalStatus.toLowerCase();

    List<Widget> actions = [];

    // Download Button
    if (activity.fileUrl != null && activity.fileUrl!.isNotEmpty) {
      actions.add(
        Expanded(
          child: CustomButton(
            text: 'Download',
            onPressed: () =>
                _downloadFile(activity.fileUrl!, 'activity_instructions'),
            variant: ButtonVariant.outline,
            size: ButtonSize.sm,
            icon: const Icon(Icons.download, size: 16),
          ),
        ),
      );
    }

    // Update Work / Submit Button
    if ((status == 'ongoing' || status == 'accepted') &&
        status != 'submitted' &&
        status != 'completed') {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CustomButton(
            text: 'Update',
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
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
            icon: const Icon(Icons.upload_file, size: 16),
          ),
        ),
      );
    }
    // Accept/Reject Buttons for Pending
    else if (status == 'pending') {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CustomButton(
            text: 'Accept',
            onPressed: () => _updateMyTaskActivityStatus(
              project.id,
              phase.phase.id,
              activity.activity.id,
              'ongoing',
            ),
            variant: ButtonVariant.default_,
            // Greenish variant if possible, else default
            size: ButtonSize.sm,
            icon: const Icon(
              Icons.check_circle,
              size: 16,
              color: AppTheme.primaryForeground,
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: CustomButton(
            text: 'Reject',
            onPressed: () =>
                _showMyTaskRejectDialog(project.id, phase.phase.id, activity),
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
            icon: const Icon(
              Icons.cancel,
              size: 16,
              color: AppTheme.primaryForeground,
            ),
          ),
        ),
      );
    }

    return Row(children: actions);
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
}
