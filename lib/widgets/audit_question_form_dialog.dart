import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/single_select_dropdown.dart';

class AuditQuestionFormDialog extends StatefulWidget {
  final AuditQuestion? auditQuestion;
  final VoidCallback? onSuccess;

  const AuditQuestionFormDialog({
    super.key,
    this.auditQuestion,
    this.onSuccess,
  });

  @override
  State<AuditQuestionFormDialog> createState() =>
      _AuditQuestionFormDialogState();
}

class _AuditQuestionFormDialogState extends State<AuditQuestionFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.auditQuestion != null) {
      _questionController.text = widget.auditQuestion!.question;
      _selectedCategoryId = widget.auditQuestion!.auditQueCategory;
    }
    _fetchCategories();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.getAuditQuestionCategories();
      if (response['auditQusCategories'] != null) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            response['auditQusCategories'],
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching categories: $e')),
        );
      }
    }
  }

  bool get _isEditing => widget.auditQuestion != null;

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
    if (_questionController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final question = _toTitleCase(_questionController.text.trim());

      if (_isEditing) {
        await _apiService.updateAuditQuestion(
          id: widget.auditQuestion!.id,
          question: question,
          categoryId: _selectedCategoryId,
        );
      } else {
        await _apiService.createAuditQuestion(
          question: question,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Audit question updated successfully'
                  : 'Audit question created successfully',
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
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
                  _isEditing ? 'Edit Audit Question' : 'Create Audit Question',
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
        if (!isMobile) const SizedBox(height: 24),
        CustomTextInput(
          controller: _questionController,
          hint: 'Enter audit question',
          label: 'Question',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        SingleSelectDropdown<Map<String, dynamic>>(
          label: 'Audit Category',
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
          isRequired: true,
        ),
        const SizedBox(height: 24),
        if (!isMobile)
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
          )
        else
          Row(
            children: [
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
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Audit Question' : 'Create Audit Question',
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(child: formContent),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints.tightFor(width: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: formContent),
      ),
    );
  }
}
