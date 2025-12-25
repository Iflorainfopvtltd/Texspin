import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StaffAuditTaskSubmissionDialog extends StatefulWidget {
  final AuditMain task;
  final VoidCallback onSubmitted;

  const StaffAuditTaskSubmissionDialog({
    super.key,
    required this.task,
    required this.onSubmitted,
  });

  @override
  State<StaffAuditTaskSubmissionDialog> createState() =>
      _StaffAuditTaskSubmissionDialogState();
}

class _StaffAuditTaskSubmissionDialogState
    extends State<StaffAuditTaskSubmissionDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _error;

  // File states
  PlatformFile? _methodologyFile;
  PlatformFile? _observationFile;
  PlatformFile? _actionPlanFile;
  PlatformFile? _actionEvidenceFile;

  final TextEditingController _scoreController = TextEditingController();

  Future<void> _pickFile(Function(PlatformFile) onPicked) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'xlsx',
          'xls',
          'pdf',
          'doc',
          'docx',
        ], // Broaden types for Audit
      );

      if (result != null) {
        setState(() {
          onPicked(result.files.first);
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error picking file: $e');
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one file or score is provided?
    // Usually submission requires at least Observation?
    // For now, let's allow partial submission as per "Update" logic, or enforce at least one file.
    if (_methodologyFile == null &&
        _observationFile == null &&
        _actionPlanFile == null &&
        _actionEvidenceFile == null &&
        _scoreController.text.isEmpty) {
      setState(
        () => _error = 'Please provide at least one file or audit score.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> data = {};
      if (_scoreController.text.isNotEmpty) {
        data['auditScore'] = _scoreController.text;
      }

      await _apiService.submitAuditTask(
        auditId: widget.task.id,
        data: data,
        methodologyPath: kIsWeb ? null : _methodologyFile?.path,
        methodologyBytes: kIsWeb ? _methodologyFile?.bytes : null,
        observationPath: kIsWeb ? null : _observationFile?.path,
        observationBytes: kIsWeb ? _observationFile?.bytes : null,
        actionPlanPath: kIsWeb ? null : _actionPlanFile?.path,
        actionPlanBytes: kIsWeb ? _actionPlanFile?.bytes : null,
        actionEvidencePath: kIsWeb ? null : _actionEvidenceFile?.path,
        actionEvidenceBytes: kIsWeb ? _actionEvidenceFile?.bytes : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit Task submitted successfully')),
        );
        widget.onSubmitted();
      }
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
  void initState() {
    super.initState();
    if (widget.task.auditScore != null) {
      _scoreController.text = widget.task.auditScore.toString();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Submit Audit Task',
                  style: TextStyle(
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
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.red.withOpacity(0.1),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      _buildUploadRow(
                        'Audit Methodology',
                        _methodologyFile,
                        (file) => _methodologyFile = file,
                      ),
                      const SizedBox(height: 16),
                      _buildUploadRow(
                        'Audit Observation',
                        _observationFile,
                        (file) => _observationFile = file,
                      ),
                      const SizedBox(height: 16),
                      _buildUploadRow(
                        'Action Plan',
                        _actionPlanFile,
                        (file) => _actionPlanFile = file,
                      ),
                      const SizedBox(height: 16),
                      _buildUploadRow(
                        'Action Evidence',
                        _actionEvidenceFile,
                        (file) => _actionEvidenceFile = file,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _scoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Audit Score',
                          border: OutlineInputBorder(),
                          hintText: 'Enter score (0-100)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    : const Text('Submit Audit Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadRow(
    String label,
    PlatformFile? file,
    Function(PlatformFile) onSet,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (file != null)
                  Text(
                    'Selected: ${file.name}',
                    style: const TextStyle(
                      color: AppTheme.green600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _pickFile(onSet),
            icon: const Icon(Icons.upload_file, size: 16),
            label: Text(file == null ? 'Upload' : 'Change'),
          ),
        ],
      ),
    );
  }
}
