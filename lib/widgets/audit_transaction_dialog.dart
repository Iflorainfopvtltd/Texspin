import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class AuditTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> audit;
  final VoidCallback? onTransactionUpdated;

  const AuditTransactionDialog({
    super.key,
    required this.audit,
    this.onTransactionUpdated,
  });

  @override
  State<AuditTransactionDialog> createState() => _AuditTransactionDialogState();
}

class _AuditTransactionDialogState extends State<AuditTransactionDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _auditScoreController = TextEditingController();

  bool _isSubmitting = false;
  String _uploadProgress = '';

  // File lists for different categories
  List<PlatformFile> _methodologyFiles = [];
  List<PlatformFile> _observationFiles = [];
  List<PlatformFile> _actionPlanFiles = [];
  List<PlatformFile> _actionEvidenceFiles = [];
  List<PlatformFile> _otherAttachmentFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Pre-fill audit score if available
    if (widget.audit['auditScore'] != null) {
      _auditScoreController.text = widget.audit['auditScore'].toString();
    }
  }

  Future<void> _pickFiles(String category) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        // Validate file extensions
        List<PlatformFile> validFiles = [];
        List<String> invalidFiles = [];

        for (var file in result.files) {
          final extension = file.extension?.toLowerCase();
          if (extension == 'xlsx' || extension == 'xls') {
            validFiles.add(file);
          } else {
            invalidFiles.add(file.name);
          }
        }

        if (invalidFiles.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Only Excel files (.xlsx, .xls) are allowed. Rejected: ${invalidFiles.join(', ')}',
                ),
                backgroundColor: AppTheme.red500,
              ),
            );
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            switch (category) {
              case 'methodology':
                _methodologyFiles.addAll(validFiles);
                break;
              case 'observation':
                _observationFiles.addAll(validFiles);
                break;
              case 'actionPlan':
                _actionPlanFiles.addAll(validFiles);
                break;
              case 'actionEvidence':
                _actionEvidenceFiles.addAll(validFiles);
                break;
              case 'otherAttachment':
                _otherAttachmentFiles.addAll(validFiles);
                break;
            }
          });
        }
      }
    } catch (e) {
      developer.log('Error picking files: $e', name: 'AuditTransactionDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _removeFile(String category, int index) {
    setState(() {
      switch (category) {
        case 'methodology':
          _methodologyFiles.removeAt(index);
          break;
        case 'observation':
          _observationFiles.removeAt(index);
          break;
        case 'actionPlan':
          _actionPlanFiles.removeAt(index);
          break;
        case 'actionEvidence':
          _actionEvidenceFiles.removeAt(index);
          break;
        case 'otherAttachment':
          _otherAttachmentFiles.removeAt(index);
          break;
      }
    });
  }

  Future<void> _submitTransaction() async {
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 'Submitting transaction...';
    });

    try {
      final auditId = widget.audit['_id'] ?? widget.audit['id'];

      // Parse audit score first
      int? auditScore;
      if (_auditScoreController.text.isNotEmpty) {
        auditScore = int.tryParse(_auditScoreController.text);
        if (auditScore != null && (auditScore < 0 || auditScore > 100)) {
          throw Exception('Audit score must be between 0 and 100');
        }
      }

      // Prepare data map
      Map<String, dynamic> data = {};
      if (auditScore != null) {
        data['auditScore'] = auditScore;
      }

      // Prepare file arguments
      String? methodologyPath;
      List<int>? methodologyBytes;
      if (_methodologyFiles.isNotEmpty) {
        if (kIsWeb) {
          methodologyBytes = _methodologyFiles.first.bytes;
        } else {
          methodologyPath = _methodologyFiles.first.path;
        }
      }

      String? observationPath;
      List<int>? observationBytes;
      if (_observationFiles.isNotEmpty) {
        if (kIsWeb) {
          observationBytes = _observationFiles.first.bytes;
        } else {
          observationPath = _observationFiles.first.path;
        }
      }

      String? actionPlanPath;
      List<int>? actionPlanBytes;
      if (_actionPlanFiles.isNotEmpty) {
        if (kIsWeb) {
          actionPlanBytes = _actionPlanFiles.first.bytes;
        } else {
          actionPlanPath = _actionPlanFiles.first.path;
        }
      }

      String? actionEvidencePath;
      List<int>? actionEvidenceBytes;
      if (_actionEvidenceFiles.isNotEmpty) {
        if (kIsWeb) {
          actionEvidenceBytes = _actionEvidenceFiles.first.bytes;
        } else {
          actionEvidencePath = _actionEvidenceFiles.first.path;
        }
      }

      List<String>? otherFilesPaths;
      List<List<int>>? otherFilesBytes;
      if (_otherAttachmentFiles.isNotEmpty) {
        if (kIsWeb) {
          otherFilesBytes = _otherAttachmentFiles
              .map((f) => f.bytes!.toList())
              .toList();
        } else {
          otherFilesPaths = _otherAttachmentFiles.map((f) => f.path!).toList();
        }
      }

      // Update the audit with new data and files via single PUT request
      final updateResponse = await _apiService.submitAuditTask(
        auditId: auditId,
        data: data,
        methodologyPath: methodologyPath,
        methodologyBytes: methodologyBytes,
        observationPath: observationPath,
        observationBytes: observationBytes,
        actionPlanPath: actionPlanPath,
        actionPlanBytes: actionPlanBytes,
        actionEvidencePath: actionEvidencePath,
        actionEvidenceBytes: actionEvidenceBytes,
        otherFilesPaths: otherFilesPaths,
        otherFilesBytes: otherFilesBytes,
      );

      developer.log(
        'Audit update response: $updateResponse',
        name: 'AuditTransactionDialog',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit transaction updated successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onTransactionUpdated?.call();
      }
    } catch (e) {
      developer.log(
        'Error submitting transaction: $e',
        name: 'AuditTransactionDialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transaction: ${e.toString()}'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _auditScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // For mobile, use full screen
    if (isMobile) {
      return _buildMobileFullScreen();
    }

    // For tablet and desktop, use dialog
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.all(isTablet ? 16 : 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 700 : 900,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(isMobile, isTablet),
            Expanded(child: _buildContent(isMobile, isTablet)),
            _buildFooter(isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFullScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.blue50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.gray600),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Audit Transaction',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.gray900,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent(true, false)),
          _buildFooter(true, false),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: const BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.blue100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppTheme.blue600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audit Transaction',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  widget.audit['auditNumber'] ?? 'Audit',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: AppTheme.gray600,
                  ),
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

  Widget _buildContent(bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audit Score
          CustomTextInput(
            label: 'Audit Score',
            controller: _auditScoreController,
            hint: 'Enter audit score (0-100)',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final score = int.tryParse(value);
                if (score == null) {
                  return 'Please enter a valid number';
                }
                if (score < 0 || score > 100) {
                  return 'Score must be between 0 and 100';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // File Upload Sections
          _buildFileUploadSection(
            'Audit Methodology',
            'methodology',
            _methodologyFiles,
            isMobile,
            Icons.description_outlined,
            AppTheme.blue600,
          ),

          const SizedBox(height: 24),

          _buildFileUploadSection(
            'Audit Observation',
            'observation',
            _observationFiles,
            isMobile,
            Icons.visibility_outlined,
            AppTheme.green600,
          ),

          const SizedBox(height: 24),

          _buildFileUploadSection(
            'Action Plan',
            'actionPlan',
            _actionPlanFiles,
            isMobile,
            Icons.assignment_outlined,
            AppTheme.orange600,
          ),

          const SizedBox(height: 24),

          _buildFileUploadSection(
            'Action Evidence',
            'actionEvidence',
            _actionEvidenceFiles,
            isMobile,
            Icons.fact_check_outlined,
            AppTheme.purple600,
          ),

          const SizedBox(height: 24),

          _buildFileUploadSection(
            'Other Attachments',
            'otherAttachment',
            _otherAttachmentFiles,
            isMobile,
            Icons.attach_file_outlined,
            AppTheme.gray600,
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(
    String title,
    String category,
    List<PlatformFile> files,
    bool isMobile,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Upload Button
          InkWell(
            onTap: () => _pickFiles(category),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.border,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.gray50,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.table_chart,
                    size: isMobile ? 32 : 40,
                    color: AppTheme.green600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to upload Excel files',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray700,
                    ),
                  ),
                  Text(
                    'Only Excel files (.xlsx, .xls) are supported',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: AppTheme.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.green100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Excel Only',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.green700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected Files List
          if (files.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${files.length} file(s) selected:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...files.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    final fileSizeKB = (file.size / 1024).round();
                    final fileSizeMB = (file.size / (1024 * 1024))
                        .toStringAsFixed(1);
                    final displaySize = fileSizeKB > 1024
                        ? '${fileSizeMB}MB'
                        : '${fileSizeKB}KB';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(file.extension),
                            size: 20,
                            color: AppTheme.gray600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.gray900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  displaySize,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeFile(category, index),
                            color: AppTheme.red500,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      default:
        return Icons
            .table_chart; // Default to Excel icon since we only allow Excel files
    }
  }

  Widget _buildFooter(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload progress indicator
          if (_isSubmitting && _uploadProgress.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.blue200),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.blue600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploadProgress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.blue700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomButton(
                text: 'Cancel',
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                variant: ButtonVariant.outline,
                size: isMobile ? ButtonSize.sm : ButtonSize.lg,
              ),
              CustomButton(
                text: _isSubmitting ? 'Updating...' : 'Update Transaction',
                onPressed: _isSubmitting ? null : _submitTransaction,
                size: isMobile ? ButtonSize.sm : ButtonSize.lg,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
