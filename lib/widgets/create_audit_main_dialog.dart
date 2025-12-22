import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_select_dropdown.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_manager.dart';
import 'dart:developer' as developer;

class CreateAuditMainDialog extends StatefulWidget {
  final VoidCallback onAuditCreated;

  const CreateAuditMainDialog({
    super.key,
    required this.onAuditCreated,
  });

  @override
  State<CreateAuditMainDialog> createState() => _CreateAuditMainDialogState();
}

class _CreateAuditMainDialogState extends State<CreateAuditMainDialog> {
  final ApiService _apiService = ApiService();
  
  // Multi-step form state (3 phases)
  int _currentPhase = 1;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Phase 1 - Template Selection
  List<Map<String, dynamic>> _auditTemplates = [];
  String? _selectedTemplateId;
  Map<String, dynamic>? _selectedTemplate;

  // Phase 2 - Basic Info Controllers
  final TextEditingController _auditNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _newVisitorController = TextEditingController();
  
  // Template Info Controllers
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _templateSegmentController = TextEditingController();
  final TextEditingController _templateTypeController = TextEditingController();
  
  // Phase 2 - Basic Info State
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _auditSegments = [];
  List<Map<String, dynamic>> _auditTypes = [];
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _visitorNames = [];
  
  // Selected values
  String? _selectedAuditTypeId;
  String? _selectedAuditTypeName;
  List<String> _selectedTexspinStaff = [];
  List<String> _selectedVisitorMembers = [];
  List<String> _newVisitorNames = [];
  
  // Phase 2 - File uploads
  List<PlatformFile> _attachmentFiles = [];
  
  // Phase 3 - Questions and Final Data
  final TextEditingController _auditScoreController = TextEditingController();
  List<Map<String, dynamic>> _allAuditQuestions = [];
  List<Map<String, dynamic>> _templateQuestions = [];
  Map<String, String> _questionAnswers = {};
  List<PlatformFile> _auditMethodologyFiles = [];
  List<PlatformFile> _auditObservationFiles = [];
  List<PlatformFile> _actionPlanFiles = [];
  List<PlatformFile> _actionEvidenceFiles = [];
  List<PlatformFile> _otherAttachmentFiles = [];
  String _auditStatus = 'open';

