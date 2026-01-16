import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/multi_select_dropdown.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_manager.dart';
import 'dart:developer' as developer;

class CreateAuditMainDialog extends StatefulWidget {
  final VoidCallback onAuditCreated;
  final bool isEditing;
  final Map<String, dynamic>? auditData;
  final bool isFullScreen;

  const CreateAuditMainDialog({
    super.key,
    required this.onAuditCreated,
    this.isEditing = false,
    this.auditData,
    this.isFullScreen = false,
  });

  @override
  State<CreateAuditMainDialog> createState() => _CreateAuditMainDialogState();
}

class _CreateAuditMainDialogState extends State<CreateAuditMainDialog> {
  final ApiService _apiService = ApiService();

  // Multi-step form state (2 phases)
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
  final TextEditingController _templateSegmentController =
      TextEditingController();
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

  @override
  void initState() {
    super.initState();
    // Initialize template controllers with default values
    _templateNameController.text = 'No template selected';
    _templateSegmentController.text = 'No segment available';
    _templateTypeController.text = 'No type available';

    // If editing, pre-fill basic form data first
    if (widget.isEditing && widget.auditData != null) {
      _preFillBasicData();
    }

    _initializeData();
  }

  void _preFillBasicData() {
    final audit = widget.auditData!;

    // Pre-fill basic information with proper type checking
    _auditNumberController.text = audit['auditNumber']?.toString() ?? '';
    _companyNameController.text = audit['companyName']?.toString() ?? '';
    _locationController.text = audit['location']?.toString() ?? '';

    // Pre-fill date
    if (audit['date'] != null) {
      try {
        _selectedDate = DateTime.parse(audit['date'].toString());
      } catch (e) {
        developer.log('Error parsing date: $e', name: 'CreateAuditMainDialog');
        _selectedDate = DateTime.now();
      }
    }

    // Skip to phase 2 for editing
    _currentPhase = 2;
  }

