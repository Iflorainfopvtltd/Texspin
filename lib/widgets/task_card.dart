import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';
import 'dart:developer' as developer;

class TaskCard extends StatelessWidget {
  // ... existing code ...
  Future<void> _downloadTaskFile(BuildContext context) async {
    try {
      String? fileUrl;
      String? fileName;

      // Check if task has downloadUrl (new structure)
      if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty) {
        fileUrl = task.downloadUrl;
        fileName = task.fileName ?? 'task_file';
      }
      // Fallback to attachments (old structure)
      else if (task.attachments != null && task.attachments!.isNotEmpty) {
        final attachment = task.attachments!.first;
        fileUrl = attachment['fileUrl'] ?? '';
        fileName = attachment['fileName'] ?? 'task_file';
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

      // Show downloading message
      if (context.mounted) {
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
      final Uri url = Uri.parse(fullUrl);

      developer.log('Downloading file from: $fullUrl');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (context.mounted) {
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
      if (context.mounted) {
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

  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh;
  final VoidCallback? onReminder;
  final bool showActions;
  final bool isCompact;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
    this.onReminder,
    this.showActions = true,
    this.isCompact = false,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.green500;
      case 'approved':
        return AppTheme.green500;
      case 'in progress':
        return AppTheme.blue500;
      case 'submitted':
        return AppTheme.blue500;
      case 'rejected':
        return AppTheme.red500;
      case 'pending':
        return AppTheme.yellow500;
      default:
        return AppTheme.yellow500;
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

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: Text('Are you sure you want to approve "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Approve',
            onPressed: () {
              Navigator.pop(context);
              _reviewTask(context, 'completed');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
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
                context,
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

  void _showReassignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          ReassignIndividualTaskDialog(task: task, onReassigned: onRefresh),
    );
  }

  Future<void> _reviewTask(
    BuildContext context,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final apiService = ApiService();
      final response = await apiService.reviewTask(
        taskId: task.id,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (context.mounted) {
        // Use API response message if available, otherwise use default
        String successMessage;
        if (response['message'] != null) {
          successMessage = response['message'].toString();
        } else {
          successMessage = status == 'completed'
              ? 'Task approved successfully'
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
        onRefresh?.call(); // Refresh the task list
      }
    } catch (e) {
      developer.log('Error reviewing task: $e');
      if (context.mounted) {
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

  Widget _buildMobileActions(BuildContext context) {
    final status = task.status.toLowerCase();

    if (status == 'submitted') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Download (if available)
            if (task.downloadUrl != null && task.downloadUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Download File',
                    onPressed: () => _downloadTaskFile(context),
                    variant: ButtonVariant.outline,
                    size: ButtonSize.sm,
                    icon: const Icon(Icons.download, size: 16),
                    isFullWidth: true,
                  ),
                ),
              ),
            // Second row: Approve and Reject
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    onPressed: () => _showApproveDialog(context),
                    variant: ButtonVariant.default_,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.primaryForeground,
                    ),
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () => _showRejectDialog(context),
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.primaryForeground,
                    ),
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (status == 'rejected') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Reassign',
                onPressed: () => _showReassignDialog(context),
                variant: ButtonVariant.outline,
                size: ButtonSize.sm,
                icon: const Icon(Icons.group, size: 16),
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                text: 'Delete',
                onPressed: onDelete,
                variant: ButtonVariant.destructive,
                size: ButtonSize.sm,
                icon: const Icon(
                  Icons.delete,
                  size: 16,
                  color: AppTheme.primaryForeground,
                ),
                isFullWidth: true,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Download (if available) and Reminder
            if ((task.downloadUrl != null && task.downloadUrl!.isNotEmpty) ||
                (task.attachments != null && task.attachments!.isNotEmpty) ||
                onReminder != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if ((task.downloadUrl != null &&
                            task.downloadUrl!.isNotEmpty) ||
                        (task.attachments != null &&
                            task.attachments!.isNotEmpty))
                      Expanded(
                        child: CustomButton(
                          text: 'Download',
                          onPressed: () => _downloadTaskFile(context),
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.download, size: 16),
                          isFullWidth: true,
                        ),
                      ),
                    if (((task.downloadUrl != null &&
                                task.downloadUrl!.isNotEmpty) ||
                            (task.attachments != null &&
                                task.attachments!.isNotEmpty)) &&
                        onReminder != null)
                      const SizedBox(width: 8),
                    if (onReminder != null)
                      Expanded(
                        child: CustomButton(
                          text: 'Remind',
                          onPressed: onReminder,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: const Icon(Icons.send, size: 16),
                          isFullWidth: true,
                        ),
                      ),
                  ],
                ),
              ),
            // Second row: Edit and Delete
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Edit',
                    onPressed: onEdit,
                    variant: ButtonVariant.outline,
                    size: ButtonSize.sm,
                    icon: const Icon(Icons.edit, size: 16),
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Delete',
                    onPressed: onDelete,
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                      color: AppTheme.primaryForeground,
                    ),
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            if ((task.downloadUrl != null && task.downloadUrl!.isNotEmpty) ||
                (task.attachments != null && task.attachments!.isNotEmpty))
              Expanded(
                child: CustomButton(
                  text: 'Download File',
                  onPressed: () => _downloadTaskFile(context),
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  icon: const Icon(Icons.download, size: 16),
                  isFullWidth: true,
                ),
              ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedStaffName =
        '${task.assignedStaff['firstName'] ?? ''} ${task.assignedStaff['lastName'] ?? ''}'
            .trim();

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 0,
        vertical: isCompact ? 4 : 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200, width: 1),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.name,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
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
                    color: _getStatusColor(task.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),

            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray600,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Info Row
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppTheme.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedStaffName,
                    style: TextStyle(fontSize: 13, color: AppTheme.gray700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  task.deadline != null
                      ? _formatDate(task.deadline!)
                      : (task.isRecurringActive == true ? 'Recurring' : 'N/A'),
                  style: TextStyle(fontSize: 13, color: AppTheme.gray700),
                ),
              ],
            ),

