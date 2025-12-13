import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import 'dart:developer' as developer;

class ApqpTaskManagementDialog extends StatefulWidget {
  const ApqpTaskManagementDialog({super.key});

  @override
  State<ApqpTaskManagementDialog> createState() => _ApqpTaskManagementDialogState();
}

class _ApqpTaskManagementDialogState extends State<ApqpTaskManagementDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _approvals = [];
  List<Map<String, dynamic>> _filteredApprovals = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      developer.log('Error loading APQP tasks: $e', name: 'ApqpTaskManagement');
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
        final status = (approval['status']?.toString() ?? 'pending').toLowerCase();
        switch (statusFilter) {
          case 'pending':
            return status == 'pending' || status == 'submitted';
          case 'approved':
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
        final activityName = (approval['activityName']?.toString() ?? '').toLowerCase();
        final projectName = (approval['projectName']?.toString() ?? '').toLowerCase();
        final phaseName = (approval['phaseName']?.toString() ?? '').toLowerCase();
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
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.gray300,
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
      final String fullUrl = ApiService.baseUrl + fileUrl;
      final Uri url = Uri.parse(fullUrl);
      
      developer.log('Downloading file from: $fullUrl');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
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
              _updateTaskStatus(approval, 'reject', rejectionReason: reasonController.text.trim());
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
      final response = await _apiService.sendApqpTaskReminder(projectId: projectId);
      
      if (mounted) {
        final successMessage = response['message']?.toString() ?? 'Reminder sent successfully';
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
                Expanded(child: Text('Error sending reminder: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(Map<String, dynamic> approval, String action, {String? rejectionReason}) async {
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
        final successMessage = response['message']?.toString() ?? 
          (action == 'approve' ? 'Task approved successfully' : 'Task rejected successfully');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: action == 'approve' ? AppTheme.green500 : AppTheme.red500,
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
    final activityName = approval['activityName']?.toString() ?? 'Unknown Activity';
    final projectName = approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final status = approval['status']?.toString() ?? 'pending';
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
              style: const TextStyle(
                color: AppTheme.gray600,
              ),
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
              style: const TextStyle(
                color: AppTheme.gray600,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(submittedDate),
            style: const TextStyle(
              color: AppTheme.gray700,
            ),
          ),
        ),
        DataCell(
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
              if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'submitted') ...[
                // Reminder button (only for pending tasks)
                if (status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(Icons.send_outlined, color: AppTheme.yellow500),
                    onPressed: () => _sendReminder(approval),
                    tooltip: 'Send Reminder',
                  ),
                // Download button (if file is available)
                if (fileUrl != null && fileUrl.isNotEmpty && fileName != null)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadFile(fileUrl, fileName),
                    tooltip: 'Download File',
                  ),
                // Approve button
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.green600),
                  onPressed: () => _showApproveDialog(approval),
                  tooltip: 'Approve',
                ),
                // Reject button
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.red500),
                  onPressed: () => _showRejectDialog(approval),
                  tooltip: 'Reject',
                ),
              ] 
              else ...[
                // For approved/rejected tasks: show download only
                if (fileUrl != null && fileUrl.isNotEmpty && fileName != null)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadFile(fileUrl, fileName),
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
                // Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMobile ? 16 : 20),
                      topRight: Radius.circular(isMobile ? 16 : 20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: isMobile ? 24 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'APQP Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppTheme.red500,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading APQP tasks',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: TextStyle(color: AppTheme.gray600),
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
                        )
                      : Column(
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
                                        _buildFilterChip('Approved', 'approved'),
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
                                            _approvals.isEmpty
                                                ? Icons.task_alt
                                                : Icons.search_off,
                                            size: 64,
                                            color: AppTheme.gray300,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _approvals.isEmpty
                                                ? 'No APQP tasks yet'
                                                : 'No tasks found',
                                            style: TextStyle(
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
                                            headingRowColor: WidgetStateProperty.all(AppTheme.blue50),
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
                                                  'Submitted Date',
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
                                            rows: _filteredApprovals.map((approval) => _buildTaskDataRow(approval)).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
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
}