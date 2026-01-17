import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/models.dart';
import '../models/additional_entities.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_select_dropdown.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final Function(Project project) onSave;
  final VoidCallback onCancel;

  const CreateProjectScreen({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  int _activeTab = 0;
  final ApiService _apiService = ApiService();

  // Project Details
  final _customerNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _partNameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _revisionNumberController = TextEditingController();
  final _planNumberController = TextEditingController();
  // REMOVED: final _authorizationController = TextEditingController();
  final _totalWeeksController = TextEditingController();
  final _projectVolumePerYearController = TextEditingController();
  final _valuePerPartController = TextEditingController();
  final _projectValuePerAnnumController = TextEditingController();

  // Revision Date: Default blank (empty text controller)
  final _revisionDateController = TextEditingController();
  // Date of Issue: Default to today's date
  final _dateOfIssueController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );

  String _teamLeader = '';
  String _teamLeaderId = ''; // Store team leader ID
  List<String> _selectedMembers = [];
  List<String> _selectedMemberIds = []; // Store selected member IDs

  // API Data
  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _teamLeaders = [];
  List<Map<String, dynamic>> _teamMembers = [];

  // Templates
  List<TemplateEntity> _templates = [];
  TemplateEntity? _selectedTemplate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _generatePlanNumber() async {
    try {
      final response = await _apiService.getProjects();

      List<dynamic> projects = [];
      if (response['apqpProjects'] != null) {
        projects = response['apqpProjects'] as List;
      } else if (response['projects'] != null) {
        projects = response['projects'] as List;
      } else if (response['data'] != null) {
        projects = response is List
            ? response as List<dynamic>
            : List<dynamic>.from(response['data'] as List);
      }

      developer.log(
        'Fetched ${projects.length} projects for plan number generation',
        name: 'CreateProjectScreen',
      );

      int maxNumber = 0;
      for (var project in projects) {
        final planNumber = (project['planNumber'] as String? ?? '')
            .toUpperCase();
        if (planNumber.startsWith('PLN-')) {
          final numberPart = planNumber.substring(4);
          // Only consider valid integers
          final number = int.tryParse(numberPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      // If found maxNumber is 0 (no projects) or random large numbers existed but we want to confirm sequence
      // The logic is simply max + 1.
      // If previous was PLN-1234 (random), next is PLN-1235.
      // If user wants to reset to PLN-1, they must clear the DB or we'd need to ignore >1000?
      // Assuming straightforward max+1 for safety.

      if (mounted) {
        setState(() {
          _planNumberController.text = 'PLN-${maxNumber + 1}';
        });
        developer.log(
          'Generated Plan Number: ${_planNumberController.text} (Max found: $maxNumber)',
          name: 'CreateProjectScreen',
        );
      }
    } catch (e) {
      developer.log(
        'Error generating plan number: $e',
        name: 'CreateProjectScreen',
      );
      // Fallback to PLN-1 if fetch fails
      if (mounted) {
        setState(() {
          _planNumberController.text = 'PLN-1';
        });
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
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
          // Display all staff EXCEPT Team Leaders
          _teamMembers = allStaff
              .where((s) => s['designation'] != 'Team Leader')
              .toList();
        });
      }

      // Fetch templates
      final templatesResponse = await _apiService.getTemplates();
      developer.log(
        'Templates response: $templatesResponse',
        name: 'CreateProjectScreen',
      );

      if (templatesResponse['templates'] != null) {
        final templatesData = templatesResponse['templates'] is List
            ? templatesResponse['templates']
            : [templatesResponse['templates']];

        developer.log(
          'Templates data: $templatesData',
          name: 'CreateProjectScreen',
        );

        final parsedTemplates = <TemplateEntity>[];
        for (final json in templatesData) {
          try {
            final template = TemplateEntity.fromJson(json);
            developer.log(
              'Parsed template: ${template.templateName}, status: ${template.status}, phases: ${template.phases.length}',
              name: 'CreateProjectScreen',
            );
            parsedTemplates.add(template);
          } catch (e, stackTrace) {
            developer.log(
              'Error parsing template: $e\nStack trace: $stackTrace\nJSON: $json',
              name: 'CreateProjectScreen',
              error: e,
            );
          }
        }

        setState(() {
          _templates = parsedTemplates
              .where((t) => t.status == 'active') // Only show active templates
              .toList();
        });

        developer.log(
          'Final templates list: ${_templates.length}',
          name: 'CreateProjectScreen',
        );
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
              name: 'CreateProjectScreen',
              error: e,
            );
          }
        }

        setState(() {
          _templates = parsedTemplates
              .where((t) => t.status == 'active') // Only show active templates
              .toList();
        });
      }

      // Generate Plan Number
      await _generatePlanNumber();
    } catch (e) {
      developer.log('Error fetching data: $e', name: 'CreateProjectScreen');
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

  @override
  void dispose() {
    _customerNameController.dispose();
    _locationController.dispose();
    _partNameController.dispose();
    _partNumberController.dispose();
    _revisionNumberController.dispose();
    _planNumberController.dispose();
    // REMOVED: _authorizationController.dispose();
    _totalWeeksController.dispose();
    _projectVolumePerYearController.dispose();
    _valuePerPartController.dispose();
    _projectValuePerAnnumController.dispose();

    // Dispose date controllers
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
      _revisionNumberController.text.trim().isNotEmpty &&
      _revisionDateController.text.trim().isNotEmpty &&
      _teamLeader.isNotEmpty &&
      _selectedMemberIds.isNotEmpty &&
      _planNumberController.text.trim().isNotEmpty &&
      _dateOfIssueController.text.trim().isNotEmpty &&
      _totalWeeks > 0 &&
      _projectVolumePerYearController.text.trim().isNotEmpty &&
      _valuePerPartController.text.trim().isNotEmpty &&
      _projectValuePerAnnumController.text.trim().isNotEmpty;

  // Helper method to convert date string to ISO format
  String _convertToIsoDate(String dateString) {
    if (dateString.isEmpty) {
      // If empty, use today's date
      return DateTime.now().toUtc().toIso8601String();
    }
    try {
      // Parse the date string (format: YYYY-MM-DD)
      final dateParts = dateString.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        // Create UTC date at midnight
        final date = DateTime.utc(year, month, day);
        return date.toIso8601String();
      }
      // Fallback to tryParse if format is different
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        return date.toUtc().toIso8601String();
      }
      // If parsing fails, use today's date as fallback
      return DateTime.now().toUtc().toIso8601String();
    } catch (e) {
      // If error, use today's date as fallback
      return DateTime.now().toUtc().toIso8601String();
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

  // Validation: Check that a template is selected
  bool get _isTemplateSelected => _selectedTemplate != null;

  void _selectTemplate(TemplateEntity template) {
    setState(() {
      _selectedTemplate = template;
    });
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

    // Show loading indicator
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
        // REMOVED: 'teamLeaderAuthorization': _authorizationController.text.trim(),
        'totalNumberOfWeeks': _totalWeeks,
        'projectVolumePerYear': projectVolumePerYear,
        'valuePerPart': valuePerPart,
        'projectValuePerAnnum': projectValuePerAnnum,
        'template': _selectedTemplate!.id, // Send template ID instead of phases
      };

      // Call API
      final response = await _apiService.createProject(
        projectData: projectData,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Create Project object for callback (if needed)
        final project = Project(
          id: response['apqpProject']?['_id'] ?? '',
          customerName: _customerNameController.text,
          location: _locationController.text,
          partName: _partNameController.text,
          partNumber: _partNumberController.text,
          revisionNumber: _revisionNumberController.text,
          revisionDate: _revisionDateController.text,
          teamLeader: _teamLeader,
          teamMembers: _selectedMembers.map((id) {
            final member = _allStaff.firstWhere(
              (m) => m['id'] == id,
              orElse: () => {'fullName': id},
            );
            return member['fullName'] as String? ?? id;
          }).toList(),
          planNumber: _planNumberController.text,
          dateOfIssue: _dateOfIssueController.text,
          // REMOVED: teamLeaderAuthorization: _authorizationController.text,
          teamLeaderAuthorization: '', // Set to empty string
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
          createdAt: response['apqpProject']?['createdAt'] ?? '',
          progress: 0,
          projectStatus: response['apqpProject']?['projectStatus'] ?? 'ongoing',
        );
        widget.onSave(project);
      }
    } catch (e) {
      developer.log('Error creating project: $e', name: 'CreateProjectScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: ${e.toString()}'),
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
        title: const Text(
          'Create New Project',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
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
                // This field is REQUIRED (*)
                child: CustomTextInput(
                  label: 'Customer Name',
                  isRequired: true,
                  hint: 'Enter customer name',
                  controller: _customerNameController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextInput(
                  label: 'Customer Zone',
                  isRequired: true,
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
                // This field is REQUIRED (*)
                child: CustomTextInput(
                  label: 'Part Name',
                  isRequired: true,
                  hint: 'e.g., Bearing',
                  controller: _partNameController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                // This field is REQUIRED (*)
                child: CustomTextInput(
                  label: 'Part Number',
                  isRequired: false,
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
                  label: 'Revision Number',
                  isRequired: true,
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
                    RichText(
                      text: const TextSpan(
                        text: 'Revision Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foreground,
                        ),
                        children: [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Color.fromARGB(255, 114, 112, 113),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          _revisionDateController, // Use controller (blank default)
                      decoration: const InputDecoration(
                        hintText: 'Select date',
                        hintStyle: TextStyle(color: AppTheme.mutedForeground),
                        filled: true,
                        fillColor: AppTheme.inputBackground,
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: AppTheme.gray500,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        await _selectDate(
                          context,
                          _revisionDateController,
                        ); // Use helper function
                        setState(() {}); // Trigger rebuild to update validation
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomDropdownButtonFormField<String>(
            label: 'Team Leader',
            isRequired: true,
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
            // Use setState on change to re-evaluate _isDetailsValid
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
                // Print selected team leader ID
                developer.log(
                  'Selected Team Leader ID: $_teamLeaderId',
                  name: 'CreateProjectScreen',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          MultiSelectDropdown<Map<String, dynamic>>(
            label: 'Team Members',
            isRequired: true,
            options: _teamMembers
                .where((member) => member['designation'] != 'Team Leader')
                .toList(),
            selectedIds: _selectedMemberIds,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedMemberIds = selectedIds;
                // Update _selectedMembers for display purposes
                _selectedMembers = _teamMembers
                    .where((member) {
                      final memberId = (member['id'] ?? '').toString();
                      return selectedIds.contains(memberId);
                    })
                    .map((member) => (member['id'] ?? '').toString())
                    .toList();
              });
              developer.log(
                'Selected Team Member IDs: $_selectedMemberIds',
                name: 'CreateProjectScreen',
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
                            isRequired: true,
                            readOnly: true,
                            label: 'Plan Number',
                            hint: 'Enter plan number',
                            controller: _planNumberController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  text: 'Date of Issue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.foreground,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          114,
                                          112,
                                          113,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                  suffixIcon: Icon(
                                    Icons.calendar_month,
                                    color: AppTheme.gray500,
                                  ),
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
                      label: 'Project Duration (Weeks)',
                      hint: 'Enter duration in weeks',
                      isRequired: true,
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
                        label: 'Plan Number',
                        isRequired: true,
                        readOnly: true,
                        hint: 'Enter plan number',
                        controller: _planNumberController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              text: 'Date of Issue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                              children: [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 114, 112, 113),
                                  ),
                                ),
                              ],
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
                              suffixIcon: Icon(
                                Icons.calendar_month,
                                color: AppTheme.gray500,
                              ),
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
                        label: 'Project Duration (Weeks)',
                        isRequired: true,
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
          // REMOVED: Team Leader Authorization Text Input
          // const SizedBox(height: 16),
          // CustomTextInput(
          //   label: 'Team Leader Authorization', // This field is OPTIONAL
          //   hint: 'Signature or name',
          //   controller: _authorizationController,
          // ),
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
                            label: 'Project Volume Per Year',
                            isRequired: true,
                            hint: 'Enter volume per year',
                            controller: _projectVolumePerYearController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateProjectValue(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextInput(
                            label: 'Value Per Part',
                            isRequired: true,
                            hint: 'Enter value per part',
                            controller: _valuePerPartController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _calculateProjectValue(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      label: 'Project Value Per Annum',
                      isRequired: true,
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
                        label: 'Project Volume Per Year',
                        isRequired: true,
                        hint: 'Enter volume per year',
                        controller: _projectVolumePerYearController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateProjectValue(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextInput(
                        label: 'Value Per Part',
                        isRequired: true,
                        hint: 'Enter value per part',
                        controller: _valuePerPartController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _calculateProjectValue(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextInput(
                        label: 'Project Value Per Annum',
                        isRequired: true,
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
              text: 'Continue to Phases',
              // Button relies only on the 5 starred required fields
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
                      // Web: Grid view
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
              text: 'Create Project',
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
