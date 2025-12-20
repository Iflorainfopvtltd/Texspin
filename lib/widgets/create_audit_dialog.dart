import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import 'dart:io';

class CreateAuditDialog extends StatefulWidget {
  final VoidCallback onAuditCreated;

  const CreateAuditDialog({
    super.key,
    required this.onAuditCreated,
  });

  @override
  State<CreateAuditDialog> createState() => _CreateAuditDialogState();
}

class _CreateAuditDialogState extends State<CreateAuditDialog> {
  final ApiService _apiService = ApiService();
  
  // Controllers
  final TextEditingController _auditNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _auditScoreController = TextEditingController();
  final TextEditingController _newSegmentController = TextEditingController();
  final TextEditingController _newVisitorController = TextEditingController();
  
  // Form state
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  
  // Step 1 data
  String? _selectedAuditTemplateId;
  Map<String, dynamic>? _selectedAuditTemplate;
  String? _selectedAuditSegmentId;
  String? _selectedAuditTypeId;
  List<Map<String, dynamic>> _auditTemplates = [];
  List<Map<String, dynamic>> _auditSegments = [];
  List<Map<String, dynamic>> _auditTypes = [];
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _visitors = [];
  List<String> _selectedTexspinStaff = [];
  List<String> _selectedVisitors = [];
  List<File> _attachedDocuments = [];
  
  // Step 2 data
  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic> _answers = {};
  List<File> _auditMethodologyFiles = [];
  List<File> _auditObservationFiles = [];
  List<File> _actionEvidenceFiles = [];
  String _auditStatus = 'open';

  @override
  void initState() {
    super.initState();
    _generateAuditNumber();
    _fetchInitialData();
  }

