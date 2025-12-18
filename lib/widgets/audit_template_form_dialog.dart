import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';


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
  List<AuditQuestion> _selectedAuditQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.auditTemplate != null) {
      _nameController.text = widget.auditTemplate!.name;
      _selectedAuditSegment = widget.auditTemplate!.auditSegment;
      _selectedAuditType = widget.auditTemplate!.auditType;
      _selectedAuditQuestions = List.from(widget.auditTemplate!.auditQuestions);
    }
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
        _selectedAuditQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _apiService.updateAuditTemplate(
          id: widget.auditTemplate!.id,
          name: _nameController.text.trim(),
        );
      } else {
        await _apiService.createAuditTemplate(
          name: _nameController.text.trim(),
          auditSegment: _selectedAuditSegment!.id,
          auditType: _selectedAuditType!.id,
          auditQuestions: _selectedAuditQuestions.map((q) => q.id).toList(),
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
        padding: const EdgeInsets.all(24),
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
            : Column(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audit Segment *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AuditSegment>(
                        value: _selectedAuditSegment,
                        hint: const Text('Select audit segment'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.blue600),
                          ),
                        ),
                        items: _auditSegments
                            .where((segment) => segment.status == 'active')
                            .map((segment) => DropdownMenuItem(
                                  value: segment,
                                  child: Text(segment.name),
                                ))
                            .toList(),
                        onChanged: _isEditing ? null : (value) {
                          setState(() => _selectedAuditSegment = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Audit Type Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audit Type *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AuditType>(
                        value: _selectedAuditType,
                        hint: const Text('Select audit type'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.blue600),
                          ),
                        ),
                        items: _auditTypes
                            .where((type) => type.status == 'active')
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                ))
                            .toList(),
                        onChanged: _isEditing ? null : (value) {
                          setState(() => _selectedAuditType = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Audit Questions Selection
                  if (!_isEditing) ...[
                    const Text(
                      'Audit Questions *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _auditQuestions.isEmpty
                          ? const Center(child: Text('No questions available'))
                          : ListView.builder(
                              itemCount: _auditQuestions.length,
                              itemBuilder: (context, index) {
                                final question = _auditQuestions[index];
                                final isSelected = _selectedAuditQuestions.contains(question);
                                
                                return CheckboxListTile(
                                  title: Text(
                                    question.question,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: question.answer != null
                                      ? Text(
                                          'Answer: ${question.answer}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                                        )
                                      : null,
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedAuditQuestions.add(question);
                                      } else {
                                        _selectedAuditQuestions.remove(question);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Selected Questions Count
                  if (_selectedAuditQuestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${_selectedAuditQuestions.length} question(s) selected',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ),

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
    );
  }
}