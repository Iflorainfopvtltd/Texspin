import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';

import 'staff_audit_task_submission_dialog.dart';
import 'custom_text_input.dart';
import 'dart:developer' as developer;

class StaffAuditTasksDialog extends StatefulWidget {
  const StaffAuditTasksDialog({super.key});

  @override
  State<StaffAuditTasksDialog> createState() => _StaffAuditTasksDialogState();
}

class _StaffAuditTasksDialogState extends State<StaffAuditTasksDialog> {
  // ... existing code ...
  Future<void> _downloadFile(String fileName, String label) async {
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
              Expanded(child: Text('Downloading $label...')),
            ],
          ),
          backgroundColor: AppTheme.blue600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Construct full URL
      // If fileName is already a URL, use it. Otherwise append to base URL.
      final String fullUrl = fileName.startsWith('http')
          ? fileName
          : '${ApiService.baseUrl}/$fileName';

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
                  Expanded(child: Text('$label download started')),
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
            content: Text('Error downloading $label: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final ApiService _apiService = ApiService();
  List<AuditMain> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String? _currentStaffId;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      _currentStaffId = staffId;

      final response = await _apiService.getStaffAuditMains(staffId: staffId);
      List<dynamic> list = [];

      if (response.containsKey('audits')) {
        list = response['audits'] as List;
      } else if (response.containsKey('auditMains')) {
        list = response['auditMains'] as List;
      } else if (response.containsKey('data')) {
        list = response['data'] as List;
      } else {
        // Try finding first list value
        for (var val in response.values) {
          if (val is List) {
            list = val;
            break;
          }
        }
      }

      List<AuditMain> parsedTasks = list
          .map((item) => AuditMain.fromJson(item))
          .toList();

      // Sort by createdAt descending (newest first)
      parsedTasks.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      setState(() {
        _tasks = parsedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTaskResponse(
    String auditId,
    String status, {
    String? reason,
    String? questionId,
  }) async {
    try {
      if (questionId == null) {
        throw Exception("Question ID is required for this action");
      }

      final action = status == 'approved' ? 'approve' : 'reject';

      await _apiService.respondToAuditQuestion(
        auditId: auditId,
        questionId: questionId,
        action: action,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audit Question $status successfully')),
        );
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String auditId, [String? questionId]) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Audit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            CustomTextInput(
              label: 'Reason',
              controller: reasonController,
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
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleTaskResponse(
                  auditId,
                  'rejected',
                  reason: reasonController.text,
                  questionId: questionId,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
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
                label: 'Search',
                hint: 'Search by audit name or question...',
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Assigned', 'assigned'),
                const SizedBox(width: 8),
                _buildFilterChip('Revision', 'revision'),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'approved'),
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
                  'Audit Tasks',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _tasks.isEmpty
                  ? const Center(child: Text('No audit tasks found'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Audit Name')),
                            DataColumn(label: Text('Scheduled Date')),
                            DataColumn(label: Text('Assigned Question')),
                            DataColumn(label: Text('Status')),
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

  List<DataRow> _buildFlattenedRows() {
    final List<DataRow> rows = [];

    for (var task in _tasks) {
      if (task.auditQuestions == null ||
          task.auditQuestions!.isEmpty ||
          _currentStaffId == null) {
        continue;
      }

      final assignedQuestions = task.auditQuestions!.where((q) {
        return q['assignedTo'] == _currentStaffId;
      }).toList();

      for (var question in assignedQuestions) {
        final status = question['status'] ?? task.status;
        final questionText = question['question'] ?? '';
        final auditName = task.auditTemplate?['name'] ?? '';

        // Filter Logic
        if (_selectedFilter != 'all') {
          final filterStatus = _selectedFilter.toLowerCase();
          final currentStatus = status.toString().toLowerCase();

          if (filterStatus == 'approved' &&
              (currentStatus == 'accepted' || currentStatus == 'approved')) {
            // allow
          } else if (currentStatus != filterStatus) {
            continue;
          }
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!questionText.toLowerCase().contains(query) &&
              !auditName.toLowerCase().contains(query)) {
            continue;
          }
        }
        final isPending =
            status.toLowerCase() == 'pending' ||
            status.toLowerCase() == 'assigned';
        final isApproved =
            status.toLowerCase() == 'approved' ||
            status.toLowerCase() == 'accepted';
        final isRevision = status.toLowerCase() == 'revision';
        final isRejected = status.toLowerCase() == 'rejected';

        // Use _id (instance id) as requested by user
        final questionId = question['_id'] ?? question['questionId'];

        rows.add(
          DataRow(
            cells: [
              DataCell(Text(task.auditTemplate?['name'] ?? 'N/A')),
              DataCell(Text(_formatDate(task.date))),
              DataCell(
                SizedBox(
                  width: 500,
                  child: Text(question['question'] ?? 'Unknown Question'),
                ),
              ),
              DataCell(
                Tooltip(
                  message: (isRejected || isRevision)
                      ? (question['rejectionReason'] ??
                            question['reviewRejectionReason'] ??
                            '')
                      : '',
                  child: _buildStatusBadge(status),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Attachment Menu (Audit level for now)
                    _buildAttachmentMenu(task),

                    if (isApproved || isRevision) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.upload, color: AppTheme.blue600),
                        tooltip: isRevision
                            ? 'Submit Revision'
                            : 'Submit Audit',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                StaffAuditTaskSubmissionDialog(
                                  task: task,
                                  question: question,
                                  onSubmitted: _loadTasks,
                                ),
                          );
                        },
                      ),
                    ],
                    // Show accept/reject for Pending AND Assigned
                    if (isPending || status.toLowerCase() == 'assigned') ...[
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: AppTheme.green600,
                        ),
                        tooltip: 'Accept',
                        onPressed: () => _handleTaskResponse(
                          task.id,
                          'approved', // Or 'active', 'accepted'? strict 'approved' based on prev code
                          questionId: questionId,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppTheme.red500),
                        tooltip: 'Reject',
                        onPressed: () => _showRejectDialog(task.id, questionId),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
    return rows;
  }

  // Helper method removed (was _buildAssignedQuestions)

  Widget _buildAttachmentMenu(AuditMain task) {
    List<PopupMenuEntry<String>> menuItems = [];

    // Helper to add menu item
    void addMenuItem(String? file, String label, IconData icon) {
      if (file != null && file.isNotEmpty) {
        menuItems.add(
          PopupMenuItem<String>(
            value: file,
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
              ],
            ),
            onTap: () {
              // We need to delay the async call slightly to allow menu to close
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _downloadFile(file, label),
              );
            },
          ),
        );
      }
    }

    addMenuItem(task.previousDoc, 'Previous Doc', Icons.history);
    addMenuItem(task.otherDoc, 'Other Doc', Icons.description);
    addMenuItem(task.auditMethodology, 'Methodology', Icons.library_books);
    addMenuItem(task.actionEvidence, 'Action Evidence', Icons.verified);

    if (task.otherDocs != null && task.otherDocs!.isNotEmpty) {
      for (int i = 0; i < task.otherDocs!.length; i++) {
        addMenuItem(
          task.otherDocs![i],
          'Attachment ${i + 1}',
          Icons.attach_file,
        );
      }
    }

    if (menuItems.isEmpty) {
      // Return empty container if no attachments
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'View Attachments',
      icon: const Icon(Icons.download_for_offline, color: AppTheme.primary),
      itemBuilder: (BuildContext context) => menuItems,
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
      case 'completed':
      case 'assigned': // Added logic for assigned
        color = AppTheme.green500;
        break;
      case 'rejected':
        color = AppTheme.red500;
        break;
      case 'pending':
        color = AppTheme.yellow500;
        break;
      case 'revision':
        color = AppTheme.blue500;
        break;
      default:
        color = AppTheme.blue500;
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
