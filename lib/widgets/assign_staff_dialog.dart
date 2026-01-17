import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class AssignStaffDialog extends StatefulWidget {
  final String projectId;
  final String phaseId;
  final String activityId;
  final String activityName;
  final String templateId;
  final String? currentStaffId;
  final String? currentStaffName;
  final bool isReassignment;
  final VoidCallback onAssigned;
  final VoidCallback? onNavigateBack;
  // Prefill data for reassignment
  final String? currentStartDate;
  final String? currentEndDate;
  final int? currentStartWeek;
  final int? currentEndWeek;
  final int? currentReminderDays;

  const AssignStaffDialog({
    super.key,
    required this.projectId,
    required this.phaseId,
    required this.activityId,
    required this.activityName,
    required this.templateId,
    this.currentStaffId,
    this.currentStaffName,
    this.isReassignment = false,
    required this.onAssigned,
    this.onNavigateBack,
    this.currentStartDate,
    this.currentEndDate,
    this.currentStartWeek,
    this.currentEndWeek,
    this.currentReminderDays,
  });

  @override
  State<AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<AssignStaffDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  bool _isLoading = true;
  String? _selectedStaffId;
  String? _selectedStaffName;
  bool _isAssigning = false;

  // Multi-step form state
  int _currentStep = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _startWeek;
  int? _endWeek;

  // Controllers for week inputs
  final TextEditingController _startWeekController = TextEditingController();
  final TextEditingController _endWeekController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  int? _reminderDays;

  // Project Constraints
  DateTime? _projectStartDate;
  DateTime? _projectEndDate;
  bool _isLoadingProject = true;

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.currentStaffId;
    _selectedStaffName = widget.currentStaffName;

    // Prefill dates if provided (for reassignment)
    if (widget.currentStartDate != null &&
        widget.currentStartDate!.isNotEmpty) {
      _startDate = _parseDate(widget.currentStartDate!);
    }
    if (widget.currentEndDate != null && widget.currentEndDate!.isNotEmpty) {
      _endDate = _parseDate(widget.currentEndDate!);
    }

    // Prefill weeks if provided (only for reassignment)
    if (widget.isReassignment) {
      _startWeek = widget.currentStartWeek;
      _endWeek = widget.currentEndWeek;
      if (_startWeek != null) {
        _startWeekController.text = _startWeek.toString();
      }
      if (_endWeek != null) {
        _endWeekController.text = _endWeek.toString();
      }
      // Prefill reminder days
      if (widget.currentReminderDays != null) {
        _reminderDays = widget.currentReminderDays;
        _reminderController.text = _reminderDays.toString();
      }
    }

    _fetchStaff();
    _fetchProjectDetails();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await _apiService.getProjectById(widget.projectId);
      if (response['apqpProject'] != null) {
        final project = response['apqpProject'];
        final dateOfIssueStr = project['dateOfIssue'] as String?;
        final totalWeeks = project['totalNumberOfWeeks'] as int? ?? 0;

        if (dateOfIssueStr != null) {
          final issueDate = DateTime.parse(dateOfIssueStr);
          setState(() {
            _projectStartDate = issueDate;
            // Calculate max date based on total weeks (7 days per week)
            _projectEndDate = issueDate.add(Duration(days: totalWeeks * 7));
            _isLoadingProject = false;
          });
          developer.log(
            'Project Dates: Start=$_projectStartDate, End=$_projectEndDate (Weeks: $totalWeeks)',
            name: 'AssignStaffDialog',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error fetching project details: $e',
        name: 'AssignStaffDialog',
      );
      setState(() => _isLoadingProject = false);
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Handle ISO format (2023-11-01T00:00:00.000Z) or simple format (2023-11-01)
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      developer.log('Error parsing date: $e', name: 'AssignStaffDialog');
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startWeekController.dispose();
    _startWeekController.dispose();
    _endWeekController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        final staff = List<Map<String, dynamic>>.from(response['staff']);
        setState(() {
          _allStaff = staff;
          _filteredStaff = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error fetching staff: $e', name: 'AssignStaffDialog');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _filterStaff(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStaff = _allStaff;
      } else {
        _filteredStaff = _allStaff.where((staff) {
          final fullName =
              '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                  .toLowerCase();
          final email = (staff['email']?.toString() ?? '').toLowerCase();
          final designationObj = staff['designation'];
          final designation =
              (designationObj is String
                      ? designationObj
                      : (designationObj is Map
                            ? (designationObj['name']?.toString() ?? '')
                            : ''))
                  .toLowerCase();
          final searchLower = query.toLowerCase();

          return fullName.contains(searchLower) ||
              email.contains(searchLower) ||
              designation.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    // Determine bounds
    final DateTime firstDate = isStartDate
        ? (_projectStartDate ?? DateTime(2020))
        : (_startDate ?? _projectStartDate ?? DateTime(2020));

    final DateTime lastDate = _projectEndDate ?? DateTime(2030);

    // If existing selection is invalid for new bounds, clear it?
    // Or just let the picker handle it (picker usually crashes if initialDate is out of bounds)

    DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    // Ensure initialDate is within bounds
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If the new start date is after the existing end date, clear the end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          // Double check to ensure end date is valid relative to start date
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date cannot be before start date'),
                backgroundColor: AppTheme.red500,
              ),
            );
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 1:
        return _selectedStaffId != null;
      case 2:
        if (_startDate == null || _endDate == null) return false;
        if (_projectStartDate != null &&
            _startDate!.isBefore(_projectStartDate!))
          return false;
        if (_projectEndDate != null && _endDate!.isAfter(_projectEndDate!))
          return false;
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _assignStaff() async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_startWeek == null || _endWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter start and end weeks'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_reminderDays != null) {
      final assignmentDuration = _endDate!.difference(_startDate!).inDays;
      if (_reminderDays! > assignmentDuration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder days cannot be greater than assignment duration ($assignmentDuration days)',
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
        return;
      }
    }

    setState(() => _isAssigning = true);

    try {
      // Check if activity is currently unassigned
      final isCurrentlyUnassigned =
          widget.currentStaffId == null || widget.currentStaffId!.isEmpty;

      final startDateStr = _formatDate(_startDate!);
      final endDateStr = _formatDate(_endDate!);

      if (isCurrentlyUnassigned) {
        // Use PATCH for new assignment
        await _apiService.assignActivityStaff(
          projectId: widget.projectId,
          phase: widget.phaseId,
          activity: widget.activityId,
          staff: _selectedStaffId!,
          startDate: startDateStr,
          endDate: endDateStr,
          startWeek: _startWeek!,
          endWeek: _endWeek!,
          reminderDays: _reminderDays,
        );
      } else {
        // Use PUT for reassignment
        await _apiService.reassignActivityStaff(
          projectId: widget.projectId,
          phaseId: widget.phaseId,
          activityId: widget.activityId,
          staffId: _selectedStaffId!,
          startDate: startDateStr,
          endDate: endDateStr,
          startWeek: _startWeek!,
          endWeek: _endWeek!,
          reminderDays: _reminderDays,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog

        widget.onAssigned(); // Refresh the data in parent

        final message = isCurrentlyUnassigned
            ? 'Staff assigned successfully!'
            : 'Staff reassigned successfully!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Error assigning staff: $e', name: 'AssignStaffDialog');
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.red500,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStepIndicator(int screenWidth) {
    final isMobile = screenWidth < 600;
    final steps = ['Select Staff', 'Date Range', 'Review'];

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              final isActive = stepNum <= _currentStep;
              final isCompleted = stepNum < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: isMobile ? 36 : 44,
                            height: isMobile ? 36 : 44,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.blue600
                                  : AppTheme.gray200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      stepNum.toString(),
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : AppTheme.gray600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 14 : 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            steps[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: isActive
                                  ? AppTheme.gray900
                                  : AppTheme.gray500,
                              fontWeight: isActive
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppTheme.blue600
                              : AppTheme.gray200,
                          margin: EdgeInsets.only(top: isMobile ? 18 : 22),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSelectionStep(int screenWidth) {
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: CustomTextInput(
            controller: _searchController,
            onChanged: _filterStaff,
            hint: 'Search by name, email, or designation...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.gray500),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterStaff('');
                    },
                  )
                : null,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredStaff.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: isMobile ? 48 : 64,
                          color: AppTheme.gray300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No staff found',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            color: AppTheme.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredStaff.length,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  itemBuilder: (context, index) {
                    final staff = _filteredStaff[index];
                    final staffId =
                        staff['id']?.toString() ??
                        staff['_id']?.toString() ??
                        '';
                    final fullName =
                        '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                            .trim();
                    final email = staff['email']?.toString() ?? '';
                    final designationObj = staff['designation'];
                    final designation = designationObj is String
                        ? designationObj
                        : (designationObj is Map
                              ? (designationObj['name']?.toString() ?? '')
                              : '');
                    final isSelected = _selectedStaffId == staffId;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedStaffId = staffId;
                          _selectedStaffName = fullName;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.blue50 : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.blue600
                                : AppTheme.gray200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isMobile ? 40 : 48,
                              height: isMobile ? 40 : 48,
                              decoration: BoxDecoration(
                                color: AppTheme.blue100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: isMobile ? 18 : 20,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.blue600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color: AppTheme.gray600,
                                    ),
                                  ),
                                  if (designation.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      designation,
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 13,
                                        color: AppTheme.gray500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.blue600,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDateRangeStep(int screenWidth) {
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Date',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray300),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.gray50,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.gray600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Select start date',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: _startDate != null
                          ? AppTheme.gray900
                          : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'End Date',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray300),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.gray50,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.gray600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select end date',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: _endDate != null
                          ? AppTheme.gray900
                          : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.blue200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppTheme.blue600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Task assigned for ${_endDate!.difference(_startDate!).inDays} Days',
                      style: const TextStyle(
                        color: AppTheme.blue900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomTextInput(
            label: 'Task Reminder (Days)',
            controller: _reminderController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _reminderDays = int.tryParse(value);
              });
            },
            hint: 'e.g. 4',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(int screenWidth) {
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Assignment',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewItem(
            'Staff Member',
            _selectedStaffName ?? 'Not selected',
          ),
          _buildReviewItem(
            'Start Date',
            _startDate != null
                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                : 'Not selected',
          ),
          _buildReviewItem(
            'End Date',
            _endDate != null
                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                : 'Not selected',
          ),
          _buildReviewItem(
            'Start Week',
            _startWeek?.toString() ?? 'Not selected',
          ),
          _buildReviewItem('End Week', _endWeek?.toString() ?? 'Not selected'),
          if (_reminderDays != null)
            _buildReviewItem('Task Reminder', '$_reminderDays days before'),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.gray900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    // Algorithm to calculate ISO-8601 week number
    final thurs = date.add(Duration(days: 4 - date.weekday));
    final year = thurs.year;
    final jan1 = DateTime(year, 1, 1);
    final daysToNextThursday = (4 - jan1.weekday + 7) % 7;
    final firstThursdayOfYear = jan1.add(Duration(days: daysToNextThursday));
    final diff = thurs.difference(firstThursdayOfYear).inDays;
    return 1 + (diff / 7).round();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final dialogWidth = isMobile
        ? screenWidth * 0.9
        : (isTablet ? 600.0 : 700.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: const BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Staff',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.activityName,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
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
            ),

            // Step Indicator
            _buildStepIndicator(screenWidth.toInt()),

            // Step Content
            Expanded(
              child: _currentStep == 1
                  ? _buildStaffSelectionStep(screenWidth.toInt())
                  : _currentStep == 2
                  ? _buildDateRangeStep(screenWidth.toInt())
                  : _buildReviewStep(screenWidth.toInt()),
            ),

            // Footer Actions
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.gray200)),
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
                  Row(
                    children: [
                      if (_currentStep > 1)
                        CustomButton(
                          text: 'Back',
                          onPressed: () {
                            setState(() => _currentStep--);
                          },
                          variant: ButtonVariant.outline,
                          size: isMobile ? ButtonSize.sm : ButtonSize.lg,
                        ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: _currentStep == 3
                            ? (_isAssigning ? 'Assigning...' : 'Done')
                            : 'Next',
                        onPressed: _isAssigning || !_isStepValid()
                            ? null
                            : () {
                                if (_currentStep == 3) {
                                  _assignStaff();
                                } else {
                                  if (_currentStep == 2 &&
                                      _reminderDays != null &&
                                      _startDate != null &&
                                      _endDate != null) {
                                    // Use strict difference (no +1) to match user preference: 13 - 3 = 10 days
                                    final duration = _endDate!
                                        .difference(_startDate!)
                                        .inDays;
                                    if (_reminderDays! > duration) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reminder days ($_reminderDays) cannot exceed duration ($duration days)',
                                          ),
                                          backgroundColor: AppTheme.red500,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  // Auto-calculate weeks when moving from Step 2 (Date Range) to Step 3 (Weeks)
                                  if (_currentStep == 2 &&
                                      _startDate != null &&
                                      _endDate != null) {
                                    final startW = _getWeekNumber(_startDate!);
                                    final endW = _getWeekNumber(_endDate!);
                                    setState(() {
                                      _startWeek = startW;
                                      _endWeek = endW;
                                      _startWeekController.text = startW
                                          .toString();
                                      _endWeekController.text = endW.toString();
                                    });
                                  }

                                  setState(() => _currentStep++);
                                }
                              },
                        size: isMobile ? ButtonSize.sm : ButtonSize.lg,
                        icon: _isAssigning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
