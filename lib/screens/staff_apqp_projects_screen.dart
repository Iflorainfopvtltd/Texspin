import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/staff_apqp_project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/staff_apqp_task_submission_dialog.dart';

class StaffApqpProjectsScreen extends StatefulWidget {
  const StaffApqpProjectsScreen({super.key});

  @override
  State<StaffApqpProjectsScreen> createState() =>
      _StaffApqpProjectsScreenState();
}

class _StaffApqpProjectsScreenState extends State<StaffApqpProjectsScreen> {
  final ApiService _apiService = ApiService();
  List<StaffApqpProject> _projects = [];
  bool _isLoading = true;
  String? _error;
  String? _currentStaffId;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
          _projects = projects;
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

  Future<void> _updateActivityStatus(
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

      await _apiService.staffRespondToActivity(
        projectId: projectId,
        phaseId: phaseId,
        activityId: activityId,
        assignmentAction: paramAssignmentAction,
        rejectionReason: reason,
      );

      if (!mounted) return;
      _loadProjects();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task status updated to $status')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  void _showRejectDialog(
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
                _updateActivityStatus(
                  projectId,
                  phaseId,
                  activity.activity.id,
                  'rejected',
                  reason: reason,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red600),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      final String fullUrl = ApiService.baseUrl + fileUrl;
      final Uri url = Uri.parse(fullUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('New Project', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _projects.isEmpty
                      ? const Center(child: Text('No APQP projects assigned'))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _buildFilteredCards(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          CustomTextInput(
            controller: _searchController,
            hint: 'Search by project, part, or activity...',
            onChanged: (value) => setState(() {}),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
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
    );
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
        });
      },
      backgroundColor: AppTheme.gray100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.gray300),
    );
  }

  List<Widget> _buildFilteredCards() {
    final List<Widget> cards = [];
    final searchText = _searchController.text.toLowerCase();

    for (var project in _projects) {
      for (var phase in project.phases) {
        for (var activity in phase.activities) {
          if (_currentStaffId != null &&
              activity.staff?.staffId != _currentStaffId &&
              activity.staff?.id != _currentStaffId) {
            continue;
          }

          // Apply Search
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
          if (_selectedFilter != 'all') {
            final status = activity.activityStatus.toLowerCase();
            final approval = activity.activityApprovalStatus.toLowerCase();
            bool matches = false;

            if (_selectedFilter == 'pending') {
              if (status == 'pending' ||
                  (approval == 'pending' && status != 'rejected')) {
                matches = true;
              }
            } else if (_selectedFilter == 'submitted') {
              if (status == 'submitted' || approval == 'submitted') {
                matches = true;
              }
            } else if (_selectedFilter == 'completed') {
              if (status == 'completed') matches = true;
            } else if (_selectedFilter == 'rejected') {
              if (status == 'rejected' || approval == 'rejected') {
                matches = true;
              }
            }

            if (!matches) continue;
          }

          cards.add(_buildProjectCard(project, phase, activity));
        }
      }
    }
    return cards;
  }

  Widget _buildProjectCard(
    StaffApqpProject project,
    StaffApqpPhase phase,
    StaffApqpActivityWrapper activity,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
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
                    project.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                _buildStatusBadge(activity.activityStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Part: ${project.partName}',
              style: const TextStyle(color: AppTheme.gray600),
            ),
            const SizedBox(height: 4),
            Text(
              'Phase: ${phase.phase.name}',
              style: const TextStyle(color: AppTheme.gray600),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              activity.activity.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                    Text(
                      _formatDate(activity.startDate),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'End',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                    Text(
                      _formatDate(activity.endDate),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activity.activityApprovalStatus != 'pending') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Approval: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  _buildApprovalBadge(activity.activityApprovalStatus),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Actions
            _buildActions(project, phase, activity),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    StaffApqpProject project,
    StaffApqpPhase phase,
    StaffApqpActivityWrapper activity,
  ) {
    final status = activity.activityStatus.toLowerCase();

    // Download Button
    Widget? downloadBtn;
    if (activity.fileUrl != null && activity.fileUrl!.isNotEmpty) {
      downloadBtn = CustomButton(
        text: 'Download File',
        onPressed: () => _downloadFile(activity.fileUrl!, 'file'),
        variant: ButtonVariant.outline,
        size: ButtonSize.default_,
        isFullWidth: true,
        icon: const Icon(Icons.download, size: 16),
      );
    }

    return Column(
      children: [
        if (downloadBtn != null) ...[downloadBtn, const SizedBox(height: 12)],

        if (status == 'pending')
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  onPressed: () => _updateActivityStatus(
                    project.id,
                    phase.phase.id,
                    activity.activity.id,
                    'ongoing',
                  ),
                  variant: ButtonVariant.default_,
                  size: ButtonSize.default_,
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  onPressed: () =>
                      _showRejectDialog(project.id, phase.phase.id, activity),
                  variant: ButtonVariant.destructive,
                  size: ButtonSize.default_,
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),

        if ((status == 'ongoing' || status == 'accepted') &&
            status != 'submitted' &&
            status != 'completed') ...[
          // Update Button for ongoing tasks
          CustomButton(
            text: 'Update Work',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StaffApqpTaskSubmissionDialog(
                  projectId: project.id,
                  phaseId: phase.phase.id,
                  activityWrapper: activity,
                  onTaskUpdated: _loadProjects,
                ),
              );
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.default_,
            isFullWidth: true,
            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
          ),
        ],
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.green500;
        break;
      case 'in progress':
      case 'ongoing':
        color = AppTheme.blue500;
        break;
      case 'pending':
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

  Widget _buildApprovalBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        color = AppTheme.green500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      case 'pending':
      default:
        color = AppTheme.gray500;
    }

    return Text(
      status.toUpperCase(),
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}