  @override
  void initState() {
    super.initState();
    // Initialize template controllers with default values
    _templateNameController.text = 'No template selected';
    _templateSegmentController.text = 'No segment available';
    _templateTypeController.text = 'No type available';
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAuditTemplates(),
        _fetchAuditTypes(),
        _fetchStaff(),
        _fetchVisitorNames(),
        _fetchAllAuditQuestions(),
        _setCurrentUserName(),
      ]);
      
    } catch (e) {
      developer.log('Error initializing data: $e', name: 'CreateAuditMainDialog');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setCurrentUserName() async {
    try {
      final loginData = await SharedPreferencesManager.getLoginData();
      
      if (loginData != null) {
        String userName = 'Current User';
        
        // Get fullName from admin object
        if (loginData['admin'] != null) {
          final admin = loginData['admin'] as Map<String, dynamic>;
          if (admin['fullName'] != null) {
            userName = admin['fullName'].toString();
          }
        }
        // Fallback to staff object if admin doesn't exist
        else if (loginData['staff'] != null) {
          final staff = loginData['staff'] as Map<String, dynamic>;
          final firstName = staff['firstName']?.toString() ?? '';
          final lastName = staff['lastName']?.toString() ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            userName = '$firstName $lastName'.trim();
          } else if (staff['fullName'] != null) {
            userName = staff['fullName'].toString();
          }
        }
        // Other fallbacks
        else if (loginData['fullName'] != null) {
          userName = loginData['fullName'].toString();
        } else if (loginData['name'] != null) {
          userName = loginData['name'].toString();
        }
        
        // Remove role information if present (e.g., "John Doe - Admin" -> "John Doe")
        if (userName.contains(' - ')) {
          userName = userName.split(' - ').first.trim();
        }
        if (userName.contains('(') && userName.contains(')')) {
          userName = userName.split('(').first.trim();
        }
        
        setState(() {
          _createdByController.text = userName;
        });
      }
    } catch (e) {
      developer.log('Error getting current user name: $e', name: 'CreateAuditMainDialog');
      setState(() {
        _createdByController.text = 'Current User';
      });
    }
  }

  Future<void> _fetchAllAuditQuestions() async {
    try {
      final response = await _apiService.getAuditQuestions();
      if (response['auditQuestions'] != null) {
        setState(() {
          _allAuditQuestions = List<Map<String, dynamic>>.from(response['auditQuestions']);
        });
      }
    } catch (e) {
      developer.log('Error fetching audit questions: $e', name: 'CreateAuditMainDialog');
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
      developer.log('Error fetching audit templates: $e', name: 'CreateAuditMainDialog');
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
      developer.log('Error fetching audit types: $e', name: 'CreateAuditMainDialog');
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
      developer.log('Error fetching staff: $e', name: 'CreateAuditMainDialog');
    }
  }

  Future<void> _fetchVisitorNames() async {
    try {
      final response = await _apiService.getVisitorNames();
      if (response['visiterNames'] != null) {
        setState(() {
          _visitorNames = List<Map<String, dynamic>>.from(response['visiterNames']);
        });
      }
    } catch (e) {
      developer.log('Error fetching visitor names: $e', name: 'CreateAuditMainDialog');
    }
  }

  Future<void> _fetchTemplateDetails(String templateId) async {
    try {
      developer.log('Fetching template details for ID: $templateId', name: 'CreateAuditMainDialog');
      final response = await _apiService.getAuditTemplateById(id: templateId);
      developer.log('Template response: $response', name: 'CreateAuditMainDialog');
      
      if (response['auditTemplate'] != null) {
        final template = response['auditTemplate'];
        developer.log('Template data: $template', name: 'CreateAuditMainDialog');
        
        setState(() {
          _selectedTemplate = template;
          
          // Update template name controller
          _templateNameController.text = template['name'] ?? 'Unknown Template';
          
          // Handle audit segments - can be single object or array
          if (template['auditSegment'] != null) {
            _auditSegments = [template['auditSegment']];
            _templateSegmentController.text = template['auditSegment']['name'] ?? 'Unknown Segment';
            developer.log('Found audit segment: ${template['auditSegment']}', name: 'CreateAuditMainDialog');
          } else if (template['segments'] != null) {
            _auditSegments = List<Map<String, dynamic>>.from(template['segments']);
            _templateSegmentController.text = _auditSegments.map((segment) => segment['name'] ?? 'Unknown Segment').join(', ');
            developer.log('Found segments: ${template['segments']}', name: 'CreateAuditMainDialog');
          } else {
            _auditSegments = [];
            _templateSegmentController.text = 'No segment available';
            developer.log('No segments found', name: 'CreateAuditMainDialog');
          }
          
          // Handle audit type - extract from template
          if (template['auditType'] != null) {
            final templateAuditType = template['auditType'];
            _selectedAuditTypeId = templateAuditType['_id'] ?? templateAuditType['id'];
            _selectedAuditTypeName = templateAuditType['name'];
            _templateTypeController.text = _selectedAuditTypeName ?? 'Unknown Type';
            developer.log('Found audit type: $_selectedAuditTypeName', name: 'CreateAuditMainDialog');
            
            // Auto-fill company name and location for internal audits
            if (_selectedAuditTypeName?.toLowerCase() == 'internal') {
              _companyNameController.text = 'Texspin';
              _locationController.text = 'Ahmedabad';
            }
          } else {
            _templateTypeController.text = 'No type available';
            developer.log('No audit type found in template', name: 'CreateAuditMainDialog');
          }
          
          // Get template questions - handle both formats
          if (template['auditQuestions'] != null) {
            final templateQuestions = template['auditQuestions'] as List;
            
            // If questions are objects with _id, extract the _id
            final templateQuestionIds = templateQuestions.map((q) {
              if (q is Map<String, dynamic>) {
                return q['_id'] ?? q['id'] ?? '';
              }
              return q.toString();
            }).where((id) => id.isNotEmpty).toList();
            
            _templateQuestions = _allAuditQuestions.where((question) {
              final questionId = question['id'] ?? question['_id'];
              return templateQuestionIds.contains(questionId);
            }).toList();
          } else {
            _templateQuestions = [];
          }
          
          // Initialize answers map
          _questionAnswers.clear();
          for (var question in _templateQuestions) {
            _questionAnswers[question['id'] ?? question['_id']] = '';
          }
        });
      } else {
        developer.log('No auditTemplate found in response', name: 'CreateAuditMainDialog');
        // Set default values when no template is found
        setState(() {
          _templateNameController.text = 'No template selected';
          _templateSegmentController.text = 'No segment available';
          _templateTypeController.text = 'No type available';
        });
      }
    } catch (e) {
      developer.log('Error fetching template details: $e', name: 'CreateAuditMainDialog');
      // Set error values
      setState(() {
        _templateNameController.text = 'Error loading template';
        _templateSegmentController.text = 'Error loading segment';
        _templateTypeController.text = 'Error loading type';
      });
    }
  }

  void _onTemplateSelected(String templateId) {
    developer.log('Template selected: $templateId', name: 'CreateAuditMainDialog');
    setState(() {
      _selectedTemplateId = templateId;
    });
    _fetchTemplateDetails(templateId);
  }

  void _onAuditTypeChanged(String? typeId) {
    if (typeId != null) {
      setState(() {
        _selectedAuditTypeId = typeId;
        _selectedAuditTypeName = _auditTypes
            .firstWhere((type) => type['id'] == typeId)['name'];
        
        // Auto-fill company name and location for internal audits
        if (_selectedAuditTypeName?.toLowerCase() == 'internal') {
          _companyNameController.text = 'Texspin';
          _locationController.text = 'Ahmedabad';
        } else {
          _companyNameController.clear();
          _locationController.clear();
        }
      });
    }
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

  Future<void> _pickFiles(List<PlatformFile> targetList, String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          targetList.addAll(result.files);
        });
      }
    } catch (e) {
      developer.log('Error picking files: $e', name: 'CreateAuditMainDialog');
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

  void _removeFile(List<PlatformFile> targetList, int index) {
    setState(() {
      targetList.removeAt(index);
    });
  }

  void _addNewVisitorName() {
    final name = _newVisitorController.text.trim();
    if (name.isNotEmpty && !_newVisitorNames.contains(name)) {
      setState(() {
        _newVisitorNames.add(name);
        _newVisitorController.clear();
      });
    }
  }

  void _removeNewVisitorName(String name) {
    setState(() {
      _newVisitorNames.remove(name);
    });
  }

  bool _isPhaseValid() {
    switch (_currentPhase) {
      case 1:
        return _selectedTemplateId != null;
      case 2:
        return _auditNumberController.text.isNotEmpty &&
               _selectedAuditTypeId != null &&
               _companyNameController.text.isNotEmpty &&
               _locationController.text.isNotEmpty;
      case 3:
        return true; // Questions are optional
      default:
        return false;
    }
  }

  Future<void> _submitAudit() async {
    if (!_isPhaseValid()) return;

    setState(() => _isSubmitting = true);

    try {
      // Combine existing visitor names with new ones
      final allVisitorMembers = [
        ..._selectedVisitorMembers,
        ..._newVisitorNames,
      ];

      final auditData = {
        'auditNumber': _auditNumberController.text,
        'date': _selectedDate.toIso8601String(),
        'auditTemplate': _selectedTemplateId,
        'companyName': _companyNameController.text,
        'location': _locationController.text,
        'texspinStaffMember': _selectedTexspinStaff,
        'visitCompanyMemberName': allVisitorMembers,
        'auditScore': _auditScoreController.text.isNotEmpty 
            ? double.tryParse(_auditScoreController.text) 
            : null,
        'questionAnswers': _questionAnswers,
        'auditStatus': _auditStatus,
      };

      await _apiService.createAuditMain(auditData: auditData);
      
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
      developer.log('Error creating audit: $e', name: 'CreateAuditMainDialog');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating audit: $e'),
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
    _auditNumberController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _createdByController.dispose();
    _auditScoreController.dispose();
    _newVisitorController.dispose();
    _templateNameController.dispose();
    _templateSegmentController.dispose();
    _templateTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    // Responsive dialog sizing
    double dialogWidth;
    double dialogHeight;
    
    if (isMobile) {
      dialogWidth = screenWidth * 0.95;
      dialogHeight = screenHeight * 0.9;
    } else if (isTablet) {
      dialogWidth = 700;
      dialogHeight = screenHeight * 0.85;
    } else {
      dialogWidth = 900;
      dialogHeight = screenHeight * 0.8;
    }

    if (_isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading audit data...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 24 : 32,
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(isMobile),
            _buildPhaseIndicator(isMobile),
            Expanded(
              child: _buildPhaseContent(isMobile, isTablet, isDesktop),
            ),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
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
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phase ${_currentPhase} of 3',
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

  Widget _buildPhaseIndicator(bool isMobile) {
    final phases = ['Select Template', 'Basic Information', 'Questions & Files'];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: List.generate(phases.length, (index) {
          final phaseNum = index + 1;
          final isActive = phaseNum <= _currentPhase;
          final isCompleted = phaseNum < _currentPhase;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: isMobile ? 32 : 40,
                        height: isMobile ? 32 : 40,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.blue600 : AppTheme.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  phaseNum.toString(),
                                  style: TextStyle(
                                    color: isActive ? Colors.white : AppTheme.gray600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phases[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: isActive ? AppTheme.gray900 : AppTheme.gray500,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < phases.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppTheme.blue600 : AppTheme.gray200,
                      margin: EdgeInsets.only(top: isMobile ? 16 : 20),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhaseContent(bool isMobile, bool isTablet, bool isDesktop) {
    switch (_currentPhase) {
      case 1:
        return _buildPhase1TemplateSelection(isMobile, isTablet, isDesktop);
      case 2:
        return _buildPhase2BasicInfo(isMobile, isTablet, isDesktop);
      case 3:
        return _buildPhase3QuestionsAndFiles(isMobile, isTablet, isDesktop);
      default:
        return Container();
    }
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
          Row(
            children: [
              if (_currentPhase > 1)
                CustomButton(
                  text: 'Back',
                  onPressed: () {
                    setState(() => _currentPhase--);
                  },
                  variant: ButtonVariant.outline,
                  size: isMobile ? ButtonSize.sm : ButtonSize.lg,
                ),
              const SizedBox(width: 12),
              CustomButton(
                text: _currentPhase == 3
                    ? (_isSubmitting ? 'Creating...' : 'Create Audit')
                    : 'Next',
                onPressed: _isSubmitting || !_isPhaseValid()
                    ? null
                    : () {
                        if (_currentPhase == 3) {
                          _submitAudit();
                        } else {
                          setState(() => _currentPhase++);
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

  // Phase 1: Template Selection as Cards
  Widget _buildPhase1TemplateSelection(bool isMobile, bool isTablet, bool isDesktop) {
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Audit Template',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an audit template to proceed with the audit creation',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 24),
          if (_auditTemplates.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: isMobile ? 48 : 64,
                    color: AppTheme.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No audit templates available',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 3 : 1.2,
              ),
              itemCount: _auditTemplates.length,
              itemBuilder: (context, index) {
                final template = _auditTemplates[index];
                final templateId = template['id'] ?? template['_id'];
                final templateName = template['name'] ?? 'Unknown Template';
                final isSelected = _selectedTemplateId == templateId;

                return InkWell(
                  onTap: () => _onTemplateSelected(templateId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.blue50 : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppTheme.blue600 : AppTheme.gray200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.blue100 : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: isMobile ? 24 : 32,
                            color: isSelected ? AppTheme.blue600 : AppTheme.gray600,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Text(
                          templateName,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.blue600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Selected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Phase 2: Basic Information
  Widget _buildPhase2BasicInfo(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audit Number and Date Row
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Audit Number',
                  controller: _auditNumberController,
                  hint: 'Enter audit number',
                  enabled: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(6),
                          color: AppTheme.inputBackground,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.mutedForeground, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Template Info (Always show, disabled CustomTextInput fields)
          CustomTextInput(
            label: 'Audit Template Name',
            controller: _templateNameController,
            hint: 'Selected template name',
            enabled: false,
          ),
          const SizedBox(height: 16),
          
          CustomTextInput(
            label: 'Audit Segment',
            controller: _templateSegmentController,
            hint: 'Template segment',
            enabled: false,
          ),
          const SizedBox(height: 16),
          
          CustomTextInput(
            label: 'Audit Type',
            controller: _templateTypeController,
            hint: 'Template audit type',
            enabled: false,
          ),
          const SizedBox(height: 24),

          // Company Name and Location
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Company Name',
                  controller: _companyNameController,
                  hint: 'Enter company name',
                  enabled: _selectedAuditTypeName?.toLowerCase() != 'internal',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Location',
                  controller: _locationController,
                  hint: 'Enter location',
                  enabled: _selectedAuditTypeName?.toLowerCase() != 'internal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Team Members Selection with MultiSelectDropdown
          MultiSelectDropdown<Map<String, dynamic>>(
            label: 'Team Members',
            options: _staff,
            selectedIds: _selectedTexspinStaff,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedTexspinStaff = selectedIds;
              });
            },
            getDisplayText: (staff) => '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
            getSubText: (staff) => staff['email']?.toString(),
            getId: (staff) => staff['id']?.toString() ?? staff['_id']?.toString() ?? '',
            hintText: 'Select team members',
          ),
          const SizedBox(height: 24),

          // Visitor Company Team with MultiSelectDropdown
          MultiSelectDropdown<Map<String, dynamic>>(
            label: 'Visitor Company Team',
            options: _visitorNames,
            selectedIds: _selectedVisitorMembers,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedVisitorMembers = selectedIds;
              });
            },
            getDisplayText: (visitor) => visitor['name']?.toString() ?? 'Unknown Visitor',
            getId: (visitor) => visitor['id']?.toString() ?? visitor['_id']?.toString() ?? '',
            hintText: 'Select visitor members',
          ),
          const SizedBox(height: 16),
          
          // Add new visitor names
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  controller: _newVisitorController,
                  hint: 'Add new visitor name',
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Add',
                onPressed: _addNewVisitorName,
                size: ButtonSize.sm,
              ),
            ],
          ),
          
          // Display new visitor names as chips
          if (_newVisitorNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _newVisitorNames.map((name) {
                return Chip(
                  label: Text(name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeNewVisitorName(name),
                  backgroundColor: AppTheme.green100,
                  labelStyle: const TextStyle(color: AppTheme.green600),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // Attachments
          _buildDocumentSection('Attachments', _attachmentFiles, isMobile),
          const SizedBox(height: 24),

          // Created By (at the end of Phase 2)
          CustomTextInput(
            label: 'Created By',
            controller: _createdByController,
            hint: 'Current user',
            enabled: false,
          ),
        ],
      ),
    );
  }

  // Phase 3: Questions and Files
  Widget _buildPhase3QuestionsAndFiles(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pre-Questions from Template
          if (_templateQuestions.isNotEmpty) ...[
            Text(
              'Pre-Questions',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ..._templateQuestions.map((question) => _buildQuestionItem(question, isMobile)),
            const SizedBox(height: 32),
          ],

          // Audit Methodology Upload
          _buildDocumentSection('Audit Methodology', _auditMethodologyFiles, isMobile),
          const SizedBox(height: 24),

          // Audit Score
          CustomTextInput(
            label: 'Audit Score',
            controller: _auditScoreController,
            hint: 'Enter audit score (optional)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Multiple File Upload Sections
          _buildDocumentSection('Audit Observation', _auditObservationFiles, isMobile),
          const SizedBox(height: 16),
          _buildDocumentSection('Action Plan', _actionPlanFiles, isMobile),
          const SizedBox(height: 16),
          _buildDocumentSection('Action Evidence', _actionEvidenceFiles, isMobile),
          const SizedBox(height: 16),
          _buildDocumentSection('Other Attachments', _otherAttachmentFiles, isMobile),
          const SizedBox(height: 24),

          // Audit Status Badge
          Row(
            children: [
              const Text(
                'Audit Status:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _auditStatus == 'open' ? AppTheme.green100 : AppTheme.red50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _auditStatus == 'open' ? AppTheme.green200 : AppTheme.red200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _auditStatus == 'open' ? Icons.check_circle : Icons.cancel,
                      color: _auditStatus == 'open' ? AppTheme.green600 : AppTheme.red600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _auditStatus == 'open' ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: _auditStatus == 'open' ? AppTheme.green600 : AppTheme.red600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: _auditStatus == 'open' ? 'Close' : 'Open',
                onPressed: () {
                  setState(() {
                    _auditStatus = _auditStatus == 'open' ? 'close' : 'open';
                  });
                },
                size: ButtonSize.sm,
                variant: ButtonVariant.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(6),
            color: AppTheme.gray50,
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection(String title, List<PlatformFile> files, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
            ),
            CustomButton(
              text: 'Add Files',
              onPressed: () => _pickFiles(files, title),
              size: ButtonSize.sm,
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.attach_file, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.gray50,
            ),
            child: Column(
              children: files.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: AppTheme.mutedForeground),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _removeFile(files, index),
                        color: AppTheme.red500,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.gray50,
            ),
            child: const Center(
              child: Text(
                'No files selected',
                style: TextStyle(color: AppTheme.mutedForeground),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> question, bool isMobile) {
    final questionId = question['id'] ?? question['_id'];
    final questionText = question['question'] ?? question['text'] ?? 'Unknown Question';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextInput(
        label: questionText,
        hint: 'Enter your answer',
        maxLines: 3,
        onChanged: (value) {
          _questionAnswers[questionId] = value;
        },
      ),
    );
  }

}