  void _preFillFormDataAfterLoad() {
    final audit = widget.auditData!;

    developer.log(
      'Starting pre-fill with audit data: $audit',
      name: 'CreateAuditMainDialog',
    );

    // Pre-fill template selection
    if (audit['auditTemplate'] != null) {
      if (audit['auditTemplate'] is String) {
        _selectedTemplateId = audit['auditTemplate'];
      } else if (audit['auditTemplate'] is Map) {
        final template = audit['auditTemplate'] as Map<String, dynamic>;
        _selectedTemplateId =
            template['_id']?.toString() ?? template['id']?.toString();

        // Also pre-fill template info
        _templateNameController.text =
            template['name']?.toString() ?? 'Unknown Template';

        if (template['auditSegment'] != null) {
          final segment = template['auditSegment'] as Map<String, dynamic>;
          _templateSegmentController.text =
              segment['name']?.toString() ?? 'Unknown Segment';
        }

        if (template['auditType'] != null) {
          final type = template['auditType'] as Map<String, dynamic>;
          _templateTypeController.text =
              type['name']?.toString() ?? 'Unknown Type';
          _selectedAuditTypeName = type['name']?.toString();
          _selectedAuditTypeId =
              type['_id']?.toString() ?? type['id']?.toString();
        }
      }
    }

    // Pre-fill staff selections with detailed debugging
    if (audit['texspinStaffMember'] != null &&
        audit['texspinStaffMember'] is List) {
      final auditStaffList = audit['texspinStaffMember'] as List;
      developer.log(
        'Audit staff list: $auditStaffList',
        name: 'CreateAuditMainDialog',
      );
      developer.log(
        'Available staff: ${_staff.map((s) => {'id': s['_id'] ?? s['id'], 'name': s['fullName'] ?? s['firstName']})}',
        name: 'CreateAuditMainDialog',
      );

      _selectedTexspinStaff.clear(); // Clear existing selections

      for (var auditStaff in auditStaffList) {
        String? staffId;

        if (auditStaff is String) {
          staffId = auditStaff;
        } else if (auditStaff is Map) {
          final staffMap = auditStaff as Map<String, dynamic>;
          staffId = staffMap['_id']?.toString() ?? staffMap['id']?.toString();
        }

        if (staffId != null) {
          // Check if this staff ID exists in our loaded staff list
          final staffExists = _staff.any((staff) {
            final loadedStaffId =
                staff['_id']?.toString() ?? staff['id']?.toString();
            return loadedStaffId == staffId;
          });

          if (staffExists) {
            _selectedTexspinStaff.add(staffId);
            developer.log(
              'Added staff ID: $staffId',
              name: 'CreateAuditMainDialog',
            );
          } else {
            developer.log(
              'Staff ID not found in list: $staffId',
              name: 'CreateAuditMainDialog',
            );
          }
        }
      }

      developer.log(
        'Final selected staff: $_selectedTexspinStaff',
        name: 'CreateAuditMainDialog',
      );
    }

    // Pre-fill visitor members from existing visitor names
    if (audit['visitCompanyMemberName'] != null &&
        audit['visitCompanyMemberName'] is List) {
      final visitors = audit['visitCompanyMemberName'] as List;
      developer.log('Audit visitors: $visitors', name: 'CreateAuditMainDialog');
      developer.log(
        'Available visitor names: ${_visitorNames.map((v) => {'id': v['_id'] ?? v['id'], 'name': v['name']})}',
        name: 'CreateAuditMainDialog',
      );

      _selectedVisitorMembers.clear(); // Clear existing selections
      _newVisitorNames.clear(); // Clear existing custom names

      for (var visitor in visitors) {
        String? visitorId;
        String? visitorName;

        if (visitor is String) {
          // Check if it's an ID that exists in our visitor names list
          final existingVisitor = _visitorNames.firstWhere(
            (v) =>
                (v['_id']?.toString() == visitor ||
                v['id']?.toString() == visitor),
            orElse: () => <String, dynamic>{},
          );

          if (existingVisitor.isNotEmpty) {
            visitorId = visitor;
            visitorName = existingVisitor['name']?.toString();
            developer.log(
              'Found existing visitor: $visitorId -> $visitorName',
              name: 'CreateAuditMainDialog',
            );
          } else {
            // It's a custom name, add to new visitor names
            visitorName = visitor;
            developer.log(
              'Adding custom visitor name: $visitorName',
              name: 'CreateAuditMainDialog',
            );
          }
        } else if (visitor is Map) {
          final visitorMap = visitor as Map<String, dynamic>;
          visitorId =
              visitorMap['_id']?.toString() ?? visitorMap['id']?.toString();
          visitorName = visitorMap['name']?.toString();
          developer.log(
            'Processing visitor map: $visitorId -> $visitorName',
            name: 'CreateAuditMainDialog',
          );
        }

        if (visitorId != null &&
            _visitorNames.any(
              (v) =>
                  (v['_id']?.toString() == visitorId ||
                  v['id']?.toString() == visitorId),
            )) {
          // Add to selected visitor members if it exists in the list
          if (!_selectedVisitorMembers.contains(visitorId)) {
            _selectedVisitorMembers.add(visitorId);
            developer.log(
              'Added visitor member: $visitorId',
              name: 'CreateAuditMainDialog',
            );
          }
        } else if (visitorName != null && visitorName.isNotEmpty) {
          // Add to new visitor names if it's a custom name
          if (!_newVisitorNames.contains(visitorName)) {
            _newVisitorNames.add(visitorName);
            developer.log(
              'Added new visitor name: $visitorName',
              name: 'CreateAuditMainDialog',
            );
          }
        }
      }

      developer.log(
        'Final selected visitor members: $_selectedVisitorMembers',
        name: 'CreateAuditMainDialog',
      );
      developer.log(
        'Final new visitor names: $_newVisitorNames',
        name: 'CreateAuditMainDialog',
      );
    }

    // Trigger a rebuild to update the UI
    setState(() {});
    developer.log(
      'Pre-fill completed, UI updated',
      name: 'CreateAuditMainDialog',
    );

    // Force another update after a brief delay to ensure dropdowns refresh
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {});
        developer.log(
          'Secondary UI update completed',
          name: 'CreateAuditMainDialog',
        );
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAuditTemplates(),
        _fetchAuditTypes(),
        _fetchStaff(),
        _fetchVisitorNames(),
        _setCurrentUserName(),
      ]);

      // After all data is loaded, pre-fill the form if editing
      if (widget.isEditing && widget.auditData != null) {
        // Add a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 100));
        _preFillFormDataAfterLoad();
      }
    } catch (e) {
      developer.log(
        'Error initializing data: $e',
        name: 'CreateAuditMainDialog',
      );
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
      developer.log(
        'Error getting current user name: $e',
        name: 'CreateAuditMainDialog',
      );
      setState(() {
        _createdByController.text = 'Current User';
      });
    }
  }

  Future<void> _fetchAuditTemplates() async {
    try {
      final response = await _apiService.getAuditTemplates();
      if (response['auditTemplates'] != null) {
        setState(() {
          _auditTemplates = List<Map<String, dynamic>>.from(
            response['auditTemplates'],
          );
        });
      }
    } catch (e) {
      developer.log(
        'Error fetching audit templates: $e',
        name: 'CreateAuditMainDialog',
      );
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
      developer.log(
        'Error fetching audit types: $e',
        name: 'CreateAuditMainDialog',
      );
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
          _visitorNames = List<Map<String, dynamic>>.from(
            response['visiterNames'],
          );
        });
      }
    } catch (e) {
      developer.log(
        'Error fetching visitor names: $e',
        name: 'CreateAuditMainDialog',
      );
    }
  }

  Future<void> _fetchTemplateDetails(String templateId) async {
    try {
      developer.log(
        'Fetching template details for ID: $templateId',
        name: 'CreateAuditMainDialog',
      );
      final response = await _apiService.getAuditTemplateById(id: templateId);
      developer.log(
        'Template response: $response',
        name: 'CreateAuditMainDialog',
      );

      if (response['auditTemplate'] != null) {
        final template = response['auditTemplate'];
        developer.log(
          'Template data: $template',
          name: 'CreateAuditMainDialog',
        );

        setState(() {
          _selectedTemplate = template;

          // Update template name controller
          _templateNameController.text = template['name'] ?? 'Unknown Template';

          // Handle audit segments - can be single object or array
          if (template['auditSegment'] != null) {
            _auditSegments = [template['auditSegment']];
            _templateSegmentController.text =
                template['auditSegment']['name'] ?? 'Unknown Segment';
            developer.log(
              'Found audit segment: ${template['auditSegment']}',
              name: 'CreateAuditMainDialog',
            );
          } else if (template['segments'] != null) {
            _auditSegments = List<Map<String, dynamic>>.from(
              template['segments'],
            );
            _templateSegmentController.text = _auditSegments
                .map((segment) => segment['name'] ?? 'Unknown Segment')
                .join(', ');
            developer.log(
              'Found segments: ${template['segments']}',
              name: 'CreateAuditMainDialog',
            );
          } else {
            _auditSegments = [];
            _templateSegmentController.text = 'No segment available';
            developer.log('No segments found', name: 'CreateAuditMainDialog');
          }

          // Handle audit type - extract from template
          if (template['auditType'] != null) {
            final templateAuditType = template['auditType'];
            _selectedAuditTypeId =
                templateAuditType['_id'] ?? templateAuditType['id'];
            _selectedAuditTypeName = templateAuditType['name'];
            _templateTypeController.text =
                _selectedAuditTypeName ?? 'Unknown Type';
            developer.log(
              'Found audit type: $_selectedAuditTypeName',
              name: 'CreateAuditMainDialog',
            );

            // Auto-fill company name and location for internal audits
            if (_selectedAuditTypeName?.toLowerCase() == 'internal') {
              _companyNameController.text = 'Texspin';
              _locationController.text = 'Ahmedabad';
              developer.log(
                'Auto-filled for internal audit: Company=Texspin, Location=Ahmedabad',
                name: 'CreateAuditMainDialog',
              );

              // Force UI update to ensure the values are displayed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            } else {
              // Clear fields for non-internal audits
              _companyNameController.clear();
              _locationController.clear();
              developer.log(
                'Cleared fields for non-internal audit type: $_selectedAuditTypeName',
                name: 'CreateAuditMainDialog',
              );
            }
          } else {
            _templateTypeController.text = 'No type available';
            developer.log(
              'No audit type found in template',
              name: 'CreateAuditMainDialog',
            );
          }
        });
      } else {
        developer.log(
          'No auditTemplate found in response',
          name: 'CreateAuditMainDialog',
        );
        // Set default values when no template is found
        setState(() {
          _templateNameController.text = 'No template selected';
          _templateSegmentController.text = 'No segment available';
          _templateTypeController.text = 'No type available';
        });
      }
    } catch (e) {
      developer.log(
        'Error fetching template details: $e',
        name: 'CreateAuditMainDialog',
      );
      // Set error values
      setState(() {
        _templateNameController.text = 'Error loading template';
        _templateSegmentController.text = 'Error loading segment';
        _templateTypeController.text = 'Error loading type';
      });
    }
  }

  void _onTemplateSelected(String templateId) {
    developer.log(
      'Template selected: $templateId',
      name: 'CreateAuditMainDialog',
    );
    setState(() {
      _selectedTemplateId = templateId;
    });
    _fetchTemplateDetails(templateId);
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

  void _addNewVisitorName() {
    final name = _toTitleCase(_newVisitorController.text.trim());
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
      default:
        return false;
    }
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str
        .toLowerCase()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

      final auditNumber = _toTitleCase(_auditNumberController.text);
      final companyName = _toTitleCase(_companyNameController.text);
      final location = _toTitleCase(_locationController.text);

      final auditData = {
        'auditNumber': auditNumber,
        'date': _selectedDate.toIso8601String(),
        'auditTemplate': _selectedTemplateId,
        'companyName': companyName,
        'location': location,
        'texspinStaffMember': _selectedTexspinStaff,
        'visitCompanyMemberName': allVisitorMembers,
      };

      if (widget.isEditing && widget.auditData != null) {
        // Update existing audit
        final auditId = widget.auditData!['_id'] ?? widget.auditData!['id'];
        await _apiService.updateAuditBasicInfo(
          auditId: auditId,
          auditData: auditData,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audit updated successfully!'),
              backgroundColor: AppTheme.green500,
            ),
          );
          widget.onAuditCreated(); // This will refresh the list
        }
      } else {
        // Create new audit
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
      }
    } catch (e) {
      developer.log(
        'Error ${widget.isEditing ? 'updating' : 'creating'} audit: $e',
        name: 'CreateAuditMainDialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.isEditing ? 'updating' : 'creating'} audit: $e',
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
    _auditNumberController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _createdByController.dispose();
    _newVisitorController.dispose();
    _templateNameController.dispose();
    _templateSegmentController.dispose();
    _templateTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Audit' : 'Create New Audit'),
          // backgroundColor: AppTheme.primary,
          // foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildBody(context),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (!widget.isFullScreen) _buildHeader(isMobile),
        _buildPhaseIndicator(isMobile),
        Expanded(child: _buildPhaseContent(isMobile, isTablet, isDesktop)),
        _buildFooter(isMobile),
      ],
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
                  widget.isEditing ? 'Edit Audit' : 'Create New Audit',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phase ${_currentPhase} of 2',
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
    final phases = ['Select Template', 'Basic Information'];

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
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.gray600,
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
                          fontWeight: isActive
                              ? FontWeight.w500
                              : FontWeight.normal,
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
      default:
        return Container();
    }
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(16, 16, 16, 32)
          : const EdgeInsets.all(24),
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
                text: _currentPhase == 2
                    ? (_isSubmitting
                          ? (widget.isEditing ? 'Updating...' : 'Creating...')
                          : (widget.isEditing
                                ? 'Update Audit'
                                : 'Create Audit'))
                    : 'Next',
                onPressed: _isSubmitting || !_isPhaseValid()
                    ? null
                    : () {
                        if (_currentPhase == 2) {
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

  // Phase 1: Template Selection as Cards
  Widget _buildPhase1TemplateSelection(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2;
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
                childAspectRatio: isMobile ? 0.85 : 1.2,
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
                            color: isSelected
                                ? AppTheme.blue100
                                : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: isMobile ? 24 : 32,
                            color: isSelected
                                ? AppTheme.blue600
                                : AppTheme.gray600,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.blue600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
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
          // Basic Information Section
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(6),
                          color: AppTheme.inputBackground,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.mutedForeground,
                              size: 20,
                            ),
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
                  hint: _selectedAuditTypeName?.toLowerCase() == 'internal'
                      ? 'Auto-filled for internal audit'
                      : 'Enter company name',
                  enabled: _selectedAuditTypeName?.toLowerCase() != 'internal',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Location',
                  controller: _locationController,
                  hint: _selectedAuditTypeName?.toLowerCase() == 'internal'
                      ? 'Auto-filled for internal audit'
                      : 'Enter location',
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
            getDisplayText: (staff) =>
                staff['fullName']?.toString() ??
                '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
            getSubText: (staff) => staff['email']?.toString(),
            getId: (staff) =>
                staff['_id']?.toString() ?? staff['id']?.toString() ?? '',
            hintText: 'Select team members',
          ),
          const SizedBox(height: 24),

          Visibility(
            visible: _selectedAuditTypeName?.toLowerCase() != 'internal',
            child: Column(
              children: [
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
                  getDisplayText: (visitor) =>
                      visitor['name']?.toString() ?? 'Unknown Visitor',
                  getId: (visitor) =>
                      visitor['id']?.toString() ??
                      visitor['_id']?.toString() ??
                      '',
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
              ],
            ),
          ),

          // Created By
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
}
