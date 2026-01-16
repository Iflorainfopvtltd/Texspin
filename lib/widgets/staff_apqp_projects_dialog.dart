import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/staff_apqp_project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';
import 'staff_apqp_task_submission_dialog.dart';
import 'custom_text_input.dart';
import 'dart:developer' as developer;

class StaffApqpProjectsDialog extends StatefulWidget {
  const StaffApqpProjectsDialog({super.key});

  @override
  State<StaffApqpProjectsDialog> createState() =>
      _StaffApqpProjectsDialogState();
}

class _StaffApqpProjectsDialogState extends State<StaffApqpProjectsDialog> {
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

      setState(() {
        final List<StaffApqpProject> projects = projectResponse.apqpProjects;
        projects.sort((a, b) => b.id.compareTo(a.id));
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Projects',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _projects.isEmpty
                  ? const Center(child: Text('No APQP projects assigned'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
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
                          rows: _buildFlattenedRows(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextInput(
                hint: 'Search by project, part, or activity...',
                controller: _searchController,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SingleChildScrollView(
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
        ),
      ],
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

  List<DataRow> _buildFlattenedRows() {
    final List<Map<String, dynamic>> rowData = [];
    final searchText = _searchController.text.toLowerCase();

    for (var project in _projects) {
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
          if (_selectedFilter != 'all') {
            final status = activity.activityStatus.toLowerCase();
            final approval = activity.activityApprovalStatus.toLowerCase();

            bool matches = false;

            if (_selectedFilter == 'pending') {
              // Show if pending either in status or approval (if not rejected)
              if (status == 'pending' ||
                  (approval == 'pending' && status != 'rejected'))
                matches = true;
            } else if (_selectedFilter == 'submitted') {
              // Submitted
              if (status == 'submitted' || approval == 'submitted')
                matches = true;
            } else if (_selectedFilter == 'completed') {
              if (status == 'completed') matches = true;
            } else if (_selectedFilter == 'rejected') {
              if (status == 'rejected' || approval == 'rejected')
                matches = true;
            }

            if (!matches) continue;
          }

          // Store row data with status for sorting
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

    // Sort: pending items first, then others
    rowData.sort((a, b) {
      if (a['isPending'] && !b['isPending']) return -1;
      if (!a['isPending'] && b['isPending']) return 1;
      return 0;
    });

    // Build DataRows from sorted data
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
            DataCell(_buildStatusBadge(activity)),
            DataCell(_buildApprovalBadge(activity)),
            DataCell(_buildActions(project, phase, activity)),
          ],
        ),
      );
    }
    return rows;
  }

  Widget _buildActions(
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
                  onTaskUpdated: _loadProjects,
                ),
              );
            },
          ),
        ] else if (activity.activityStatus.toLowerCase() == 'pending' &&
            activity.activityApprovalStatus.toLowerCase() == 'pending') ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppTheme.green600),
            tooltip: 'Accept Task',
            onPressed: () => _updateActivityStatus(
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
                _showRejectDialog(project.id, phase.phase.id, activity),
          ),
        ],
      ],
    );
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

      await ApiService().staffRespondToActivity(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
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
            child: const Text('Reject'),
          ),
        ],
      ),
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

  Widget _buildStatusBadge(StaffApqpActivityWrapper activity) {
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

    // Show managerReason in tooltip if NOT accepted/completed (e.g. rejected or pending with reason)
    // The requirement says: "manager reason display in status tooltip udpate"
    // Usually reasons are for rejections.
    if (activity.managerReason != null && activity.managerReason!.isNotEmpty) {
      return Tooltip(message: activity.managerReason!, child: badge);
    }

    return badge;
  }

  Widget _buildApprovalBadge(StaffApqpActivityWrapper activity) {
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
}
