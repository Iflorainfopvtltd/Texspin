import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../models/models.dart';
import '../models/additional_entities.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_alert.dart';
import '../widgets/multi_select_dropdown.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;
  final Function(Project project) onSave;
  final VoidCallback onCancel;

  const EditProjectScreen({
    super.key,
    required this.project,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  int _activeTab = 0;
  String? _error;
  final ApiService _apiService = ApiService();

  // Project Details State
  late TextEditingController _customerNameController;
  late TextEditingController _locationController;
  late TextEditingController _partNameController;
  late TextEditingController _partNumberController;
  late TextEditingController _revisionNumberController;
  late TextEditingController _planNumberController;
  late TextEditingController _authorizationController;
  late TextEditingController _totalWeeksController;
  late TextEditingController _projectVolumePerYearController;
  late TextEditingController _valuePerPartController;
  late TextEditingController _projectValuePerAnnumController;

  // Date controllers
  late TextEditingController _revisionDateController;
  late TextEditingController _dateOfIssueController;

  String _teamLeader = '';
  String _teamLeaderId = ''; // Store team leader ID
  List<String> _selectedMembers = [];
  List<String> _selectedMemberIds = []; // Store selected member IDs

  // API Data
  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _teamLeaders = [];
  List<Map<String, dynamic>> _teamMembers = [];

  Map<String, dynamic>? _rawProjectData;
  String? _projectTemplateId;

  // Templates
  List<TemplateEntity> _templates = [];
  TemplateEntity? _selectedTemplate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchData();
  }

  void _initializeControllers() {
    _customerNameController = TextEditingController(
      text: _toTitleCase(widget.project.customerName),
    );
    _locationController = TextEditingController(
      text: _toTitleCase(widget.project.location),
    );
    _partNameController = TextEditingController(
      text: _toTitleCase(widget.project.partName),
    );
    _partNumberController = TextEditingController(
      text: _toTitleCase(widget.project.partNumber),
    );
    _revisionNumberController = TextEditingController(
      text: _toTitleCase(widget.project.revisionNumber),
    );
    _planNumberController = TextEditingController(
      text: _toTitleCase(widget.project.planNumber),
    );
    _authorizationController = TextEditingController(
      text: widget.project.teamLeaderAuthorization,
    );
    _totalWeeksController = TextEditingController(
      text: widget.project.totalWeeks.toString(),
    );

    // Initialize new fields - try to get from project if available
    // Note: These fields may not be in the Project model yet, so we'll need to fetch them
    // For now, initialize as empty - they'll be populated after fetching project details
    _projectVolumePerYearController = TextEditingController();
    _valuePerPartController = TextEditingController();
    _projectValuePerAnnumController = TextEditingController();

    // Initialize date controllers
    _revisionDateController = TextEditingController(
      text: widget.project.revisionDate.isNotEmpty
          ? widget.project.revisionDate
          : '',
    );
    _dateOfIssueController = TextEditingController(
      text: widget.project.dateOfIssue.isNotEmpty
          ? widget.project.dateOfIssue
          : DateTime.now().toIso8601String().split('T')[0],
    );

    _teamLeader = widget.project.teamLeader;
    _selectedMembers = List.from(widget.project.teamMembers);
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // First, fetch the full project details to get template and financial fields
      await _fetchProjectDetails();

      // Fetch staff
      final staffResponse = await _apiService.getStaff();
      if (staffResponse['staff'] != null) {
        final allStaff = List<Map<String, dynamic>>.from(
          staffResponse['staff'],
        );
        setState(() {
          _allStaff = allStaff;
          _teamLeaders = allStaff
              .where((s) => s['designation'] == 'Team Leader')
              .toList();
          _teamMembers = allStaff
              .where((s) => s['designation'] != 'Team Leader')
              .toList();

          // Try to find and set team leader ID
          if (_teamLeader.isNotEmpty) {
            final leader = _teamLeaders.firstWhere(
              (l) => (l['fullName'] ?? '').toString() == _teamLeader,
              orElse: () => {},
            );
            if (leader.isNotEmpty) {
              _teamLeaderId = (leader['id'] ?? '').toString();
            }
          }

          // Try to find and set team member IDs
          if (_selectedMembers.isNotEmpty) {
            _selectedMemberIds = _teamMembers
                .where((member) {
                  final fullName = (member['fullName'] ?? '').toString();
                  return _selectedMembers.contains(fullName);
                })
                .map((member) => (member['id'] ?? '').toString())
                .toList();
          }
        });
      }

      // Fetch templates
      final templatesResponse = await _apiService.getTemplates();
      developer.log(
        'Templates response: $templatesResponse',
        name: 'EditProjectScreen',
      );

      if (templatesResponse['templates'] != null) {
        final templatesData = templatesResponse['templates'] is List
            ? templatesResponse['templates']
            : [templatesResponse['templates']];

        final parsedTemplates = <TemplateEntity>[];
        for (final json in templatesData) {
          try {
            final template = TemplateEntity.fromJson(json);
            parsedTemplates.add(template);
          } catch (e, stackTrace) {
            developer.log(
              'Error parsing template: $e\nStack trace: $stackTrace\nJSON: $json',
              name: 'EditProjectScreen',
              error: e,
            );
          }
        }

        setState(() {
          _templates = parsedTemplates
              .where((t) => t.status == 'active')
              .toList();

          // Preselect template if we have a template ID
          if (_projectTemplateId != null && _templates.isNotEmpty) {
            try {
              _selectedTemplate = _templates.firstWhere(
                (t) => t.id == _projectTemplateId,
                orElse: () =>
                    _templates.first, // Fallback to first if not found
              );
            } catch (e) {
              developer.log(
                'Template not found: $_projectTemplateId',
                name: 'EditProjectScreen',
              );
            }
          }
        });
      } else if (templatesResponse['data'] != null) {
        final templatesData = templatesResponse['data'] is List
            ? templatesResponse['data']
            : [templatesResponse['data']];

        final parsedTemplates = <TemplateEntity>[];
        for (final json in templatesData) {
          try {
            final template = TemplateEntity.fromJson(json);
            parsedTemplates.add(template);
          } catch (e, stackTrace) {
            developer.log(
              'Error parsing template: $e\nStack trace: $stackTrace\nJSON: $json',
              name: 'EditProjectScreen',
              error: e,
            );
          }
        }

        setState(() {
          _templates = parsedTemplates
              .where((t) => t.status == 'active')
              .toList();

          // Preselect template if we have a template ID
          if (_projectTemplateId != null && _templates.isNotEmpty) {
            try {
              _selectedTemplate = _templates.firstWhere(
                (t) => t.id == _projectTemplateId,
                orElse: () => _templates.first,
              );
            } catch (e) {
              developer.log(
                'Template not found: $_projectTemplateId',
                name: 'EditProjectScreen',
              );
            }
          }
        });
      }
    } catch (e) {
      developer.log('Error fetching data: $e', name: 'EditProjectScreen');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add method to fetch full project details
  Future<void> _fetchProjectDetails() async {
    try {
      // Fetch all projects and find the one matching our project ID
      final projectsResponse = await _apiService.getProjects();
      if (projectsResponse['apqpProjects'] != null) {
        final projectsList = projectsResponse['apqpProjects'] as List<dynamic>;
        final projectData = projectsList.firstWhere(
          (p) => (p as Map<String, dynamic>)['_id'] == widget.project.id,
          orElse: () => null,
        );

        if (projectData != null) {
          _rawProjectData = projectData as Map<String, dynamic>;

          // Extract template ID
          final templateObj = _rawProjectData!['template'];
          if (templateObj != null) {
            if (templateObj is Map) {
              _projectTemplateId =
                  templateObj['_id']?.toString() ??
                  templateObj['id']?.toString();
            } else if (templateObj is String) {
              _projectTemplateId = templateObj;
            }
          }

          // Extract financial fields and populate controllers
          final projectVolumePerYear = _rawProjectData!['projectVolumePerYear'];
          final valuePerPart = _rawProjectData!['valuePerPart'];
          final projectValuePerAnnum = _rawProjectData!['projectValuePerAnnum'];

          if (mounted) {
            setState(() {
              if (projectVolumePerYear != null) {
                _projectVolumePerYearController.text = projectVolumePerYear
                    .toString();
              }
              if (valuePerPart != null) {
                _valuePerPartController.text = valuePerPart.toString();
              }
              if (projectValuePerAnnum != null) {
                _projectValuePerAnnumController.text = projectValuePerAnnum
                    .toString();
              }
            });
          }
        }
      }
    } catch (e) {
      developer.log(
        'Error fetching project details: $e',
        name: 'EditProjectScreen',
      );
      // Don't show error to user, just log it
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _locationController.dispose();
    _partNameController.dispose();
    _partNumberController.dispose();
    _revisionNumberController.dispose();
    _planNumberController.dispose();
    _authorizationController.dispose();
    _totalWeeksController.dispose();
    _projectVolumePerYearController.dispose();
    _valuePerPartController.dispose();
    _projectValuePerAnnumController.dispose();
    _revisionDateController.dispose();
    _dateOfIssueController.dispose();
    super.dispose();
  }

  int get _totalWeeks => int.tryParse(_totalWeeksController.text) ?? 0;

  // Calculate project value per annum automatically
  void _calculateProjectValue() {
    final volume =
        int.tryParse(_projectVolumePerYearController.text.trim()) ?? 0;
    final valuePerPart =
        double.tryParse(_valuePerPartController.text.trim()) ?? 0.0;
    final calculatedValue = volume * valuePerPart;
    _projectValuePerAnnumController.text = calculatedValue > 0
        ? calculatedValue.toStringAsFixed(2)
        : '';
    setState(() {});
  }

  // Validation: All fields with '*' must be filled (except Team Members which is optional)
  bool get _isDetailsValid =>
      _customerNameController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _partNameController.text.trim().isNotEmpty &&
      _partNumberController.text.trim().isNotEmpty &&
      _revisionNumberController.text.trim().isNotEmpty &&
      _revisionDateController.text.trim().isNotEmpty &&
      _teamLeader.isNotEmpty &&
      _planNumberController.text.trim().isNotEmpty &&
      _dateOfIssueController.text.trim().isNotEmpty &&
      _totalWeeks > 0 &&
      _projectVolumePerYearController.text.trim().isNotEmpty &&
      _valuePerPartController.text.trim().isNotEmpty &&
      _projectValuePerAnnumController.text.trim().isNotEmpty;

  // Helper method to convert date string to ISO format
  String _convertToIsoDate(String dateString) {
    if (dateString.isEmpty) {
      return DateTime.now().toUtc().toIso8601String();
    }
    try {
      final dateParts = dateString.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final date = DateTime.utc(year, month, day);
        return date.toIso8601String();
      }
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        return date.toUtc().toIso8601String();
      }
      return DateTime.now().toUtc().toIso8601String();
    } catch (e) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  // Validation: Check that a template is selected
  bool get _isTemplateSelected => _selectedTemplate != null;

  void _selectTemplate(TemplateEntity template) {
    setState(() {
      _selectedTemplate = template;
    });
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

  // Helper function for date picker logic
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.tryParse(controller.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => controller.text = date.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse numeric values
      final projectVolumePerYear =
          int.tryParse(_projectVolumePerYearController.text.trim()) ?? 0;
      final valuePerPart =
          double.tryParse(_valuePerPartController.text.trim()) ?? 0.0;
      final projectValuePerAnnum =
          double.tryParse(_projectValuePerAnnumController.text.trim()) ?? 0.0;

      // Prepare API request data
      final projectData = {
        'customerName': _toTitleCase(_customerNameController.text.trim()),
        'location': _toTitleCase(_locationController.text.trim()),
        'partName': _toTitleCase(_partNameController.text.trim()),
        'partNumber': _toTitleCase(_partNumberController.text.trim()),
        'revisionNumber': _toTitleCase(_revisionNumberController.text.trim()),
        'revisionDate': _convertToIsoDate(_revisionDateController.text),
        'teamLeader': _teamLeaderId,
        'teamMembers': _selectedMemberIds,
        'planNumber': _toTitleCase(_planNumberController.text.trim()),
        'dateOfIssue': _convertToIsoDate(_dateOfIssueController.text),
        'teamLeaderAuthorization': _authorizationController.text.trim(),
        'totalNumberOfWeeks': _totalWeeks,
        'projectVolumePerYear': projectVolumePerYear,
        'valuePerPart': valuePerPart,
        'projectValuePerAnnum': projectValuePerAnnum,
        'template': _selectedTemplate!.id,
      };

      // Call API to update project using PUT request
      final response = await _apiService.updateProject(
        projectId: widget.project.id,
        projectData: projectData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Create Project object for callback
        final updatedProject = Project(
          id: widget.project.id,
          customerName: _customerNameController.text,
          location: _locationController.text,
          partName: _partNameController.text,
          partNumber: _partNumberController.text,
          revisionNumber: _revisionNumberController.text,
          revisionDate: _revisionDateController.text,
          teamLeader: _teamLeader,
          teamMembers: _selectedMembers,
          planNumber: _planNumberController.text,
          dateOfIssue: _dateOfIssueController.text,
          teamLeaderAuthorization: _authorizationController.text,
          totalWeeks: _totalWeeks,
          phases: _selectedTemplate!.phases.map((tp) {
            return Phase(
              id: tp.phaseId,
              name: tp.name,
              activities: tp.activities.map((ta) {
                return Activity(
                  id: ta.activityId,
                  name: ta.name,
                  responsiblePerson: '',
                  startWeek: 1,
                  endWeek: 1,
                  status: ActivityStatus.notStarted,
                );
              }).toList(),
            );
          }).toList(),
          createdAt: widget.project.createdAt,
          progress: widget.project.progress,
          projectStatus: widget.project.projectStatus,
        );
        widget.onSave(updatedProject);
      }
    } catch (e) {
      developer.log('Error updating project: $e', name: 'EditProjectScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            _ExportOption(
              icon: Icons.picture_as_pdf,
              title: 'Export as PDF',
              description:
                  'Generate a PDF report with project details and Gantt chart',
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(context);
              },
            ),
            // const SizedBox(height: 12),
            // _ExportOption(
            //   icon: Icons.table_chart,
            //   title: 'Export as Excel',
            //   description: 'Export project data to Excel spreadsheet',
            //   onTap: () {
            //     Navigator.pop(context);
            //     _exportToExcel(context);
            //   },
            // ),
            // const SizedBox(height: 12),
            // _ExportOption(
            //   icon: Icons.description,
            //   title: 'Export as CSV',
            //   description: 'Export project data as CSV file',
            //   onTap: () {
            //     Navigator.pop(context);
            //     _exportToCSV(context);
            //   },
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PDF export would generate a report with project details and Gantt chart',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.green500,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: widget.onCancel,
          color: AppTheme.gray900,
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Project',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              'Update project details and timeline',
              style: TextStyle(fontSize: 12, color: AppTheme.gray600),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Export',
            onPressed: () => _showExportDialog(context),
            variant: ButtonVariant.outline,
            size: ButtonSize.sm,
            icon: const Icon(Icons.download, size: 16),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                if (_error != null) ...[
                  CustomAlert(
                    message: _error!,
                    variant: AlertVariant.destructive,
                  ),
                  const SizedBox(height: 16),
                ],
                // Tabs
                Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        text: 'Project Details',
                        isActive: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TabButton(
                        text: 'Select Template',
                        isActive: _activeTab == 1,
                        onTap: _isDetailsValid
                            ? () => setState(() => _activeTab = 1)
                            : null,
                        isDisabled: !_isDetailsValid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (_activeTab == 0) _buildDetailsTab(),
                  if (_activeTab == 1) _buildTemplatesTab(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Customer Name *',
                  hint: 'Enter customer name',
                  controller: _customerNameController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Customer Zone *',
                  hint: 'Enter customer zone',
                  controller: _locationController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Part Name *',
                  hint: 'e.g., Bearing',
                  controller: _partNameController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Part Number *',
                  hint: 'Enter part number',
                  controller: _partNumberController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextInput(
                  label: 'Revision Number *',
                  hint: 'e.g., Rev 1.0',
                  controller: _revisionNumberController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revision Date *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _revisionDateController,
                      decoration: const InputDecoration(
                        hintText: 'Select date',
                        hintStyle: TextStyle(color: AppTheme.mutedForeground),
                        filled: true,
                        fillColor: AppTheme.inputBackground,
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        await _selectDate(context, _revisionDateController);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomDropdownButtonFormField<String>(
            label: 'Team Leader *',
            hint: 'Select team leader',
            value: _teamLeader.isEmpty ? null : _teamLeader,
            items: _teamLeaders.map((leader) {
              final fullName = leader['fullName'] as String? ?? '';
              final designation = leader['designation'] as String? ?? '';
              return DropdownMenuItem(
                value: fullName,
                child: Text('$fullName - $designation'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selectedLeader = _teamLeaders.firstWhere(
                  (l) => l['fullName'] == value,
                  orElse: () => {},
                );
                final leaderId = (selectedLeader['id'] ?? '').toString();
                setState(() {
                  _teamLeader = value;
                  _teamLeaderId = leaderId;
                });
                developer.log(
                  'Selected Team Leader ID: $_teamLeaderId',
                  name: 'EditProjectScreen',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          MultiSelectDropdown<Map<String, dynamic>>(
            label: 'Team Members',
            isRequired: false,
            options: _teamMembers
                .where((member) => member['designation'] != 'Team Leader')
                .toList(),
            selectedIds: _selectedMemberIds,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedMemberIds = selectedIds;
                _selectedMembers = _teamMembers
                    .where((member) {
                      final memberId = (member['id'] ?? '').toString();
                      return selectedIds.contains(memberId);
                    })
                    .map((member) => (member['fullName'] ?? '').toString())
                    .toList();
              });
              developer.log(
                'Selected Team Member IDs: $_selectedMemberIds',
                name: 'EditProjectScreen',
              );
            },
            getDisplayText: (member) => member['fullName'] as String? ?? '',
            getSubText: (member) => member['designation'] as String? ?? '',
            getId: (member) => (member['id'] ?? '').toString(),
            hintText: 'Select team members',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            label: 'Plan Number *',
                            hint: 'Enter plan number',
                            controller: _planNumberController,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date of Issue *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _dateOfIssueController,
                                decoration: const InputDecoration(
                                  hintText: 'Select date',
                                  filled: true,
                                  fillColor: AppTheme.inputBackground,
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  await _selectDate(
                                    context,
                                    _dateOfIssueController,
                                  );
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      label: 'Project Duration (Weeks) *',
                      hint: 'Enter duration in weeks',
                      controller: _totalWeeksController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextInput(
                        label: 'Plan Number *',
                        hint: 'Enter plan number',
                        controller: _planNumberController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Issue *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _dateOfIssueController,
                            decoration: const InputDecoration(
                              hintText: 'Select date',
                              filled: true,
                              fillColor: AppTheme.inputBackground,
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () async {
                              await _selectDate(
                                context,
                                _dateOfIssueController,
                              );
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextInput(
                        label: 'Project Duration (Weeks) *',
                        hint: 'Enter duration in weeks',
                        controller: _totalWeeksController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            label: 'Project Volume Per Year *',
                            hint: 'Enter volume per year',
                            controller: _projectVolumePerYearController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              _calculateProjectValue();
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextInput(
                            label: 'Value Per Part *',
                            hint: 'Enter value per part',
                            controller: _valuePerPartController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) {
                              _calculateProjectValue();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      label: 'Project Value Per Annum *',
                      hint: 'Auto-calculated',
                      controller: _projectValuePerAnnumController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: false,
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextInput(
                        label: 'Project Volume Per Year *',
                        hint: 'Enter volume per year',
                        controller: _projectVolumePerYearController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          _calculateProjectValue();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextInput(
                        label: 'Value Per Part *',
                        hint: 'Enter value per part',
                        controller: _valuePerPartController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) {
                          _calculateProjectValue();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextInput(
                        label: 'Project Value Per Annum *',
                        hint: 'Auto-calculated',
                        controller: _projectValuePerAnnumController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        enabled: false,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              text: 'Continue to Template',
              onPressed: _isDetailsValid
                  ? () => setState(() => _activeTab = 1)
                  : null,
              size: ButtonSize.lg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No templates available',
                        style: TextStyle(fontSize: 18, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please create templates first',
                        style: TextStyle(fontSize: 14, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 768;

                    if (isMobile) {
                      // Mobile: List view
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          final isSelected =
                              _selectedTemplate?.id == template.id;
                          final totalPhases = template.phases.length;
                          final totalActivities = template.phases.fold<int>(
                            0,
                            (sum, phase) => sum + phase.activities.length,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _selectTemplate(template),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              template.templateName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.gray900,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.layers_outlined,
                                            size: 16,
                                            color: AppTheme.gray600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$totalPhases ${totalPhases == 1 ? 'Phase' : 'Phases'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.checklist_outlined,
                                            size: 16,
                                            color: AppTheme.gray600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$totalActivities ${totalActivities == 1 ? 'Activity' : 'Activities'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (template.phases.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            ...template.phases.take(3).map((
                                              phase,
                                            ) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.gray100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  phase.name,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.gray700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }),
                                            if (template.phases.length > 3)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.gray100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '+${template.phases.length - 3} more',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.gray700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Web/Tablet: Grid view
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          final isSelected =
                              _selectedTemplate?.id == template.id;
                          final totalPhases = template.phases.length;
                          final totalActivities = template.phases.fold<int>(
                            0,
                            (sum, phase) => sum + phase.activities.length,
                          );

                          return InkWell(
                            onTap: () => _selectTemplate(template),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(
                                            0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            template.templateName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.gray900,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.layers_outlined,
                                          size: 16,
                                          color: AppTheme.gray600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$totalPhases ${totalPhases == 1 ? 'Phase' : 'Phases'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.checklist_outlined,
                                          size: 16,
                                          color: AppTheme.gray600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$totalActivities ${totalActivities == 1 ? 'Activity' : 'Activities'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    if (template.phases.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          ...template.phases.take(3).map((
                                            phase,
                                          ) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.gray100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                phase.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.gray700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }),
                                          if (template.phases.length > 3)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.gray100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '+${template.phases.length - 3} more',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.gray700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomButton(
              text: 'Back to Details',
              onPressed: () => setState(() => _activeTab = 0),
              variant: ButtonVariant.outline,
            ),
            CustomButton(
              text: 'Save Changes',
              onPressed: _isTemplateSelected ? _handleSave : null,
              size: ButtonSize.lg,
              icon: const Icon(Icons.save, size: 16, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _TabButton({
    required this.text,
    required this.isActive,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primary : AppTheme.border,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDisabled
                ? AppTheme.gray300
                : isActive
                ? AppTheme.primaryForeground
                : AppTheme.foreground,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppTheme.blue600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.gray500),
          ],
        ),
      ),
    );
  }
}
