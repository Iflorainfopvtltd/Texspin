import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/single_select_dropdown.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

class AssignQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> audit;
  final Map<String, dynamic> question;
  final bool isReassign;
  final VoidCallback onAssignmentChanged;

  const AssignQuestionDialog({
    super.key,
    required this.audit,
    required this.question,
    this.isReassign = false,
    required this.onAssignmentChanged,
  });

  @override
  State<AssignQuestionDialog> createState() => _AssignQuestionDialogState();
}

class _AssignQuestionDialogState extends State<AssignQuestionDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();

  List<Staff> _staff = [];
  String? _selectedStaffId;
  bool _isLoading = false;
  bool _isSubmitting = false;
  DateTime? _selectedDeadline;
  String? _reminderError;

  int _calculateDaysFromNow(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(
      DateTime(now.year, now.month, now.day),
    );
    return difference.inDays;
  }

  void _validateReminder(String value) {
    setState(() {
      if (value.isEmpty) {
        _reminderError = null;
        return;
      }

      final n = int.tryParse(value);
      if (n == null || n < 0) {
        _reminderError = 'Enter a valid non-negative number';
        return;
      }

      if (_selectedDeadline != null) {
        final assignedDays = _calculateDaysFromNow(_selectedDeadline!);
        if (n > assignedDays) {
          _reminderError = 'Reminder ($n) too large. Max: $assignedDays';
          return;
        }
      }

      _reminderError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchStaff();
    _initializeData();
  }

  void _initializeData() {
    if (widget.isReassign) {
      // Pre-fill data for reassignment
      _selectedStaffId = widget.question['assignedTo'];
      if (widget.question['deadline'] != null) {
        _selectedDeadline = DateTime.parse(widget.question['deadline']);
        _deadlineController.text = _selectedDeadline!.toString().split(' ')[0];
      }

      final reminderDays = widget.question['reminderDays'];
      if (reminderDays != null) {
        if (reminderDays is List) {
          if (reminderDays.isNotEmpty) {
            _reminderController.text = reminderDays.first.toString();
          }
        } else {
          _reminderController.text = reminderDays.toString();
        }
      }
    }
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = (response['staff'] as List)
              .map((staffJson) => Staff.fromJson(staffJson))
              .where((staff) => staff.status.toLowerCase() == 'active')
              .toList();
        });
      }
    } catch (e) {
      developer.log('Error fetching staff: $e', name: 'AssignQuestionDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        // Set time to noon (12:00) to avoid timezone/date shifting issues when storing as UTC
        _selectedDeadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          12,
          0,
          0,
        );
        _deadlineController.text = picked.toString().split(' ')[0];

        // Re-validate reminder when date changes
        if (_reminderController.text.isNotEmpty) {
          _validateReminder(_reminderController.text);
        }
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedStaffId == null || _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select staff member and deadline'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_reminderError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix errors before assigning'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auditId = widget.audit['_id'] ?? widget.audit['id'];
      final questionId = widget.question['_id'] ?? widget.question['id'];

      await _apiService.assignQuestionToStaff(
        auditId: auditId,
        questionId: questionId,
        assignedTo: _selectedStaffId!,
        deadline: _selectedDeadline!.toIso8601String(),
        reminderDays: int.tryParse(_reminderController.text),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isReassign
                  ? 'Question reassigned successfully!'
                  : 'Question assigned successfully!',
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onAssignmentChanged();
      }
    } catch (e) {
      developer.log(
        'Error assigning question: $e',
        name: 'AssignQuestionDialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.isReassign ? 'reassigning' : 'assigning'} question: $e',
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isMobile),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(child: _buildContent(isMobile)),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.blue100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.isReassign ? Icons.swap_horiz : Icons.person_add,
              color: AppTheme.blue600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isReassign ? 'Reassign Question' : 'Assign Question',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  widget.question['question'] ?? 'Question',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: AppTheme.gray600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: AppTheme.gray600,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Selection
          SingleSelectDropdown<Staff>(
            label: 'Select Staff Member',
            isRequired: true,
            options: _staff,
            selectedId: _selectedStaffId,
            onSelectionChanged: (staffId) {
              setState(() {
                _selectedStaffId = staffId;
              });
            },
            getDisplayText: (staff) => staff.fullName,
            getSubText: (staff) =>
                '${staff.designation ?? ''} - ${staff.department ?? ''}',
            getId: (staff) => staff.id,
            hintText: 'Choose a staff member',
          ),

          const SizedBox(height: 24),

          // Deadline Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deadline *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  hintText: 'Select deadline date',
                  filled: true,
                  fillColor: AppTheme.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.ring, width: 2),
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: AppTheme.gray600,
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              if (_selectedDeadline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This task has assigned ${_calculateDaysFromNow(_selectedDeadline!)} days',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Task Reminder
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Reminder (Days)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reminderController,
                keyboardType: TextInputType.number,
                onChanged: _validateReminder,
                decoration: InputDecoration(
                  hintText: 'e.g. 4',
                  errorText: _reminderError,
                  filled: true,
                  fillColor: AppTheme.inputBackground,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    borderSide: BorderSide(color: AppTheme.ring, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            variant: ButtonVariant.outline,
            size: isMobile ? ButtonSize.sm : ButtonSize.lg,
          ),
          CustomButton(
            text: _isSubmitting
                ? (widget.isReassign ? 'Reassigning...' : 'Assigning...')
                : (widget.isReassign ? 'Reassign' : 'Assign'),
            onPressed:
                _isSubmitting ||
                    _selectedStaffId == null ||
                    _selectedDeadline == null
                ? null
                : _submitAssignment,
            size: isMobile ? ButtonSize.sm : ButtonSize.lg,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