            if (showActions) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Actions Section with proper spacing
              _buildMobileActions(context),
            ],
          ],
        ),
      ),
    );
  }
}

class ReassignIndividualTaskDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onReassigned;

  const ReassignIndividualTaskDialog({
    super.key,
    required this.task,
    this.onReassigned,
  });

  @override
  State<ReassignIndividualTaskDialog> createState() =>
      _ReassignIndividualTaskDialogState();
}

class _ReassignIndividualTaskDialogState
    extends State<ReassignIndividualTaskDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reminderDaysController = TextEditingController();
  DateTime? _deadline;
  String? _selectedStaffId;
  List<Staff> _staff = [];
  bool _isLoading = false;
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.task.deadline != null) {
        _deadline = DateTime.parse(widget.task.deadline!);
      }
      if (widget.task.reminderDays != null &&
          widget.task.reminderDays!.isNotEmpty) {
        _reminderDaysController.text = widget.task.reminderDays!.join(', ');
      } else if (widget.task.frequency != null) {
        _reminderDaysController.text = widget.task.frequency.toString();
      }
      if (widget.task.assignedStaff.isNotEmpty) {
        _selectedStaffId =
            widget.task.assignedStaff['id'] ??
            widget.task.assignedStaff['_id'] ??
            widget.task.assignedStaff['staffId'];
      }
    } catch (e) {
      developer.log('Error parsing task data: $e');
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _reminderDaysController.dispose();
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

  Future<void> _reassignTask() async {
    if (_deadline == null && widget.task.isRecurringActive != true) {
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
      final deadlineStr = _deadline?.toIso8601String();
      int? reminderDays;
      if (_reminderDaysController.text.isNotEmpty) {
        reminderDays = int.tryParse(_reminderDaysController.text.trim());
      }

      await _apiService.reassignTaskStaff(
        taskId: widget.task.id,
        assignedStaffId: _selectedStaffId!,
        deadline: deadlineStr,
        reminderDays: reminderDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task reassigned successfully'),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Row(
            children: [
              Icon(Icons.person_outline, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reassign Individual Task: ${widget.task.name}',
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
        if (!isMobile) const SizedBox(height: 20),

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
        if (widget.task.isRecurringActive == true)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.blue50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.blue100),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat, color: AppTheme.blue600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blue900,
                        ),
                      ),
                      Text(
                        'This task repeats automatically. Deadline is set by the schedule.',
                        style: TextStyle(fontSize: 12, color: AppTheme.blue800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
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
        const SizedBox(height: 16),

        // Task Reminder Days
        CustomTextInput(
          label: 'Task Reminder (Days)',
          hint: 'e.g. 4',
          controller: _reminderDaysController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final parts = value.split(',');
              for (final part in parts) {
                final n = int.tryParse(part.trim());
                if (n == null || n < 0) {
                  return 'Enter valid numbers (0 or greater)';
                }
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 24),

        // Action Buttons
        if (!isMobile)
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
          )
        else
          CustomButton(
            text: _isLoading ? 'Reassigning...' : 'Reassign Task',
            onPressed: _isLoading ? null : _reassignTask,
          ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reassign: ${widget.task.name}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}
