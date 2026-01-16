import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/single_select_dropdown.dart';

class AuditTemplateFormDialog extends StatefulWidget {
  final AuditTemplate? auditTemplate;
  final VoidCallback? onSuccess;

  const AuditTemplateFormDialog({
    super.key,
    this.auditTemplate,
    this.onSuccess,
  });

  @override
  State<AuditTemplateFormDialog> createState() =>
      _AuditTemplateFormDialogState();
}

class _AuditTemplateFormDialogState extends State<AuditTemplateFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;

  List<AuditSegment> _auditSegments = [];
  List<AuditType> _auditTypes = [];
  List<AuditQuestion> _auditQuestions = [];
  List<Map<String, dynamic>> _categories = [];

  AuditSegment? _selectedAuditSegment;
  AuditType? _selectedAuditType;
  String? _selectedCategoryId;

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

  List<AuditQuestion> get _filteredQuestions {
    if (_selectedCategoryId == null) return [];
    return _auditQuestions
        .where(
          (q) =>
              q.status == 'active' && q.auditQueCategory == _selectedCategoryId,
        )
        .toList();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final futures = await Future.wait([
        _apiService.getAuditSegments(),
        _apiService.getAuditTypes(),
        _apiService.getAuditQuestions(),
        _apiService.getAuditQuestionCategories(),
      ]);

      final segmentsResponse = futures[0];
      final typesResponse = futures[1];
      final questionsResponse = futures[2];
      final categoriesResponse = futures[3];

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
        if (categoriesResponse['auditQusCategories'] != null) {
          _categories = List<Map<String, dynamic>>.from(
            categoriesResponse['auditQusCategories'],
          );
        }

        // If editing, match the selected values with the loaded data
        if (_isEditing && widget.auditTemplate != null) {
          // Find matching audit segment
          try {
            _selectedAuditSegment = _auditSegments.firstWhere(
              (segment) => segment.id == widget.auditTemplate!.auditSegment.id,
            );
          } catch (e) {
            _selectedAuditSegment = _auditSegments.isNotEmpty
                ? _auditSegments.first
                : null;
          }

          // Find matching audit type
          try {
            _selectedAuditType = _auditTypes.firstWhere(
              (type) => type.id == widget.auditTemplate!.auditType.id,
            );
          } catch (e) {
            _selectedAuditType = _auditTypes.isNotEmpty
                ? _auditTypes.first
                : null;
          }

          // Try to deduce category from existing questions
          if (widget.auditTemplate!.auditQuestions.isNotEmpty) {
            final firstQ = widget.auditTemplate!.auditQuestions.first;
            // Find full question object to check categoryId if not populated in template
            // Template questions might be partial? Assuming they have ID.
            // We use _auditQuestions (full list) to find the category of the template questions.
            try {
              final fullQuestion = _auditQuestions.firstWhere(
                (q) => q.id == firstQ.id,
              );
              _selectedCategoryId = fullQuestion.auditQueCategory;
            } catch (_) {}
          }
        }

        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str
        .toLowerCase()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedAuditSegment == null ||
        _selectedAuditType == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final selectedQuestions = _filteredQuestions.map((q) => q.id).toList();
    if (selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected category has no active questions'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _toTitleCase(_nameController.text.trim());

      if (_isEditing) {
        await _apiService.updateFullAuditTemplate(
          id: widget.auditTemplate!.id,
          name: name,
          auditSegment: _selectedAuditSegment!.id,
          auditType: _selectedAuditType!.id,
          auditQuestions: selectedQuestions,
        );
      } else {
        await _apiService.createAuditTemplate(
          name: name,
          auditSegment: _selectedAuditSegment!.id,
          auditType: _selectedAuditType!.id,
          auditQuestions: selectedQuestions,
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
                  : 'Audit template created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            _isEditing
                                ? 'Edit AuditTemplate'
                                : 'Create Audit Template',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gray900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.gray600,
                          ),
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
                      value: _auditSegments.contains(_selectedAuditSegment)
                          ? _selectedAuditSegment
                          : null,
                      items: _auditSegments
                          .where((segment) => segment.status == 'active')
                          .toSet()
                          .map(
                            (segment) => DropdownMenuItem(
                              value: segment,
                              child: Text(segment.name),
                            ),
                          )
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
                      value: _auditTypes.contains(_selectedAuditType)
                          ? _selectedAuditType
                          : null,
                      items: _auditTypes
                          .where((type) => type.status == 'active')
                          .toSet()
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedAuditType = value);
                      },
                      enabled: true,
                    ),
                    const SizedBox(height: 16),

                    // "Question Category" Single Select Dropdown
                    SingleSelectDropdown<Map<String, dynamic>>(
                      label: 'Audit Question Category *',
                      options: _categories,
                      selectedId: _selectedCategoryId,
                      onSelectionChanged: (id) {
                        setState(() {
                          _selectedCategoryId = id;
                        });
                      },
                      getDisplayText: (category) =>
                          category['name']?.toString() ?? 'Unknown',
                      getId: (category) =>
                          (category['_id'] ?? category['id'])?.toString() ?? '',
                      hintText: 'Select category',
                      // isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Display filtered questions
                    if (_selectedCategoryId != null) ...[
                      const Text(
                        'Included Questions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: _filteredQuestions.isEmpty
                            ? const Text(
                                'No active questions found in this category.',
                                style: TextStyle(
                                  color: AppTheme.mutedForeground,
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredQuestions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final q = _filteredQuestions[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      q.question,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
