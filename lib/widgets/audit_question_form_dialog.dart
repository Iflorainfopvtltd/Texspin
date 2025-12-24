import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';

class AuditQuestionFormDialog extends StatefulWidget {
  final AuditQuestion? auditQuestion;
  final VoidCallback? onSuccess;

  const AuditQuestionFormDialog({
    super.key,
    this.auditQuestion,
    this.onSuccess,
  });

  @override
  State<AuditQuestionFormDialog> createState() => _AuditQuestionFormDialogState();
}

class _AuditQuestionFormDialogState extends State<AuditQuestionFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.auditQuestion != null) {
      _questionController.text = widget.auditQuestion!.question;
      _answerController.text = widget.auditQuestion!.answer ?? '';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.auditQuestion != null;

  Future<void> _submit() async {
    if (_questionController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _apiService.updateAuditQuestion(
          id: widget.auditQuestion!.id,
          question: _questionController.text.trim(),
          answer: _answerController.text.trim().isNotEmpty ? _answerController.text.trim() : null,
        );
      } else {
        await _apiService.createAuditQuestion(
          question: _questionController.text.trim(),
          answer: _answerController.text.trim().isNotEmpty ? _answerController.text.trim() : null,
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
                : 'Audit question created successfully'
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
        constraints: const BoxConstraints.tightFor(width: 600),
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
            const SizedBox(height: 24),
            CustomTextInput(
              controller: _questionController,
              hint: 'Enter audit question',
              label: 'Question',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomTextInput(
              controller: _answerController,
              hint: 'Enter answer (optional)',
              label: 'Answer',
              maxLines: 2,
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