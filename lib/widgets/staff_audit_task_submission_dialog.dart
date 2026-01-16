import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StaffAuditTaskSubmissionDialog extends StatefulWidget {
  final AuditMain task;
  final Map<String, dynamic> question;
  final VoidCallback onSubmitted;

  const StaffAuditTaskSubmissionDialog({
    super.key,
    required this.task,
    required this.question,
    required this.onSubmitted,
  });

  @override
  State<StaffAuditTaskSubmissionDialog> createState() =>
      _StaffAuditTaskSubmissionDialogState();
}

class _StaffAuditTaskSubmissionDialogState
    extends State<StaffAuditTaskSubmissionDialog> {
  final ApiService _apiService = ApiService();

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
    }
  }

  Future<void> _submitTask() async {
    if (_selectedFile == null) {
      setState(() => _error = 'Please select a file to upload');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final questionId =
          widget.question['_id'] ?? widget.question['questionId'];

      await _apiService.uploadAuditQuestionFile(
        auditId: widget.task.id,
        questionId: questionId,
        filePath: kIsWeb ? null : _selectedFile!.path,
        fileBytes: _selectedFile!.bytes,
        fileName: _selectedFile!.name,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSubmitted(); // Refresh parent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit question submitted successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Only for Dialog)
        if (!isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.task.auditTemplate?['name'] ?? 'Audit Task',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 24),

        // Progress Bar
        _buildProgressBar(isMobile),
        const SizedBox(height: 32),

        // Task Details
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsGrid(isMobile),
                const SizedBox(height: 24),

                const Text(
                  'Question',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question['question'] ?? 'No Question Content',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray900,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                const Divider(),
                const SizedBox(height: 24),

                // Submission Section
                const Text(
                  'Submit Your Work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 16),

                _buildUploadArea(),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.red500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blue600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: AppTheme.blue600.withOpacity(0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit to Admin for Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.task.auditTemplate?['name'] ?? 'Audit Task'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(padding: const EdgeInsets.all(16), child: content),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }

  Widget _buildProgressBar(bool isMobile) {
    // Determine current step based on status
    int currentStep = 1;
    final status = widget.question['status']?.toLowerCase() ?? 'pending';

    if (status == 'accepted')
      currentStep = 2;
    else if (status == 'submitted')
      currentStep = 3;
    else if (status == 'revision')
      currentStep = 3;
    else if (status == 'under review')
      currentStep = 4;
    else if (status == 'completed' || status == 'approved')
      currentStep = 5;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _buildStep(1, 'Pending', currentStep >= 1, isMobile),
            _buildLine(currentStep > 1),
            _buildStep(2, 'Accepted', currentStep >= 2, isMobile),
            _buildLine(currentStep > 2),
            _buildStep(3, 'Submitted', currentStep >= 3, isMobile),
            _buildLine(currentStep > 3),
            _buildStep(4, 'Under Review', currentStep >= 4, isMobile),
            _buildLine(currentStep > 4),
            _buildStep(5, 'Completed', currentStep >= 5, isMobile),
          ],
        );
      },
    );
  }

  Widget _buildStep(int step, String label, bool isActive, bool isMobile) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.blue600 : Colors.white,
            border: Border.all(
              color: isActive ? AppTheme.blue600 : AppTheme.gray300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.gray500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppTheme.blue600 : AppTheme.gray500,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppTheme.blue600 : AppTheme.gray300,
        margin: const EdgeInsets.only(left: 4, right: 4, bottom: 20),
      ),
    );
  }

  Widget _buildDetailsGrid(bool isMobile) {
    final deadline = widget.question['deadline'] ?? widget.task.date;
    final createdBy = widget.task.createdBy?['firstName'] ?? 'Manager';
    final lastName = widget.task.createdBy?['lastName'] ?? '';
    final assignedBy = '$createdBy $lastName'.trim();

    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: [
        _buildDetailItem(
          'Activity Assigned',
          widget.task.auditTemplate?['name'] ?? 'Audit Activity',
        ),
        _buildDetailItem('Deadline', _formatDate(deadline.toString())),
        _buildDetailItem(
          'Assigned By',
          assignedBy.isEmpty ? 'N/A' : assignedBy,
        ),
        _buildDetailItem(
          'Priority',
          'High',
        ), // Assuming High for now or fetch if available
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.blue200,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.upload_file_outlined,
              size: 48,
              color: AppTheme.gray500,
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null) ...[
              Text(
                _selectedFile!.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.blue600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click to change file',
                style: TextStyle(fontSize: 12, color: AppTheme.gray500),
              ),
            ] else ...[
              const Text(
                'Upload File',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click to browse files',
                style: TextStyle(fontSize: 14, color: AppTheme.gray500),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