  void _generateAuditNumber() {
    // Generate audit number based on current date/time
    final now = DateTime.now();
    final auditNumber = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    _auditNumberController.text = auditNumber;
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAuditTemplates(),
        _fetchAuditTypes(),
        _fetchStaff(),
        _fetchVisitors(),
      ]);
    } catch (e) {
      developer.log('Error fetching initial data: $e', name: 'CreateAuditDialog');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAuditTemplates() async {
    try {
      final response = await _apiService.getAuditTemplates();
      if (response['auditTemplates'] != null) {
        setState(() {
          _auditTemplates = List<Map<String, dynamic>>.from(response['auditTemplates']);
        });
      }
    } catch (e) {
      developer.log('Error fetching audit templates: $e', name: 'CreateAuditDialog');
    }
  }

  Future<void> _fetchAuditTypes() async {
    try {
      final response = await _apiService.getAuditTypes();
      if (response['auditTypes'] != null) {
        setState(() {
          _auditTypes = List<Map<String, dynamic>>.from(response['auditTypes']);
        });
      }
    } catch (e) {
      developer.log('Error fetching audit types: $e', name: 'CreateAuditDialog');
    }
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] != null) {
        setState(() {
          _staff = List<Map<String, dynamic>>.from(response['staff']);
        });
      }
    } catch (e) {
      developer.log('Error fetching staff: $e', name: 'CreateAuditDialog');
    }
  }

  Future<void> _fetchVisitors() async {
    try {
      final response = await _apiService.getVisitors();
      if (response['visitors'] != null) {
        setState(() {
          _visitors = List<Map<String, dynamic>>.from(response['visitors']);
        });
      }
    } catch (e) {
      developer.log('Error fetching visitors: $e', name: 'CreateAuditDialog');
    }
  }

  Future<void> _onAuditTemplateChanged(String? templateId) async {
    if (templateId == null) return;
    
    setState(() {
      _selectedAuditTemplateId = templateId;
      _selectedAuditTemplate = _auditTemplates.firstWhere(
        (template) => template['id'] == templateId,
        orElse: () => {},
      );
    });

    // Fetch segments and questions for selected template
    await _fetchAuditSegments(templateId);
    await _fetchTemplateQuestions(templateId);
  }

  Future<void> _fetchAuditSegments(String templateId) async {
    try {
      final response = await _apiService.getAuditSegmentsByTemplate(templateId);
      if (response['segments'] != null) {
        setState(() {
          _auditSegments = List<Map<String, dynamic>>.from(response['segments']);
        });
      }
    } catch (e) {
      developer.log('Error fetching audit segments: $e', name: 'CreateAuditDialog');
    }
  }

  Future<void> _fetchTemplateQuestions(String templateId) async {
    try {
      final response = await _apiService.getTemplateQuestions(templateId);
      if (response['questions'] != null) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(response['questions']);
        });
      }
    } catch (e) {
      developer.log('Error fetching template questions: $e', name: 'CreateAuditDialog');
    }
  }

  void _onAuditTypeChanged(String? typeId) {
    setState(() {
      _selectedAuditTypeId = typeId;
      final selectedType = _auditTypes.firstWhere(
        (type) => type['id'] == typeId,
        orElse: () => {},
      );
      
      // Auto-fill company name and location for internal audits
      if (selectedType['name']?.toString().toLowerCase() == 'internal') {
        _companyNameController.text = 'Texspin';
        _locationController.text = 'Ahmedabad';
      } else {
        _companyNameController.clear();
        _locationController.clear();
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addNewSegment() async {
    if (_newSegmentController.text.trim().isEmpty) return;
    
    try {
      final response = await _apiService.createAuditSegment({
        'name': _newSegmentController.text.trim(),
        'auditTemplate': _selectedAuditTemplateId,
      });
      
      if (response['segment'] != null) {
        setState(() {
          _auditSegments.add(response['segment']);
          _newSegmentController.clear();
        });
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segment added successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error adding segment: $e', name: 'CreateAuditDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding segment: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _addNewVisitor() async {
    if (_newVisitorController.text.trim().isEmpty) return;
    
    try {
      final response = await _apiService.createVisitor({
        'name': _newVisitorController.text.trim(),
      });
      
      if (response['visiterName'] != null) {
        setState(() {
          _visitors.add(response['visiterName']);
          _newVisitorController.clear();
        });
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visitor added successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error adding visitor: $e', name: 'CreateAuditDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding visitor: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _pickFiles(String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        
        setState(() {
          switch (fileType) {
            case 'documents':
              _attachedDocuments.addAll(files);
              break;
            case 'methodology':
              _auditMethodologyFiles.addAll(files);
              break;
            case 'observation':
              _auditObservationFiles.addAll(files);
              break;
            case 'evidence':
              _actionEvidenceFiles.addAll(files);
              break;
          }
        });
      }
    } catch (e) {
      developer.log('Error picking files: $e', name: 'CreateAuditDialog');
    }
  }

  bool _isStep1Valid() {
    return _selectedAuditTemplateId != null &&
           _selectedAuditSegmentId != null &&
           _selectedAuditTypeId != null &&
           _companyNameController.text.isNotEmpty &&
           _locationController.text.isNotEmpty;
  }

  bool _isStep2Valid() {
    return _auditScoreController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _auditNumberController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _auditScoreController.dispose();
    _newSegmentController.dispose();
    _newVisitorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.95 : 800.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isMobile),
            _buildStepIndicator(isMobile),
            Expanded(
              child: _currentStep == 1 
                ? _buildStep1Content(isMobile)
                : _buildStep2Content(isMobile),
            ),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }  Widge
t _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Audit',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_currentStep} of 2',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
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

  Widget _buildStepIndicator(bool isMobile) {
    final steps = ['Basic Information', 'Questions & Files'];

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isActive = stepNum <= _currentStep;
          final isCompleted = stepNum < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: isMobile ? 36 : 44,
                        height: isMobile ? 36 : 44,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.blue600 : AppTheme.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  stepNum.toString(),
                                  style: TextStyle(
                                    color: isActive ? Colors.white : AppTheme.gray600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: isActive ? AppTheme.gray900 : AppTheme.gray500,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppTheme.blue600 : AppTheme.gray200,
                      margin: EdgeInsets.only(top: isMobile ? 18 : 22),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Content(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audit Number and Date
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Audit Number',
                  controller: _auditNumberController,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gray300),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.gray50,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.gray600, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Audit Template
          CustomDropdown<String>(
            label: 'Audit Template',
            value: _selectedAuditTemplateId,
            items: _auditTemplates.map((template) => DropdownMenuItem<String>(
              value: template['id'],
              child: Text(template['name'] ?? ''),
            )).toList(),
            onChanged: _onAuditTemplateChanged,
            hint: 'Select audit template',
          ),
          const SizedBox(height: 24),

          // Audit Segment with Add button
          Row(
            children: [
              Expanded(
                child: CustomDropdown<String>(
                  label: 'Audit Segment',
                  value: _selectedAuditSegmentId,
                  items: _auditSegments.map((segment) => DropdownMenuItem<String>(
                    value: segment['id'],
                    child: Text(segment['name'] ?? ''),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedAuditSegmentId = value),
                  hint: 'Select audit segment',
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Add',
                onPressed: _selectedAuditTemplateId != null ? _showAddSegmentDialog : null,
                size: ButtonSize.sm,
                variant: ButtonVariant.outline,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Audit Type
          CustomDropdown<String>(
            label: 'Audit Type',
            value: _selectedAuditTypeId,
            items: _auditTypes.map((type) => DropdownMenuItem<String>(
              value: type['id'],
              child: Text(type['name'] ?? ''),
            )).toList(),
            onChanged: _onAuditTypeChanged,
            hint: 'Select audit type',
          ),
          const SizedBox(height: 24),

          // Company Name and Location
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Company Name',
                  controller: _companyNameController,
                  enabled: _selectedAuditTypeId == null || 
                           !_auditTypes.any((type) => 
                             type['id'] == _selectedAuditTypeId && 
                             type['name']?.toString().toLowerCase() == 'internal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Location',
                  controller: _locationController,
                  enabled: _selectedAuditTypeId == null || 
                           !_auditTypes.any((type) => 
                             type['id'] == _selectedAuditTypeId && 
                             type['name']?.toString().toLowerCase() == 'internal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Created By (read-only)
          CustomTextInput(
            label: 'Created By',
            controller: TextEditingController(text: 'Current User'), // Replace with actual user
            enabled: false,
          ),
          const SizedBox(height: 24),

          // Texspin Staff Members
          _buildStaffSelection(),
          const SizedBox(height: 24),

          // Visit Company Member Names
          _buildVisitorSelection(),
          const SizedBox(height: 24),

          // Attach Documents
          _buildDocumentAttachment(),
        ],
      ),
    );
  }

  Widget _buildStaffSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Texspin Staff Members',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ..._staff.map((staff) {
                final staffId = staff['id'] ?? staff['_id'];
                final isSelected = _selectedTexspinStaff.contains(staffId);
                final fullName = '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim();
                
                return CheckboxListTile(
                  title: Text(fullName),
                  subtitle: Text(staff['email'] ?? ''),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedTexspinStaff.add(staffId);
                      } else {
                        _selectedTexspinStaff.remove(staffId);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Visit Company Member Names',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
            ),
            CustomButton(
              text: 'Add New',
              onPressed: _showAddVisitorDialog,
              size: ButtonSize.sm,
              variant: ButtonVariant.outline,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ..._visitors.map((visitor) {
                final visitorId = visitor['id'] ?? visitor['_id'];
                final isSelected = _selectedVisitors.contains(visitorId);
                
                return CheckboxListTile(
                  title: Text(visitor['name'] ?? ''),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedVisitors.add(visitorId);
                      } else {
                        _selectedVisitors.remove(visitorId);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attach Documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
            ),
            CustomButton(
              text: 'Browse Files',
              onPressed: () => _pickFiles('documents'),
              size: ButtonSize.sm,
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.attach_file, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_attachedDocuments.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.gray50,
            ),
            child: Column(
              children: _attachedDocuments.map((file) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16, color: AppTheme.gray600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _attachedDocuments.remove(file));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }  Widget 
_buildStep2Content(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Questions from template
          if (_questions.isNotEmpty) ...[
            const Text(
              'Template Questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ..._questions.map((question) => _buildQuestionWidget(question)).toList(),
            const SizedBox(height: 32),
          ],

          // Audit Methodology Files
          _buildFileUploadSection(
            'Audit Methodology',
            'methodology',
            _auditMethodologyFiles,
          ),
          const SizedBox(height: 24),

          // Audit Score
          CustomTextInput(
            label: 'Audit Score',
            controller: _auditScoreController,
            keyboardType: TextInputType.number,
            hint: 'Enter audit score',
          ),
          const SizedBox(height: 24),

          // Audit Observation Files
          _buildFileUploadSection(
            'Audit Observation',
            'observation',
            _auditObservationFiles,
          ),
          const SizedBox(height: 24),

          // Action Evidence Files
          _buildFileUploadSection(
            'Action Evidence',
            'evidence',
            _actionEvidenceFiles,
          ),
          const SizedBox(height: 24),

          // Audit Status
          CustomDropdown<String>(
            label: 'Audit Status',
            value: _auditStatus,
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'close', child: Text('Close')),
            ],
            onChanged: (value) => setState(() => _auditStatus = value ?? 'open'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionId = question['id'] ?? question['_id'];
    final questionText = question['question'] ?? '';
    final questionType = question['type'] ?? 'text';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.gray300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnswerInput(questionId, questionType),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(String questionId, String questionType) {
    switch (questionType.toLowerCase()) {
      case 'boolean':
      case 'yes_no':
        return Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Yes'),
                value: 'yes',
                groupValue: _answers[questionId],
                onChanged: (value) => setState(() => _answers[questionId] = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('No'),
                value: 'no',
                groupValue: _answers[questionId],
                onChanged: (value) => setState(() => _answers[questionId] = value),
              ),
            ),
          ],
        );
      case 'multiple_choice':
        // Assuming options are provided in question data
        final options = question['options'] as List<dynamic>? ?? [];
        return Column(
          children: options.map((option) {
            return RadioListTile<String>(
              title: Text(option.toString()),
              value: option.toString(),
              groupValue: _answers[questionId],
              onChanged: (value) => setState(() => _answers[questionId] = value),
            );
          }).toList(),
        );
      default:
        return TextField(
          onChanged: (value) => _answers[questionId] = value,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.gray300),
            ),
            filled: true,
            fillColor: AppTheme.gray50,
          ),
          maxLines: questionType == 'textarea' ? 3 : 1,
        );
    }
  }

  Widget _buildFileUploadSection(String title, String fileType, List<File> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
              ),
            ),
            CustomButton(
              text: 'Upload Files',
              onPressed: () => _pickFiles(fileType),
              size: ButtonSize.sm,
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.upload_file, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.gray50,
            ),
            child: Column(
              children: files.map((file) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16, color: AppTheme.gray600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => files.remove(file));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddSegmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Segment'),
        content: TextField(
          controller: _newSegmentController,
          decoration: const InputDecoration(
            hintText: 'Enter segment name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Add',
            onPressed: _addNewSegment,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showAddVisitorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Visitor'),
        content: TextField(
          controller: _newVisitorController,
          decoration: const InputDecoration(
            hintText: 'Enter visitor name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Add',
            onPressed: _addNewVisitor,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.gray200)),
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
          Row(
            children: [
              if (_currentStep > 1)
                CustomButton(
                  text: 'Back',
                  onPressed: () => setState(() => _currentStep--),
                  variant: ButtonVariant.outline,
                  size: isMobile ? ButtonSize.sm : ButtonSize.lg,
                ),
              const SizedBox(width: 12),
              CustomButton(
                text: _currentStep == 2
                    ? (_isSubmitting ? 'Creating...' : 'Create Audit')
                    : 'Next',
                onPressed: _isSubmitting || 
                          (_currentStep == 1 && !_isStep1Valid()) ||
                          (_currentStep == 2 && !_isStep2Valid())
                    ? null
                    : () {
                        if (_currentStep == 2) {
                          _createAudit();
                        } else {
                          setState(() => _currentStep++);
                        }
                      },
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
        ],
      ),
    );
  }

  Future<void> _createAudit() async {
    setState(() => _isSubmitting = true);

    try {
      // Prepare audit data
      final auditData = {
        'auditNumber': _auditNumberController.text,
        'date': _selectedDate.toIso8601String(),
        'auditTemplate': _selectedAuditTemplateId,
        'companyName': _companyNameController.text,
        'location': _locationController.text,
        'texspinStaffMember': _selectedTexspinStaff,
        'visitCompanyMemberName': _selectedVisitors,
        'auditStatus': _auditStatus,
        'answers': _answers,
      };

      // Create audit
      final response = await _apiService.createAudit(auditData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit created successfully!'),
            backgroundColor: AppTheme.green500,
          ),
        );
        widget.onAuditCreated();
      }
    } catch (e) {
      developer.log('Error creating audit: $e', name: 'CreateAuditDialog');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating audit: $e'),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }
}