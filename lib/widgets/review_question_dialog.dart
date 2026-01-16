import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class ReviewQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> audit;
  final Map<String, dynamic> question;
  final String action; // "approve" or "reject"
  final VoidCallback onReviewCompleted;

  const ReviewQuestionDialog({
    super.key,
    required this.audit,
    required this.question,
    required this.action,
    required this.onReviewCompleted,
  });

  @override
  State<ReviewQuestionDialog> createState() => _ReviewQuestionDialogState();
}

class _ReviewQuestionDialogState extends State<ReviewQuestionDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isReject => widget.action == 'reject';

  Future<void> _submitReview() async {
    if (_isReject && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auditId = widget.audit['_id'] ?? widget.audit['id'];
      final questionId = widget.question['_id'] ?? widget.question['id'];

      await _apiService.reviewQuestion(
        auditId: auditId,
        questionId: questionId,
        action: widget.action,
        reason: _isReject ? _reasonController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isReject
                  ? 'Question rejected successfully!'
                  : 'Question approved successfully!',
            ),
            backgroundColor: _isReject ? AppTheme.red500 : AppTheme.green500,
          ),
        );
        widget.onReviewCompleted();
      }
    } catch (e) {
      developer.log(
        'Error reviewing question: $e',
        name: 'ReviewQuestionDialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_isReject ? 'rejecting' : 'approving'} question: $e',
            ),
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
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? screenWidth : 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isMobile),
            _buildContent(isMobile),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _isReject ? AppTheme.red50 : AppTheme.green50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isReject ? AppTheme.red200 : AppTheme.green100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isReject ? Icons.close : Icons.check,
              color: _isReject ? AppTheme.red600 : AppTheme.green600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReject ? 'Reject Question' : 'Approve Question',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  widget.question['question'] ?? 'Question',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
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
    );
  }

  Widget _buildContent(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Details
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
                  'Question Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question['question'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, color: AppTheme.gray700),
                ),
                const SizedBox(height: 8),
                if (widget.question['assignedTo'] != null) ...[
                  Text(
                    'Assigned To: ${widget.question['assignedTo']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
                if (widget.question['uploadedFile'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppTheme.gray600,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'File uploaded',
                        style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Confirmation Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isReject ? AppTheme.red50 : AppTheme.green50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isReject ? AppTheme.red200 : AppTheme.green200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isReject ? Icons.warning : Icons.info,
                  color: _isReject ? AppTheme.red600 : AppTheme.green600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isReject
                        ? 'Are you sure you want to reject this question submission? This will move the question to revision status.'
                        : 'Are you sure you want to approve this question submission? This will mark the question as completed.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isReject ? AppTheme.red600 : AppTheme.green700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rejection Reason (only for reject)
          if (_isReject) ...[
            const SizedBox(height: 20),
            CustomTextInput(
              label: 'Rejection Reason',
              controller: _reasonController,
              hint: 'Please provide a reason for rejection',
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
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
          CustomButton(
            text: _isSubmitting
                ? (_isReject ? 'Rejecting...' : 'Approving...')
                : (_isReject ? 'Reject' : 'Approve'),
            onPressed: _isSubmitting ? null : _submitReview,
            variant: _isReject
                ? ButtonVariant.destructive
                : ButtonVariant.default_,
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
