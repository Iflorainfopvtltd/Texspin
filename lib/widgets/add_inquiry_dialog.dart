import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'custom_text_input.dart';
import 'custom_button.dart';

class AddInquiryDialog extends StatefulWidget {
  const AddInquiryDialog({super.key});

  @override
  State<AddInquiryDialog> createState() => _AddInquiryDialogState();
}

class _AddInquiryDialogState extends State<AddInquiryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerZoneController = TextEditingController();
  final _projectVolumeController = TextEditingController();
  final _valuePerPartController = TextEditingController();
  final _projectValueController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Listen to changes to calculate project value
    _projectVolumeController.addListener(_calculateProjectValue);
    _valuePerPartController.addListener(_calculateProjectValue);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerZoneController.dispose();
    _projectVolumeController.dispose();
    _valuePerPartController.dispose();
    _projectValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _calculateProjectValue() {
    final double? volume = double.tryParse(_projectVolumeController.text);
    final double? value = double.tryParse(_valuePerPartController.text);

    if (volume != null && value != null) {
      _projectValueController.text = (volume * value).toStringAsFixed(2);
    } else {
      _projectValueController.text = '';
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error picking file: $e';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = {
        'customerName': _customerNameController.text.trim(),
        'customerZone': _customerZoneController.text.trim(),
        'projectVolumePerYear': _projectVolumeController.text.trim(),
        'valuePerPart': _valuePerPartController.text.trim(),
        'projectValuePerAnnum': _projectValueController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      await ApiService().createInquiry(
        data: data,
        filePath: kIsWeb ? null : _selectedFile!.path,
        fileBytes: _selectedFile!.bytes,
        fileName: _selectedFile!.name,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inquiry created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.blue600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Inquiry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.gray500),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.red50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.red200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.red500,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppTheme.red600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              label: 'Customer Name',
                              controller: _customerNameController,
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Required',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextInput(
                              label: 'Customer Zone',
                              controller: _customerZoneController,
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Required',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              label: 'Project Volume / Year',
                              controller: _projectVolumeController,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Required',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextInput(
                              label: 'Value Per Part',
                              controller: _valuePerPartController,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isNotEmpty == true ? null : 'Required',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        label: 'Project Value / Annum',
                        controller: _projectValueController,
                        enabled: false, // Calculated field
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 3,
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'Required',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file,
                                color: AppTheme.gray500,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedFile != null
                                      ? _selectedFile!.name
                                      : 'Click to select file...',
                                  style: TextStyle(
                                    color: _selectedFile != null
                                        ? AppTheme.gray900
                                        : AppTheme.gray500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: CustomButton(
                    text: 'Create Inquiry',
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
