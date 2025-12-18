import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_select_dropdown.dart';


class AuditTemplateFormDialog extends StatefulWidget {
  final AuditTemplate? auditTemplate;
  final VoidCallback? onSuccess;

  const AuditTemplateFormDialog({
    super.key,
    this.auditTemplate,
    this.onSuccess,
  });

  @override
  State<AuditTemplateFormDialog> createState() => _AuditTemplateFormDialogState();
}

class _AuditTemplateFormDialogState extends State<AuditTemplateFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = false;
  
  List<AuditSegment> _auditSegments = [];
  List<AuditType> _auditTypes = [];
  List<AuditQuestion> _auditQuestions = [];
  
  AuditSegment? _selectedAuditSegment;
  AuditType? _selectedAuditType;
  List<String> _selectedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.auditTemplate != null) {
      _nameController.text = widget.auditTemplate!.name;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.auditTemplate != null;

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final futures = await Future.wait([
        _apiService.getAuditSegments(),
        _apiService.getAuditTypes(),
        _apiService.getAuditQuestions(),
      ]);

      final segmentsResponse = futures[0];
      final typesResponse = futures[1];
      final questionsResponse = futures[2];

      setState(() {
        _auditSegments = (segmentsResponse['auditSegments'] as List)
            .map((json) => AuditSegment.fromJson(json))
            .toList();
        _auditTypes = (typesResponse['auditTypes'] as List)
            .map((json) => AuditType.fromJson(json))
            .toList();
        _auditQuestions = (questionsResponse['auditQuestions'] as List)
            .map((json) => AuditQuestion.fromJson(json))
            .toList();
        
        // If editing, match the selected values with the loaded data
        if (_isEditing && widget.auditTemplate != null) {
          // Find matching audit segment
          try {
            _selectedAuditSegment = _auditSegments.firstWhere(
              (segment) => segment.id == widget.auditTemplate!.auditSegment.id,
            );
          } catch (e) {
            _selectedAuditSegment = _auditSegments.isNotEmpty ? _auditSegments.first : null;
          }
          
          // Find matching audit type
          try {
            _selectedAuditType = _auditTypes.firstWhere(
              (type) => type.id == widget.auditTemplate!.auditType.id,
            );
          } catch (e) {
            _selectedAuditType = _auditTypes.isNotEmpty ? _auditTypes.first : null;
          }
          
          // Set selected question IDs
          _selectedQuestionIds = widget.auditTemplate!.auditQuestions
              .map((question) => question.id)
              .toList();
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedAuditSegment == null ||
        _selectedAuditType == null ||
        _selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _apiService.updateFullAuditTemplate(
          id: widget.auditTemplate!.id,
          name: _nameController.text.trim(),
          auditSegment: _selectedAuditSegment!.id,
          auditType: _selectedAuditType!.id,
          auditQuestions: _selectedQuestionIds,
        );
      } else {
        await _apiService.createAuditTemplate(
          name: _nameController.text.trim(),
          auditSegment: _selectedAuditSegment!.id,
          auditType: _selectedAuditType!.id,
          auditQuestions: _selectedQuestionIds,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                ? 'Audit template updated successfully'
                : 'Audit template created successfully'
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints.tightFor(width: 700),
        child: _isLoadingData
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading data...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit : Icons.add,
                        color: AppTheme.gray600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Edit Audit Template' : 'Create Audit Template',
                          style: const TextStyle(
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
                  const SizedBox(height: 24),
                  
                  // Template Name
                  CustomTextInput(
                    controller: _nameController,
                    hint: 'Enter template name',
                    label: 'Template Name *',
                  ),
                  const SizedBox(height: 16),

                  // Audit Segment Dropdown
                  CustomDropdownButtonFormField<AuditSegment>(
                    label: 'Audit Segment *',
                    hint: 'Select audit segment',
                    value: _auditSegments.contains(_selectedAuditSegment) ? _selectedAuditSegment : null,
                    items: _auditSegments
                        .where((segment) => segment.status == 'active')
                        .toSet() // Remove duplicates
                        .map((segment) => DropdownMenuItem(
                              value: segment,
                              child: Text(segment.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedAuditSegment = value);
                    },
                    enabled: true,
                  ),
                  const SizedBox(height: 16),

                  // Audit Type Dropdown
                  CustomDropdownButtonFormField<AuditType>(
                    label: 'Audit Type *',
                    hint: 'Select audit type',
                    value: _auditTypes.contains(_selectedAuditType) ? _selectedAuditType : null,
                    items: _auditTypes
                        .where((type) => type.status == 'active')
                        .toSet() // Remove duplicates
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedAuditType = value);
                    },
                    enabled: true,
                  ),
                  const SizedBox(height: 16),

                  // Audit Questions Multi-Select
                  MultiSelectDropdown<AuditQuestion>(
                    label: 'Audit Questions',
                    isRequired: true,
                    options: _auditQuestions.where((q) => q.status == 'active').toList(),
                    selectedIds: _selectedQuestionIds,
                    onSelectionChanged: (selectedIds) {
                      setState(() {
                        _selectedQuestionIds = selectedIds;
                      });
                    },
                    getDisplayText: (question) => question.question,
                    getSubText: (question) => question.answer != null ? 'Answer: ${question.answer}' : null,
                    getId: (question) => question.id,
                    hintText: 'Select audit questions',
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 8),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                          variant: ButtonVariant.outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: _isEditing ? 'Update' : 'Create',
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}