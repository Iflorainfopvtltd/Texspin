import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/file_download_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import 'dart:developer' as developer;

class DepartmentTaskManagementDialog extends StatefulWidget {
  const DepartmentTaskManagementDialog({super.key});

  @override
  State<DepartmentTaskManagementDialog> createState() =>
      _DepartmentTaskManagementDialogState();
}

class _DepartmentTaskManagementDialogState
    extends State<DepartmentTaskManagementDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<DepartmentTask> _tasks = [];
  List<DepartmentTask> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDepartmentTasks();
      if (response['tasks'] != null) {
        setState(() {
          _tasks = (response['tasks'] as List)
              .map((task) => DepartmentTask.fromJson(task))
              .toList();
          _filteredTasks = _tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error loading department tasks: $e',
        name: 'DepartmentTaskManagement',
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
    var filtered = _tasks;

    // Apply status filter
    if (statusFilter != 'all') {
      filtered = filtered.where((task) {
        final status = task.status.toLowerCase();
        switch (statusFilter) {
          case 'pending':
            return status == 'pending';
          case 'submitted':
            return status == 'submitted';
          case 'accepted':
            return status == 'completed' || status == 'accepted';
          case 'rejected':
            return status == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Apply text filter
    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        final taskName = task.name.toLowerCase();
        final staffName =
            '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
                .toLowerCase();
        final searchLower = query.toLowerCase();
        return taskName.contains(searchLower) ||
            staffName.contains(searchLower);
      }).toList();
    }

    _filteredTasks = filtered;
  }

  void _showAddEditTaskDialog({DepartmentTask? task}) {
    showDialog(
      context: context,
      builder: (context) => AddEditDepartmentTaskDialog(
        task: task,
        onSaved: () {
          Navigator.of(context).pop();
          _loadTasks();
        },
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department Task'),
        content: const Text(
          'Are you sure you want to delete this department task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteDepartmentTask(taskId: taskId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Department task deleted successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
          _loadTasks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: AppTheme.red500,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.green500;
      case 'accepted':
        return AppTheme.green500;
      case 'submitted':
      case 'revision':
        return AppTheme.blue500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
    }
  }

  void _showAcceptDialog(DepartmentTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Task'),
        content: Text('Are you sure you want to accept "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Accept',
            onPressed: () {
              Navigator.pop(context);
              _reviewTask(task.id, 'completed');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(DepartmentTask task) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${task.name}"?'),
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
              _reviewTask(
                task.id,
                'rejected',
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

  void _showReassignDialog(DepartmentTask task) {
    showDialog(
      context: context,
      builder: (context) =>
          ReassignDepartmentTaskDialog(task: task, onReassigned: _loadTasks),
    );
  }

  Future<void> _sendReminder(String taskId) async {
    try {
      final response = await _apiService.sendDepartmentTaskReminder(
        taskId: taskId,
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

  Future<void> _reviewTask(
    String taskId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final response = await _apiService.reviewDepartmentTask(
        taskId: taskId,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        // Use API response message if available, otherwise use default
        String successMessage;
        if (response['message'] != null) {
          successMessage = response['message'].toString();
        } else {
          successMessage = status == 'completed'
              ? 'Task accepted successfully'
              : 'Task rejected successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: status == 'completed'
                ? AppTheme.green500
                : AppTheme.red500,
          ),
        );
        _loadTasks(); // Refresh the task list
      }
    } catch (e) {
      developer.log('Error reviewing task: $e');
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _downloadTaskFile(DepartmentTask task) async {
    try {
      String? fileUrl;
      String? fileName;

      // Check if task has downloadUrl (new structure)
      if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
        fileUrl = task.downloadUrl;
        fileName = task.fileName ?? 'dept_task_file';
      }
      // Fallback to attachments (old structure)
      else if (task.attachments != null && task.attachments!.isNotEmpty) {
        final attachment = task.attachments!.first;
        fileUrl = attachment['fileUrl'] ?? '';
        fileName = attachment['fileName'] ?? 'dept_task_file';
      }

      if (fileUrl == null || fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No files to download'),
            backgroundColor: AppTheme.yellow500,
          ),
        );
        return;
      }

      // Check storage permission first
      if (!await FileDownloadService.hasStoragePermission()) {
        final granted = await FileDownloadService.requestStoragePermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Storage permission is required to download files',
                ),
                backgroundColor: AppTheme.red500,
              ),
            );
          }
          return;
        }
      }

      // Show downloading message
      if (mounted) {
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
      }

      // Construct full URL using ApiService baseUrl
      final String fullUrl = ApiService.baseUrl + fileUrl;

      // Download the file using our custom service
      final filePath = await FileDownloadService.downloadFile(
        url: fullUrl,
        fileName: fileName!,
        onProgress: (received, total) {
          developer.log(
            'Download progress: ${(received / total * 100).toStringAsFixed(1)}%',
          );
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$fileName downloaded successfully'),
                      Text(
                        'Saved to: ${filePath.split('/').last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => FileDownloadService.openFile(filePath),
            ),
          ),
        );
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
                Expanded(
                  child: Text('Error downloading file: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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

  DataRow _buildTaskDataRow(DepartmentTask task) {
    final assignedStaffName =
        '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
            .trim();

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              task.name,
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
            width: 150,
            child: Text(
              task.description,
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
              assignedStaffName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(task.deadline),
            style: const TextStyle(color: AppTheme.gray700),
          ),
        ),
        DataCell(
          (task.status.toLowerCase() == 'rejected' ||
                  task.status.toLowerCase() == 'revision')
              ? Tooltip(
                  message: task.rejectionReason ?? 'No reason provided',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        task.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(task.status),
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // For submitted tasks: show download, accept and reject
              if (task.status.toLowerCase() == 'submitted') ...[
                // Download button (if downloadUrl is available)
                if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadTaskFile(task),
                    tooltip: 'Download File',
                  ),
                // Accept button
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.green600,
                  ),
                  onPressed: () => _showAcceptDialog(task),
                  tooltip: 'Accept',
                ),
                // Reject button
                IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppTheme.red500,
                  ),
                  onPressed: () => _showRejectDialog(task),
                  tooltip: 'Reject',
                ),
              ]
              // For rejected tasks: show reassign button
              else if (task.status.toLowerCase() == 'rejected') ...[
                IconButton(
                  icon: const Icon(Icons.person_add, color: AppTheme.blue600),
                  onPressed: () => _showReassignDialog(task),
                  tooltip: 'Reassign',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.red500,
                  ),
                  onPressed: () => _deleteTask(task.id),
                  tooltip: 'Delete',
                ),
              ] else ...[
                // For other tasks: show download (if available), edit and delete
                // Download button (if downloadUrl is available or has attachments)
                if ((task.downloadUrl != null &&
                        task.downloadUrl!.isNotEmpty) ||
                    (task.attachments != null && task.attachments!.isNotEmpty))
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadTaskFile(task),
                    tooltip: 'Download File',
                  ),
                // Reminder button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.send_outlined,
                      color: AppTheme.yellow500,
                    ),
                    onPressed: () => _sendReminder(task.id),
                    tooltip: 'Send Reminder',
                  ),
                // Edit button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.blue600,
                    ),
                    onPressed: () => _showAddEditTaskDialog(task: task),
                    tooltip: 'Edit',
                  ),
                // Delete button (only for pending tasks)
                if (task.status.toLowerCase() == 'pending')
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.red500,
                    ),
                    onPressed: () => _deleteTask(task.id),
                    tooltip: 'Delete',
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
                // // Header
                // Container(
                //   padding: EdgeInsets.all(isMobile ? 16 : 24),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [
                //         AppTheme.primary,
                //         AppTheme.primary.withOpacity(0.8),
                //       ],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //     borderRadius: BorderRadius.only(
                //       topLeft: Radius.circular(isMobile ? 16 : 20),
                //       topRight: Radius.circular(isMobile ? 16 : 20),
                //     ),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(
                //         Icons.business,
                //         color: Colors.white,
                //         size: isMobile ? 24 : 28,
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: Text(
                //           'Department Tasks',
                //           style: TextStyle(
                //             color: Colors.white,
                //             fontSize: isMobile ? 20 : 24,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ),
                //       IconButton(
                //         icon: const Icon(Icons.close, color: Colors.white),
                //         onPressed: () => Navigator.of(context).pop(),
                //       ),
                //     ],
                //   ),
                // ),

                // // Content
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
                                  'Error loading department tasks',
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
                                  onPressed: _loadTasks,
                                  variant: ButtonVariant.default_,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Search Bar
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: Column(
                                children: [
                                  CustomTextInput(
                                    controller: _searchController,
                                    hint:
                                        'Search by task name or staff name...',
                                    onChanged: _filterTasks,
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                            ),
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
                                        _buildFilterChip(
                                          'Submitted',
                                          'submitted',
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          'Accepted',
                                          'accepted',
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          'Rejected',
                                          'rejected',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Task List
                            Expanded(
                              child: _filteredTasks.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _tasks.isEmpty
                                                ? Icons.business
                                                : Icons.search_off,
                                            size: 64,
                                            color: AppTheme.gray300,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _tasks.isEmpty
                                                ? 'No department tasks yet'
                                                : 'No tasks found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                          if (_tasks.isEmpty) ...[
                                            const SizedBox(height: 24),
                                            CustomButton(
                                              text: 'Add First Department Task',
                                              onPressed: () =>
                                                  _showAddEditTaskDialog(),
                                              icon: const Icon(
                                                Icons.add,
                                                size: 20,
                                              ),
                                            ),
                                          ],
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.gray200,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columnSpacing: isMobile ? 16 : 16,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                  AppTheme.blue50,
                                                ),
                                            dataRowColor:
                                                WidgetStateProperty.all(
                                                  Colors.white,
                                                ),
                                            columns: const [
                                              DataColumn(
                                                label: Text(
                                                  'Task Name',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Description',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Assigned To',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Deadline',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Status',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Actions',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            rows: _filteredTasks
                                                .map(
                                                  (task) =>
                                                      _buildTaskDataRow(task),
                                                )
                                                .toList(),
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
            // Floating Action Button
            Positioned(
              right: isMobile ? 16 : 24,
              bottom: isMobile ? 16 : 24,
              child: FloatingActionButton(
                onPressed: () => _showAddEditTaskDialog(),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditDepartmentTaskDialog extends StatefulWidget {
  final DepartmentTask? task;
  final VoidCallback onSaved;

  const AddEditDepartmentTaskDialog({
    super.key,
    this.task,
    required this.onSaved,
  });

  @override
  State<AddEditDepartmentTaskDialog> createState() =>
      _AddEditDepartmentTaskDialogState();
}

class _AddEditDepartmentTaskDialogState
    extends State<AddEditDepartmentTaskDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _descriptionController.text = widget.task!.description;
      _selectedStaffId = widget.task!.assignedStaff['_id'];
      try {
        _deadline = DateTime.parse(widget.task!.deadline);
      } catch (e) {
        developer.log('Error parsing deadline: $e');
      }
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = (response['staff'] as List)
              .map((s) => Staff.fromJson(s))
              .toList();
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      developer.log('Error loading staff: $e');
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deadlineStr = _deadline!.toIso8601String().split(
        'T',
      )[0]; // Format as YYYY-MM-DD

      if (widget.task == null) {
        await _apiService.createDepartmentTask(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadlineStr,
          assignedStaffId: _selectedStaffId!,
        );
      } else {
        // Note: Update functionality would need to be implemented in the API
        throw Exception('Editing department tasks is not yet supported');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null
                  ? 'Department task created successfully'
                  : 'Department task updated successfully',
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.task == null
                            ? 'Add Department Task'
                            : 'Edit Department Task',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomTextInput(
                  label: 'Task Name',
                  hint: 'Enter department task name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter task name';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                CustomTextInput(
                  label: 'Description',
                  hint: 'Enter task description',
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deadline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isLoading ? null : _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _deadline != null
                                    ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                    : 'Select deadline',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _deadline != null
                                      ? AppTheme.foreground
                                      : AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.mutedForeground,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingStaff
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : SingleSelectDropdown<Staff>(
                        label: 'Assign to Staff',
                        isRequired: true,
                        options: _staff,
                        selectedId: _selectedStaffId,
                        onSelectionChanged: (value) {
                          setState(() => _selectedStaffId = value);
                        },
                        getDisplayText: (staff) => staff.fullName,
                        getSubText: (staff) => staff.designation ?? staff.role,
                        getId: (staff) => staff.id,
                        hintText: 'Select staff member',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a staff member';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: _isLoading
                          ? 'Saving...'
                          : (widget.task == null ? 'Create' : 'Update'),
                      onPressed: _isLoading ? null : _saveTask,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReassignDepartmentTaskDialog extends StatefulWidget {
  final DepartmentTask task;
  final VoidCallback? onReassigned;

  const ReassignDepartmentTaskDialog({
    super.key,
    required this.task,
    this.onReassigned,
  });

  @override
  State<ReassignDepartmentTaskDialog> createState() =>
      _ReassignDepartmentTaskDialogState();
}

class _ReassignDepartmentTaskDialogState
    extends State<ReassignDepartmentTaskDialog> {
  final ApiService _apiService = ApiService();
  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    try {
      _deadline = DateTime.parse(widget.task.deadline);
    } catch (e) {
      developer.log('Error parsing deadline: $e');
    }
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = (response['staff'] as List)
              .map((s) => Staff.fromJson(s))
              .toList();
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      developer.log('Error loading staff: $e');
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _reassignTask() async {
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deadlineStr = _deadline!.toIso8601String().split(
        'T',
      )[0]; // Format as YYYY-MM-DD

      await _apiService.reassignDepartmentTask(
        taskId: widget.task.id,
        assignedStaffId: _selectedStaffId!,
        deadline: deadlineStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department task reassigned successfully'),
            backgroundColor: AppTheme.green500,
          ),
        );
        Navigator.of(context).pop();
        widget.onReassigned?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reassign Department Task: ${widget.task.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Staff Selection
            _isLoadingStaff
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SingleSelectDropdown<Staff>(
                    label: 'Reassign to Staff',
                    isRequired: true,
                    options: _staff,
                    selectedId: _selectedStaffId,
                    onSelectionChanged: (value) {
                      setState(() => _selectedStaffId = value);
                    },
                    getDisplayText: (staff) => staff.fullName,
                    getSubText: (staff) => staff.designation ?? staff.role,
                    getId: (staff) => staff.id,
                    hintText: 'Select staff member',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a staff member';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
            const SizedBox(height: 16),

            // Deadline Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Deadline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _deadline != null
                                ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                : 'Select new deadline',
                            style: TextStyle(
                              fontSize: 16,
                              color: _deadline != null
                                  ? AppTheme.foreground
                                  : AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.mutedForeground,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: _isLoading ? 'Reassigning...' : 'Reassign Task',
                  onPressed: _isLoading ? null : _reassignTask,
                ),
              ],
            ),
          ],
        ),
      ),
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
        const Icon(Icons.business, color: AppTheme.gray600, size: 24),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Department Tasks',
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
