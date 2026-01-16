import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../models/staff_apqp_project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StaffApqpTaskSubmissionDialog extends StatefulWidget {
  final String projectId;
  final StaffApqpActivityWrapper activityWrapper;
  final String phaseId;
  final VoidCallback onTaskUpdated;

  const StaffApqpTaskSubmissionDialog({
    super.key,
    required this.projectId,
    required this.activityWrapper,
    required this.phaseId,
    required this.onTaskUpdated,
  });

  @override
  State<StaffApqpTaskSubmissionDialog> createState() =>
      _StaffApqpTaskSubmissionDialogState();
}

class _StaffApqpTaskSubmissionDialogState
    extends State<StaffApqpTaskSubmissionDialog> {
  final ApiService _apiService = ApiService();

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  String? _error;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _determineCurrentStep();
  }

  void _determineCurrentStep() {
    final status = widget.activityWrapper.activityStatus.toLowerCase();
    final approval = widget.activityWrapper.activityApprovalStatus
        .toLowerCase();

    if (status == 'pending') {
      _currentStep = 1; // UI uses 1-based indexing for visuals
    } else if (status == 'ongoing' || status == 'accepted') {
      _currentStep = 2;
    } else if (status == 'completed') {
      _currentStep = 5;
    }

    if (approval == 'under review') {
      _currentStep = 4;
    } else if (approval == 'submitted') {
      _currentStep = 3;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png'],
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

  Future<void> _submitWork() async {
    if (_selectedFile == null) {
      setState(() => _error = 'Please select a file to upload');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Create FormData
      String fileName = _selectedFile!.name;
      MultipartFile? multipartFile;

      if (kIsWeb) {
        if (_selectedFile!.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            _selectedFile!.bytes!,
            filename: fileName,
          );
        }
      } else {
        if (_selectedFile!.path != null) {
          multipartFile = await MultipartFile.fromFile(
            _selectedFile!.path!,
            filename: fileName,
          );
        }
      }

      if (multipartFile == null) throw Exception("File data is missing");

      final formData = FormData.fromMap({
        'file': multipartFile,
        'phase': widget.phaseId,
        'activity': widget.activityWrapper.activity.id,
      });

      // Submit work using the single endpoint
      await _apiService.staffSubmitProjectWork(
        projectId: widget.projectId,
        phaseId: widget.phaseId,
        activityId: widget.activityWrapper.activity.id,
        formData: formData,
      );

      widget.onTaskUpdated();
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: AppTheme.green500,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: isMobile ? screenWidth : 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.activityWrapper.activity.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                      'Question', // Using "Question" to match screenshot
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.activityWrapper.technicalRemarks ??
                          "No description available",
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
                onPressed: _isSubmitting ? null : _submitWork,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _buildStep(1, 'Pending', true, isMobile),
            _buildLine(true),
            _buildStep(2, 'Accepted', _currentStep >= 2, isMobile),
            _buildLine(_currentStep >= 2),
            _buildStep(3, 'Submitted', _currentStep >= 3, isMobile),
            _buildLine(_currentStep >= 3),
            _buildStep(4, 'Under Review', _currentStep >= 4, isMobile),
            _buildLine(_currentStep >= 4),
            _buildStep(5, 'Completed', _currentStep >= 5, isMobile),
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
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: [
        _buildDetailItem(
          'Activity Assigned',
          widget.activityWrapper.activity.name,
        ),
        _buildDetailItem(
          'Deadline',
          widget.activityWrapper.endDate == null
              ? 'No Deadline'
              : _formatDate(widget.activityWrapper.endDate!),
        ),
        _buildDetailItem('Assigned By', 'Manager'),
        _buildDetailItem('Priority', 'High'),
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
