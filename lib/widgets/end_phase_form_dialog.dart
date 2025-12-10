import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_button.dart';
import '../widgets/multi_select_dropdown.dart';
import 'dart:developer' as developer;

class EndPhaseFormDialog extends StatefulWidget {
  final String projectId;
  final String phaseId;
  final String phaseName;
  final Project project;
  final VoidCallback? onSuccess;
  final bool isEditMode;
  final Map<String, dynamic>? existingFormData;
  final String? formId; // Add formId for editing

  const EndPhaseFormDialog({
    super.key,
    required this.projectId,
    required this.phaseId,
    required this.phaseName,
    required this.project,
    this.onSuccess,
    this.isEditMode = false,
    this.existingFormData,
    this.formId,
  });

  @override
  State<EndPhaseFormDialog> createState() => _EndPhaseFormDialogState();
}

class _EndPhaseFormDialogState extends State<EndPhaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  DateTime? _selectedDate;
  String? _teamLeaderId;
  String? _teamLeaderName;
  List<String> _selectedTeamMemberIds = [];
  List<PlatformFile> _selectedFiles = [];
  
  List<Staff> _projectStaff = [];
  bool _isLoadingStaff = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditMode && widget.existingFormData != null) {
      // Load existing data
      final dateStr = widget.existingFormData!['date'] as String?;
      _selectedDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      
      final teamLeader = widget.existingFormData!['teamLeader'] as Map<String, dynamic>?;
      if (teamLeader != null) {
        _teamLeaderId = teamLeader['_id'];
        _teamLeaderName = '${teamLeader['firstName']} ${teamLeader['lastName']}';
      } else {
        _teamLeaderName = widget.project.teamLeader;
      }
      
      final teamMembers = widget.existingFormData!['teamMembers'] as List<dynamic>? ?? [];
      _selectedTeamMemberIds = teamMembers.map((m) => m['_id'] as String).toList();
    } else {
      _selectedDate = DateTime.now();
      _teamLeaderName = widget.project.teamLeader;
    }
    
    _loadProjectStaff();
  }

  Future<void> _loadProjectStaff() async {
    try {
      // Get all staff
      final response = await _apiService.getStaff();
      final allStaff = (response['staff'] as List)
          .map((json) => Staff.fromJson(json))
          .toList();
      
      // Find team leader ID
      final teamLeader = allStaff.firstWhere(
        (staff) => staff.fullName == widget.project.teamLeader,
        orElse: () => allStaff.first,
      );
      
      // Filter to only include team members (exclude team leader)
      // Match by name since project.teamMembers contains names
      final projectStaffList = allStaff.where((staff) {
        final fullName = staff.fullName;
        // Include only team members, exclude team leader
        return widget.project.teamMembers.contains(fullName) &&
               widget.project.teamLeader != fullName;
      }).toList();
      
      setState(() {
        _projectStaff = projectStaffList;
        _teamLeaderId = teamLeader.id;
        _isLoadingStaff = false;
      });
    } catch (e) {
      developer.log('Error loading staff: $e');
      setState(() {
        _isLoadingStaff = false;
      });
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

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      developer.log('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_teamLeaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team leader not found'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_selectedTeamMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one team member'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = {
        'apqpProject': widget.projectId,
        'phase': widget.phaseId,
        'date': _selectedDate!.toIso8601String(),
        'teamLeader': _teamLeaderId!,
        'teamMembers': _selectedTeamMemberIds,
      };
      
      developer.log('Submitting form with ${_selectedFiles.length} files');
      for (int i = 0; i < _selectedFiles.length; i++) {
        developer.log('File $i: ${_selectedFiles[i].name} (${_selectedFiles[i].size} bytes)');
      }
      
      if (widget.isEditMode && widget.formId != null) {
        // Update existing form (PUT request)
        developer.log('Updating existing form with ID: ${widget.formId}');
        await _apiService.updateEndPhaseForm(
          formId: widget.formId!,
          data: formData,
          files: _selectedFiles,
        );
      } else {
        // Create new form (POST request)
        developer.log('Creating new end phase form');
        await _apiService.createEndPhaseForm(
          data: formData,
          files: _selectedFiles,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.isEditMode 
                    ? 'End phase form updated successfully'
                    : '${widget.phaseName} is now unlocked'),
                ),
              ],
            ),
            backgroundColor: AppTheme.green500,
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      developer.log('Error submitting end phase form: $e');
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: _isLoadingStaff
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.green50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_open,
                              color: AppTheme.green600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isEditMode ? 'Edit End Phase Form' : 'End Phase Form',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.phaseName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Date Field
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppTheme.gray600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(_selectedDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedDate != null
                                      ? AppTheme.gray900
                                      : AppTheme.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Team Leader (Read-only)
                      CustomTextInput(
                        label: 'Team Leader',
                        controller: TextEditingController(text: _teamLeaderName ?? ''),
                        enabled: false,
                        hint: 'Team Leader',
                      ),
                      const SizedBox(height: 20),

                      // Team Members Multi-Select
                      MultiSelectDropdown<Staff>(
                        label: 'Team Members',
                        isRequired: true,
                        options: _projectStaff,
                        selectedIds: _selectedTeamMemberIds,
                        onSelectionChanged: (selectedIds) {
                          setState(() {
                            _selectedTeamMemberIds = selectedIds;
                          });
                        },
                        getDisplayText: (staff) => staff.fullName,
                        getSubText: (staff) => staff.email,
                        getId: (staff) => staff.id,
                        hintText: 'Select team members from project',
                      ),
                      const SizedBox(height: 20),

                      // File Upload
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gray900,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Files'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.blue600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Selected Files List
                      if (_selectedFiles.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No files selected\nSupported formats: .xlsx, .xls, .pdf, .doc, .docx',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _selectedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              final isLast = index == _selectedFiles.length - 1;
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: isLast ? null : const Border(
                                    bottom: BorderSide(color: AppTheme.gray200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getFileIcon(file.extension ?? ''),
                                      size: 20,
                                      color: AppTheme.blue600,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.gray900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatFileSize(file.size),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: AppTheme.red500,
                                      ),
                                      onPressed: () => _removeFile(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Cancel',
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              variant: ButtonVariant.outline,
                              size: ButtonSize.default_,
                              isFullWidth: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: widget.isEditMode ? 'Update' : 'Submit',
                              onPressed: _isSubmitting ? null : _submitForm,
                              variant: ButtonVariant.default_,
                              size: ButtonSize.default_,
                              isLoading: _isSubmitting,
                              isFullWidth: true,
                            ),
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
