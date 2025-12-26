import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/multi_select_dropdown.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class AssignAuditStaffDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final VoidCallback? onAssigned;

  const AssignAuditStaffDialog({
    super.key,
    required this.question,
    this.onAssigned,
  });

  @override
  State<AssignAuditStaffDialog> createState() => _AssignAuditStaffDialogState();
}

class _AssignAuditStaffDialogState extends State<AssignAuditStaffDialog> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _staff = [];
  List<String> _selectedStaff = [];
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = List<Map<String, dynamic>>.from(response['staff']);
        });
      }
    } catch (e) {
      developer.log('Error fetching staff: $e', name: 'AssignAuditStaffDialog');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _assignStaff() async {
    if (_selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one staff member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff assigned successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onAssigned?.call();
      }
    } catch (e) {
      developer.log('Error assigning staff: $e', name: 'AssignAuditStaffDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning staff: $e'),
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
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
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: AppTheme.gray600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assign Staff to Question',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Question:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question['question'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Staff Selection
          MultiSelectDropdown<Map<String, dynamic>>(
            label: 'Select Staff Members',
            options: _staff,
            selectedIds: _selectedStaff,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedStaff = selectedIds;
              });
            },
            getDisplayText: (staff) => '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
            getSubText: (staff) => staff['email']?.toString(),
            getId: (staff) => staff['id']?.toString() ?? staff['_id']?.toString() ?? '',
            hintText: 'Select staff members to assign',
          ),
          const SizedBox(height: 24),

          // Deadline Selection
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
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.inputBackground,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.mutedForeground, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.outline,
            size: isMobile ? ButtonSize.sm : ButtonSize.lg,
          ),
          const SizedBox(width: 12),
          CustomButton(
            text: _isSubmitting ? 'Assigning...' : 'Assign Staff',
            onPressed: _isSubmitting ? null : _assignStaff,
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