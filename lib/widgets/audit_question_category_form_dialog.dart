import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';

class AuditQuestionCategoryFormDialog extends StatefulWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onSuccess;

  const AuditQuestionCategoryFormDialog({
    super.key,
    this.category,
    required this.onSuccess,
  });

  @override
  State<AuditQuestionCategoryFormDialog> createState() =>
      _AuditQuestionCategoryFormDialogState();
}

class _AuditQuestionCategoryFormDialogState
    extends State<AuditQuestionCategoryFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.category != null;

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
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final name = _toTitleCase(_nameController.text.trim());

      if (_isEditing) {
        final id = widget.category!['_id'] ?? widget.category!['id'];
        await _apiService.updateAuditQuestionCategory(id: id, name: name);
      } else {
        await _apiService.createAuditQuestionCategory(name: name);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Category updated successfully'
                  : 'Category created successfully',
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
        constraints: const BoxConstraints.tightFor(width: 500),
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
                    _isEditing ? 'Edit Category' : 'Create Category',
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
            CustomTextInput(
              label: 'Category Name',
              controller: _nameController,
              hint: 'Enter category name',
            ),
            const SizedBox(height: 24),
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
