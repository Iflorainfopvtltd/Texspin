import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class AddAuditSegmentDialog extends StatefulWidget {
  final VoidCallback onSegmentAdded;

  const AddAuditSegmentDialog({
    super.key,
    required this.onSegmentAdded,
  });

  @override
  State<AddAuditSegmentDialog> createState() => _AddAuditSegmentDialogState();
}

class _AddAuditSegmentDialogState extends State<AddAuditSegmentDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitSegment() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a segment name'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.createAuditSegment(name: _nameController.text.trim());
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit segment created successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onSegmentAdded();
      }
    } catch (e) {
      developer.log('Error creating audit segment: $e', name: 'AddAuditSegmentDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating segment: $e'),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Audit Segment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextInput(
              label: 'Segment Name',
              controller: _nameController,
              hint: 'Enter segment name',
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  variant: ButtonVariant.outline,
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: _isSubmitting ? 'Creating...' : 'Create',
                  onPressed: _isSubmitting || _nameController.text.trim().isEmpty
                      ? null
                      : _submitSegment,
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
          ],
        ),
      ),
    );
  }
}