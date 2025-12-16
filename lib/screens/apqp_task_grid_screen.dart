import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import 'dart:developer' as developer;

class ApqpTaskGridScreen extends StatefulWidget {
  const ApqpTaskGridScreen({super.key});

  @override
  State<ApqpTaskGridScreen> createState() => _ApqpTaskGridScreenState();
}

class _ApqpTaskGridScreenState extends State<ApqpTaskGridScreen> {
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
      developer.log('Error loading APQP tasks: $e', name: 'ApqpTaskGrid');
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

  Widget _buildApqpTaskCard(Map<String, dynamic> approval) {
    final activityName = approval['activityName']?.toString() ?? 'Unknown Activity';
    final projectName = approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final status = approval['status']?.toString() ?? 'pending';
    final submittedDate = approval['submittedDate']?.toString();
    final fileUrl = approval['fileUrl']?.toString();
    final fileName = approval['fileName']?.toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 16,
                  color: AppTheme.primary,
                ),
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
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
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
                Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            // Actions Row
            Row(
              children: [
                // For pending/submitted tasks: show reminder, download, approve and reject
                if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'submitted') ...[
                  // Reminder button (only for pending tasks)
                  if (status.toLowerCase() == 'pending')
                    Expanded(
                      child: CustomButton(
                        text: 'Remind',
                        onPressed: () => _sendReminder(approval),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.send, size: 16),
                      ),
                    ),
                  if (status.toLowerCase() == 'pending')
                    const SizedBox(width: 8),
                  // Download button (if file is available)
                  if (fileUrl != null && fileUrl.isNotEmpty && fileName != null)
                    Expanded(
                      child: CustomButton(
                        text: 'Download',
                        onPressed: () => _downloadFile(fileUrl, fileName),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.download, size: 16),
                      ),
                    ),
                  if (fileUrl != null && fileUrl.isNotEmpty && fileName != null)
                    const SizedBox(width: 8),
                  // Approve button
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _showApproveDialog(approval),
                      variant: ButtonVariant.default_,
                      size: ButtonSize.sm,
                      icon: const Icon(Icons.check, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reject button
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () => _showRejectDialog(approval),
                      variant: ButtonVariant.destructive,
                      size: ButtonSize.sm,
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ] 
                else ...[
                  // For approved/rejected tasks: show download only
                  if (fileUrl != null && fileUrl.isNotEmpty && fileName != null)
                    Expanded(
                      child: CustomButton(
                        text: 'Download',
                        onPressed: () => _downloadFile(fileUrl, fileName),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        icon: const Icon(Icons.download, size: 16),
                      ),
                    ),
                ],
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
        title: const Text('APQP Tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.red500),
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
                            _buildFilterChip('Approved', 'approved'),
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
            ),
    );
  }
}