import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../bloc/entity/entity_bloc.dart';
import '../bloc/entity/entity_event.dart';
import '../bloc/entity/entity_state.dart';
import '../models/additional_entities.dart';
import 'search_dialog.dart';

class EntityDetailDialog extends StatefulWidget {
  final EntityType entityType;

  const EntityDetailDialog({super.key, required this.entityType});

  @override
  State<EntityDetailDialog> createState() => _EntityDetailDialogState();
}

class _EntityDetailDialogState extends State<EntityDetailDialog> {
  final TextEditingController _nameController = TextEditingController();
  // Staff form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _staffSearchController = TextEditingController();
  final TextEditingController _simpleSearchController = TextEditingController();
  bool _showStaffForm = false;
  String? _editingStaffId;
  String _selectedStatus = 'active';
  String? _selectedDesignationId;
  String? _selectedZoneId;
  String? _selectedDepartmentId;

  String? _selectedRole;
  String? _selectedWorkCategoryId;

  // Template state
  final TextEditingController _templateNameController = TextEditingController();
  String? _editingTemplateId;

  String _currentTemplatePhaseName = '';
  String? _currentTemplatePhaseId;
  final TextEditingController _currentTemplatePhaseNameController =
      TextEditingController();
  List<Map<String, dynamic>> _currentTemplateActivities = [];

  List<Map<String, dynamic>> _savedTemplatePhases = [];

  final Map<String, TextEditingController> _currentTemplateActivityControllers =
      {};

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str
        .toLowerCase()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();

    _designationController.dispose();
    _zoneController.dispose();
    _departmentController.dispose();
    _staffSearchController.dispose();
    _simpleSearchController.dispose();
    _templateNameController.dispose();
    _currentTemplatePhaseNameController.dispose();
    for (var controller in _currentTemplateActivityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _title {
    switch (widget.entityType) {
      case EntityType.designation:
        return 'Designation';
      case EntityType.zone:
        return 'Zone';
      case EntityType.department:
        return 'Department';
      case EntityType.phase:
        return 'Phase';
      case EntityType.staff:
        return 'Staff';
      case EntityType.activity:
        return 'Activity';
      case EntityType.template:
        return 'Template';
      case EntityType.workCategory:
        return 'Work Category';
    }
  }

  IconData get _icon {
    switch (widget.entityType) {
      case EntityType.designation:
        return Icons.work_outline;
      case EntityType.zone:
        return Icons.location_on_outlined;
      case EntityType.department:
        return Icons.business_outlined;
      case EntityType.phase:
        return Icons.timeline_outlined;
      case EntityType.staff:
        return Icons.people_outline;
      case EntityType.activity:
        return Icons.task_alt_outlined;
      case EntityType.template:
        return Icons.description_outlined;
      case EntityType.workCategory:
        return Icons.category_outlined;
    }
  }

  List<dynamic> _getEntities(EntityState state) {
    switch (widget.entityType) {
      case EntityType.designation:
        return state.designations;
      case EntityType.zone:
        return state.zones;
      case EntityType.department:
        return state.departments;
      case EntityType.phase:
        return state.phases;
      case EntityType.staff:
        return state.staff;
      case EntityType.activity:
        return state.activities;
      case EntityType.template:
        return state.templates;
      case EntityType.workCategory:
        return state.workCategories;
    }
  }

  void _loadEntities(BuildContext context) {
    switch (widget.entityType) {
      case EntityType.designation:
        context.read<EntityBloc>().add(const LoadDesignations());
        break;
      case EntityType.zone:
        context.read<EntityBloc>().add(const LoadZones());
        break;
      case EntityType.department:
        context.read<EntityBloc>().add(const LoadDepartments());
        break;
      case EntityType.phase:
        context.read<EntityBloc>().add(const LoadPhases());
        break;
      case EntityType.staff:
        context.read<EntityBloc>().add(const LoadStaff());
        break;
      case EntityType.activity:
        context.read<EntityBloc>().add(const LoadActivities());
        break;
      case EntityType.template:
        context.read<EntityBloc>().add(const LoadTemplates());
        break;
      case EntityType.workCategory:
        context.read<EntityBloc>().add(const LoadWorkCategories());
        break;
    }
  }

  void _createEntity(BuildContext context) {
    switch (widget.entityType) {
      case EntityType.designation:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(
          CreateDesignation(name: name, status: status),
        );
        break;
      case EntityType.zone:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(CreateZone(name: name, status: status));
        break;
      case EntityType.department:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(
          CreateDepartment(name: name, status: status),
        );
        break;
      case EntityType.phase:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(CreatePhase(name: name, status: status));
        break;
      case EntityType.activity:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(
          CreateActivityEntity(name: name, status: status),
        );
        break;
      case EntityType.staff:
        final data = {
          'firstName': _toTitleCase(_firstNameController.text.trim()),
          'lastName': _toTitleCase(_lastNameController.text.trim()),
          'mobile': _mobileController.text.trim(),
          'email': _emailController.text.trim(),

          'designation': _selectedDesignationId?.trim() ?? '',
          'zone': _selectedZoneId?.trim() ?? '',
          'department': _selectedDepartmentId?.trim() ?? '',
          'role': _selectedRole?.trim() ?? '',
        };
        // Basic validation for required fields including dropdowns
        if (data.values.any((v) => v == null || (v is String && v.isEmpty))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all staff fields'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        if (_editingStaffId != null && _editingStaffId!.isNotEmpty) {
          context.read<EntityBloc>().add(
            UpdateStaff(id: _editingStaffId!, staffData: data),
          );
        } else {
          context.read<EntityBloc>().add(CreateStaff(staffData: data));
        }
        // Hide form after submit
        setState(() {
          _showStaffForm = false;
          _editingStaffId = null;
          _selectedDesignationId = null;
          _selectedZoneId = null;
          _selectedDepartmentId = null;
        });
        break;
      case EntityType.template:
        // Template creation is handled in _openTemplateAddDialog
        break;
      case EntityType.workCategory:
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a name'),
              backgroundColor: AppTheme.red500,
            ),
          );
          return;
        }
        final name = _toTitleCase(_nameController.text.trim());
        final status = _selectedStatus;
        context.read<EntityBloc>().add(
          CreateWorkCategory(name: name, status: status),
        );
        break;
    }

    // Clear form after dispatching event
    _nameController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _emailController.clear();

    _designationController.clear();
    _zoneController.clear();
    _departmentController.clear();
    setState(() {
      _selectedStatus = 'active';
      _selectedDesignationId = null;
      _selectedZoneId = null;
      _selectedDepartmentId = null;
    });
  }

  void _updateEntityStatus(BuildContext context, String id, String status) {
    switch (widget.entityType) {
      case EntityType.designation:
        context.read<EntityBloc>().add(
          UpdateDesignationStatus(id: id, status: status),
        );
        break;
      case EntityType.zone:
        context.read<EntityBloc>().add(
          UpdateZoneStatus(id: id, status: status),
        );
        break;
      case EntityType.department:
        context.read<EntityBloc>().add(
          UpdateDepartmentStatus(id: id, status: status),
        );
        break;
      case EntityType.phase:
        context.read<EntityBloc>().add(
          UpdatePhaseStatus(id: id, status: status),
        );
        break;
      case EntityType.staff:
        context.read<EntityBloc>().add(
          UpdateStaffStatus(id: id, status: status),
        );
        break;
      case EntityType.activity:
        context.read<EntityBloc>().add(
          UpdateActivityStatus(id: id, status: status),
        );
        break;
      case EntityType.template:
        context.read<EntityBloc>().add(
          UpdateTemplateStatus(id: id, status: status),
        );
        break;
      case EntityType.workCategory:
        context.read<EntityBloc>().add(
          UpdateWorkCategoryStatus(id: id, status: status),
        );
        break;
    }
  }

  void _deleteEntity(BuildContext context, String id) {
    final entityBloc = context.read<EntityBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              switch (widget.entityType) {
                case EntityType.designation:
                  entityBloc.add(DeleteDesignation(id: id));
                  break;
                case EntityType.zone:
                  entityBloc.add(DeleteZone(id: id));
                  break;
                case EntityType.department:
                  entityBloc.add(DeleteDepartment(id: id));
                  break;
                case EntityType.phase:
                  entityBloc.add(DeletePhase(id: id));
                  break;
                case EntityType.staff:
                  entityBloc.add(DeleteStaff(id: id));
                  break;
                case EntityType.activity:
                  entityBloc.add(DeleteActivityEntity(id: id));
                  break;
                case EntityType.template:
                  entityBloc.add(DeleteTemplate(id: id));
                  break;
                case EntityType.workCategory:
                  entityBloc.add(DeleteWorkCategory(id: id));
                  break;
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.red500),
            ),
          ),
        ],
      ),
    );
  }

  void _openStaffAddDialog() {
    _editingStaffId = null;
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _emailController.clear();

    _selectedDesignationId = null;
    _selectedZoneId = null;
    _selectedDepartmentId = null;

    _selectedRole = null;
    _selectedWorkCategoryId = null;
    final bloc = context.read<EntityBloc>();
    // Load work categories for manager role
    bloc.add(const LoadWorkCategories());
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: BlocProvider.value(
            value: bloc,
            child: BlocListener<EntityBloc, EntityState>(
              listenWhen: (previous, current) {
                // Only listen when isCreating changes from true to false
                return previous.isCreating && !current.isCreating;
              },
              listener: (context, state) {
                if (state.errorMessage == null || state.errorMessage!.isEmpty) {
                  Navigator.of(ctx).pop();
                }
              },
              child: Container(
                constraints: const BoxConstraints.tightFor(
                  width: 1000,
                  height: 800,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    final state = context.watch<EntityBloc>().state;
                    return Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: AppTheme.gray900,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Add Staff',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.gray600,
                                    ),
                                    onPressed: state.isCreating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextInput(
                                      label: 'First Name',
                                      controller: _firstNameController,
                                      hint: 'Enter first name',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Last Name',
                                      controller: _lastNameController,
                                      hint: 'Enter last name',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Mobile',
                                      controller: _mobileController,
                                      hint: 'Enter mobile',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Email',
                                      controller: _emailController,
                                      hint: 'Enter email',
                                    ),
                                    const SizedBox(height: 12),

                                    CustomDropdownButtonFormField<String>(
                                      label: 'Designation',
                                      hint: 'Select designation',
                                      value:
                                          state.designations.any(
                                            (d) =>
                                                d.id == _selectedDesignationId,
                                          )
                                          ? _selectedDesignationId
                                          : null,
                                      items: state.designations
                                          .map(
                                            (d) => DropdownMenuItem(
                                              value: d.id,
                                              child: Text(d.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedDesignationId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Zone',
                                      hint: 'Select zone',
                                      value:
                                          state.zones.any(
                                            (z) => z.id == _selectedZoneId,
                                          )
                                          ? _selectedZoneId
                                          : null,
                                      items: state.zones
                                          .map(
                                            (z) => DropdownMenuItem(
                                              value: z.id,
                                              child: Text(z.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedZoneId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Department',
                                      hint: 'Select department',
                                      value:
                                          state.departments.any(
                                            (d) =>
                                                d.id == _selectedDepartmentId,
                                          )
                                          ? _selectedDepartmentId
                                          : null,
                                      items: state.departments
                                          .map(
                                            (d) => DropdownMenuItem(
                                              value: d.id,
                                              child: Text(d.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedDepartmentId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Role',
                                      hint: 'Select role',
                                      value: _selectedRole,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'staff',
                                          child: Text('Staff'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'manager',
                                          child: Text('Manager'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'worker',
                                          child: Text('Worker'),
                                        ),
                                      ],
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedRole = val,
                                      ),
                                    ),
                                    if (_selectedRole == 'manager') ...[
                                      const SizedBox(height: 12),
                                      CustomDropdownButtonFormField<String>(
                                        label: 'Work Category',
                                        hint: 'Select work category',
                                        value:
                                            state.workCategories.any(
                                              (wc) =>
                                                  wc.id ==
                                                  _selectedWorkCategoryId,
                                            )
                                            ? _selectedWorkCategoryId
                                            : null,
                                        items: state.workCategories
                                            .map(
                                              (wc) => DropdownMenuItem(
                                                value: wc.id,
                                                child: Text(wc.name),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setStateDialog(
                                          () => _selectedWorkCategoryId = val,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: state.isCreating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  CustomButton(
                                    text: 'Add',
                                    onPressed: state.isCreating
                                        ? null
                                        : () {
                                            final data = {
                                              'firstName': _toTitleCase(
                                                _firstNameController.text
                                                    .trim(),
                                              ),
                                              'lastName': _toTitleCase(
                                                _lastNameController.text.trim(),
                                              ),
                                              'mobile': _mobileController.text
                                                  .trim(),
                                              'email': _emailController.text
                                                  .trim(),

                                              'designation':
                                                  _selectedDesignationId
                                                      ?.trim() ??
                                                  '',
                                              'zone':
                                                  _selectedZoneId?.trim() ?? '',
                                              'department':
                                                  _selectedDepartmentId
                                                      ?.trim() ??
                                                  '',
                                              'role':
                                                  _selectedRole?.trim() ?? '',
                                              if (_selectedRole == 'manager')
                                                'workCategory':
                                                    _selectedWorkCategoryId
                                                        ?.trim() ??
                                                    '',
                                            };
                                            // Check required fields
                                            final requiredFields = [
                                              'firstName',
                                              'lastName',
                                              'mobile',
                                              'email',

                                              'designation',
                                              'zone',
                                              'department',
                                              'role',
                                            ];
                                            if (_selectedRole == 'manager') {
                                              requiredFields.add(
                                                'workCategory',
                                              );
                                            }
                                            if (requiredFields.any((field) {
                                              final value = data[field];
                                              return value == null ||
                                                  (value is String &&
                                                      value.isEmpty);
                                            })) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please fill all staff fields',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }
                                            context.read<EntityBloc>().add(
                                              CreateStaff(staffData: data),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Loading overlay
                        if (state.isCreating)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openStaffEditDialog(dynamic entity) {
    _editingStaffId = entity.id;
    _firstNameController.text = entity.firstName ?? '';
    _lastNameController.text = entity.lastName ?? '';
    _mobileController.text = entity.mobile ?? '';
    _emailController.text = entity.email ?? '';

    _selectedDesignationId = entity.designation?.toString();
    _selectedZoneId = entity.zone?.toString();
    _selectedDepartmentId = entity.department?.toString();
    _selectedRole = entity.role?.toString();
    _selectedWorkCategoryId = entity.workCategory?.toString();

    final bloc = context.read<EntityBloc>();
    // Load required data for edit form
    bloc.add(const LoadDesignations());
    bloc.add(const LoadZones());
    bloc.add(const LoadDepartments());
    bloc.add(const LoadWorkCategories());
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: BlocProvider.value(
            value: bloc,
            child: MultiBlocListener(
              listeners: [
                // Listener for closing dialog after successful update
                BlocListener<EntityBloc, EntityState>(
                  listenWhen: (previous, current) {
                    return previous.isUpdating && !current.isUpdating;
                  },
                  listener: (context, state) {
                    if (state.errorMessage == null ||
                        state.errorMessage!.isEmpty) {
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
                // Listener for mapping names to IDs when data loads
                BlocListener<EntityBloc, EntityState>(
                  listenWhen: (previous, current) {
                    return previous.designations != current.designations ||
                        previous.zones != current.zones ||
                        previous.departments != current.departments ||
                        previous.workCategories != current.workCategories;
                  },
                  listener: (context, state) {
                    // Map names to IDs if values aren't valid IDs
                    if (_selectedDesignationId != null &&
                        !state.designations.any(
                          (d) => d.id == _selectedDesignationId,
                        )) {
                      for (final d in state.designations) {
                        if (d.name == _selectedDesignationId) {
                          _selectedDesignationId = d.id;
                          break;
                        }
                      }
                    }
                    if (_selectedZoneId != null &&
                        !state.zones.any((z) => z.id == _selectedZoneId)) {
                      for (final z in state.zones) {
                        if (z.name == _selectedZoneId) {
                          _selectedZoneId = z.id;
                          break;
                        }
                      }
                    }
                    if (_selectedDepartmentId != null &&
                        !state.departments.any(
                          (d) => d.id == _selectedDepartmentId,
                        )) {
                      for (final d in state.departments) {
                        if (d.name == _selectedDepartmentId) {
                          _selectedDepartmentId = d.id;
                          break;
                        }
                      }
                    }
                    if (_selectedWorkCategoryId != null &&
                        !state.workCategories.any(
                          (wc) => wc.id == _selectedWorkCategoryId,
                        )) {
                      for (final wc in state.workCategories) {
                        if (wc.name == _selectedWorkCategoryId) {
                          _selectedWorkCategoryId = wc.id;
                          break;
                        }
                      }
                    }
                  },
                ),
              ],
              child: Container(
                constraints: const BoxConstraints.tightFor(
                  width: 1000,
                  height: 800,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    final state = context.watch<EntityBloc>().state;
                    return Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: AppTheme.gray900,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Edit Staff',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.gray600,
                                    ),
                                    onPressed: state.isUpdating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextInput(
                                      label: 'First Name',
                                      controller: _firstNameController,
                                      hint: 'Enter first name',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Last Name',
                                      controller: _lastNameController,
                                      hint: 'Enter last name',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Mobile',
                                      controller: _mobileController,
                                      hint: 'Enter mobile',
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextInput(
                                      label: 'Email',
                                      controller: _emailController,
                                      hint: 'Enter email',
                                    ),
                                    const SizedBox(height: 12),

                                    CustomDropdownButtonFormField<String>(
                                      label: 'Designation',
                                      hint: 'Select designation',
                                      value:
                                          state.designations.any(
                                            (d) =>
                                                d.id == _selectedDesignationId,
                                          )
                                          ? _selectedDesignationId
                                          : null,
                                      items: state.designations
                                          .map(
                                            (d) => DropdownMenuItem(
                                              value: d.id,
                                              child: Text(d.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedDesignationId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Zone',
                                      hint: 'Select zone',
                                      value:
                                          state.zones.any(
                                            (z) => z.id == _selectedZoneId,
                                          )
                                          ? _selectedZoneId
                                          : null,
                                      items: state.zones
                                          .map(
                                            (z) => DropdownMenuItem(
                                              value: z.id,
                                              child: Text(z.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedZoneId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Department',
                                      hint: 'Select department',
                                      value:
                                          state.departments.any(
                                            (d) =>
                                                d.id == _selectedDepartmentId,
                                          )
                                          ? _selectedDepartmentId
                                          : null,
                                      items: state.departments
                                          .map(
                                            (d) => DropdownMenuItem(
                                              value: d.id,
                                              child: Text(d.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedDepartmentId = val,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomDropdownButtonFormField<String>(
                                      label: 'Role',
                                      hint: 'Select role',
                                      value: _selectedRole,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'staff',
                                          child: Text('Staff'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'manager',
                                          child: Text('Manager'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'worker',
                                          child: Text('Worker'),
                                        ),
                                      ],
                                      onChanged: (val) => setStateDialog(
                                        () => _selectedRole = val,
                                      ),
                                    ),
                                    if (_selectedRole == 'manager') ...[
                                      const SizedBox(height: 12),
                                      CustomDropdownButtonFormField<String>(
                                        label: 'Work Category',
                                        hint: 'Select work category',
                                        value:
                                            state.workCategories.any(
                                              (wc) =>
                                                  wc.id ==
                                                  _selectedWorkCategoryId,
                                            )
                                            ? _selectedWorkCategoryId
                                            : null,
                                        items: state.workCategories
                                            .map(
                                              (wc) => DropdownMenuItem(
                                                value: wc.id,
                                                child: Text(wc.name),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setStateDialog(
                                          () => _selectedWorkCategoryId = val,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: state.isUpdating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  CustomButton(
                                    text: 'Update',
                                    onPressed: state.isUpdating
                                        ? null
                                        : () {
                                            final data = {
                                              'firstName': _toTitleCase(
                                                _firstNameController.text
                                                    .trim(),
                                              ),
                                              'lastName': _toTitleCase(
                                                _lastNameController.text.trim(),
                                              ),
                                              'mobile': _mobileController.text
                                                  .trim(),
                                              'email': _emailController.text
                                                  .trim(),

                                              'designation':
                                                  _selectedDesignationId
                                                      ?.trim() ??
                                                  '',
                                              'zone':
                                                  _selectedZoneId?.trim() ?? '',
                                              'department':
                                                  _selectedDepartmentId
                                                      ?.trim() ??
                                                  '',
                                              'role':
                                                  _selectedRole?.trim() ?? '',
                                              if (_selectedRole == 'manager')
                                                'workCategory':
                                                    _selectedWorkCategoryId
                                                        ?.trim() ??
                                                    '',
                                            };
                                            // Check required fields
                                            final requiredFields = [
                                              'firstName',
                                              'lastName',
                                              'mobile',
                                              'email',

                                              'designation',
                                              'zone',
                                              'department',
                                              'role',
                                            ];
                                            if (_selectedRole == 'manager') {
                                              requiredFields.add(
                                                'workCategory',
                                              );
                                            }
                                            if (requiredFields.any((field) {
                                              final value = data[field];
                                              return value == null ||
                                                  (value is String &&
                                                      value.isEmpty);
                                            })) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please fill all staff fields',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }
                                            context.read<EntityBloc>().add(
                                              UpdateStaff(
                                                id: _editingStaffId!,
                                                staffData: data,
                                              ),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Loading overlay
                        if (state.isUpdating)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntities(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints.tightFor(width: 800, height: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(_icon, color: AppTheme.gray900, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.gray600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Toolbar + Conditional Form (Staff) / Search only (others)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.entityType == EntityType.staff) ...[
                        CustomTextInput(
                          label: 'Search staff',
                          controller: _staffSearchController,
                          hint: 'Search by name, email, mobile',
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 16),
                      ] else ...[
                        CustomTextInput(
                          label: 'Search',
                          controller: _simpleSearchController,
                          hint: 'Search ${_title.toLowerCase()} by name',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),
                // List
                Flexible(
                  child: BlocConsumer<EntityBloc, EntityState>(
                    listener: (context, state) {
                      final msg = state.errorMessage;
                      if (msg != null && msg.isNotEmpty) {
                        final isSuccess = msg.toLowerCase().contains('success');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: isSuccess
                                ? AppTheme.green600
                                : AppTheme.red500,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      var entities = _getEntities(state);
                      if (widget.entityType == EntityType.staff &&
                          _staffSearchController.text.trim().isNotEmpty) {
                        final q = _staffSearchController.text
                            .trim()
                            .toLowerCase();
                        entities = entities.where((e) {
                          final fn = (e.firstName ?? '')
                              .toString()
                              .toLowerCase();
                          final ln = (e.lastName ?? '')
                              .toString()
                              .toLowerCase();
                          final em = (e.email ?? '').toString().toLowerCase();
                          final mb = (e.mobile ?? '').toString().toLowerCase();
                          return fn.contains(q) ||
                              ln.contains(q) ||
                              em.contains(q) ||
                              mb.contains(q);
                        }).toList();
                      } else if (widget.entityType != EntityType.staff &&
                          widget.entityType != EntityType.template &&
                          _simpleSearchController.text.trim().isNotEmpty) {
                        final q = _simpleSearchController.text
                            .trim()
                            .toLowerCase();
                        entities = entities.where((e) {
                          final name = (e.name ?? '').toString().toLowerCase();
                          return name.contains(q);
                        }).toList();
                      } else if (widget.entityType == EntityType.template &&
                          _simpleSearchController.text.trim().isNotEmpty) {
                        final q = _simpleSearchController.text
                            .trim()
                            .toLowerCase();
                        entities = entities.where((e) {
                          final template = e as TemplateEntity;
                          final name = (template.templateName ?? '')
                              .toString()
                              .toLowerCase();
                          return name.contains(q);
                        }).toList();
                      }

                      if (state.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (entities.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: AppTheme.gray300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No ${_title.toLowerCase()}s found',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: entities.length,
                        itemBuilder: (context, index) {
                          final entity = entities[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.entityType == EntityType.staff
                                              ? '${entity.firstName} ${entity.lastName}'
                                                    .trim()
                                              : widget.entityType ==
                                                    EntityType.template
                                              ? (entity as TemplateEntity)
                                                    .templateName
                                              : entity.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (entity.status ?? 'active') ==
                                                    'active'
                                                ? AppTheme.green100
                                                : AppTheme.gray200,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            (entity.status ?? 'active')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  (entity.status ?? 'active') ==
                                                      'active'
                                                  ? AppTheme.green600
                                                  : AppTheme.gray600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildActionButtons(context, entity),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () {
                  if (widget.entityType == EntityType.staff) {
                    context.read<EntityBloc>().add(const LoadDesignations());
                    context.read<EntityBloc>().add(const LoadZones());
                    context.read<EntityBloc>().add(const LoadDepartments());
                    _openStaffAddDialog();
                  } else if (widget.entityType == EntityType.template) {
                    context.read<EntityBloc>().add(const LoadPhases());
                    context.read<EntityBloc>().add(const LoadActivities());
                    context.read<EntityBloc>().add(const LoadStaff());
                    _openTemplateAddDialog();
                  } else {
                    _openSimpleAddDialog();
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSimpleAddDialog() {
    _nameController.clear();
    _selectedStatus = 'active';
    final entityBloc = context.read<EntityBloc>();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 800, height: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppTheme.gray900,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add ${_title}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.gray600,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextInput(
                              label: 'Name',
                              controller: _nameController,
                              hint: 'Enter ${_title.toLowerCase()} name',
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatusChip(
                                    label: 'Active',
                                    isSelected: _selectedStatus == 'active',
                                    onTap: () {
                                      setStateDialog(() {
                                        _selectedStatus = 'active';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatusChip(
                                    label: 'Inactive',
                                    isSelected: _selectedStatus == 'inactive',
                                    onTap: () {
                                      setStateDialog(() {
                                        _selectedStatus = 'inactive';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'Add',
                            onPressed: () {
                              if (_nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a name'),
                                    backgroundColor: AppTheme.red500,
                                  ),
                                );
                                return;
                              }
                              final name = _toTitleCase(
                                _nameController.text.trim(),
                              );
                              final status = _selectedStatus;
                              switch (widget.entityType) {
                                case EntityType.designation:
                                  entityBloc.add(
                                    CreateDesignation(
                                      name: name,
                                      status: status,
                                    ),
                                  );
                                  break;
                                case EntityType.zone:
                                  entityBloc.add(
                                    CreateZone(name: name, status: status),
                                  );
                                  break;
                                case EntityType.department:
                                  entityBloc.add(
                                    CreateDepartment(
                                      name: name,
                                      status: status,
                                    ),
                                  );
                                  break;
                                case EntityType.phase:
                                  entityBloc.add(
                                    CreatePhase(name: name, status: status),
                                  );
                                  break;
                                case EntityType.activity:
                                  entityBloc.add(
                                    CreateActivityEntity(
                                      name: name,
                                      status: status,
                                    ),
                                  );
                                  break;
                                case EntityType.staff:
                                  break;
                                case EntityType.template:
                                  break;
                                case EntityType.workCategory:
                                  entityBloc.add(
                                    CreateWorkCategory(
                                      name: name,
                                      status: status,
                                    ),
                                  );
                                  break;
                              }
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Template helper methods
  void _addTemplateActivity() {
    final activityId = 'activity-${DateTime.now().millisecondsSinceEpoch}';
    _currentTemplateActivities.add({
      'id': activityId,
      'name': '',
      'activityId': '',
    });
    _currentTemplateActivityControllers[activityId] = TextEditingController();
  }

  void _removeTemplateActivity(String activityId) {
    _currentTemplateActivities.removeWhere((a) => a['id'] == activityId);
    _currentTemplateActivityControllers[activityId]?.dispose();
    _currentTemplateActivityControllers.remove(activityId);
  }

  void _updateTemplateActivity(String activityId, String field, dynamic value) {
    final index = _currentTemplateActivities.indexWhere(
      (a) => a['id'] == activityId,
    );
    if (index != -1) {
      _currentTemplateActivities[index][field] = value;
    }
  }

  void _saveTemplatePhase(BuildContext context, EntityState state) {
    final customPhaseName = _toTitleCase(
      _currentTemplatePhaseNameController.text.trim(),
    );
    final selectedPhaseName = _currentTemplatePhaseName;

    final actualPhaseName = customPhaseName.isNotEmpty
        ? customPhaseName
        : selectedPhaseName;

    if (actualPhaseName.isEmpty || _currentTemplateActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill phase name and add at least one activity'),
        ),
      );
      return;
    }

    // Validate all activities have names
    if (_currentTemplateActivities.any((a) => a['name'].toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all activity names')),
      );
      return;
    }

    // Determine phase ID
    String phaseId;
    if (customPhaseName.isNotEmpty) {
      phaseId = customPhaseName; // Custom phase name
    } else if (_currentTemplatePhaseId != null) {
      phaseId = _currentTemplatePhaseId!; // Existing phase ID
    } else {
      phaseId = actualPhaseName; // Fallback to name
    }

    // Build activities list with IDs or names
    final activitiesList = _currentTemplateActivities.map((activity) {
      final activityName = _toTitleCase(activity['name'].toString());
      final activityId = activity['activityId'].toString();
      // Use activityId if it's a valid ID, otherwise use name
      return activityId.isNotEmpty &&
              state.activities.any((a) => a.id == activityId)
          ? activityId
          : activityName;
    }).toList();

    _savedTemplatePhases.add({
      'phaseId': phaseId,
      'phaseName': actualPhaseName,
      'activities': activitiesList,
      'activitiesDetails': _currentTemplateActivities
          .map((a) => {'name': _toTitleCase(a['name'].toString())})
          .toList(),
    });

    // Clear current phase
    _currentTemplatePhaseName = '';
    _currentTemplatePhaseId = null;
    _currentTemplatePhaseNameController.clear();
    _currentTemplateActivities.clear();
    for (var controller in _currentTemplateActivityControllers.values) {
      controller.dispose();
    }
    _currentTemplateActivityControllers.clear();
  }

  void _removeSavedTemplatePhase(int index) {
    _savedTemplatePhases.removeAt(index);
  }

  Widget _buildTemplateFormLayout({
    required BuildContext context,
    required EntityState state,
    required StateSetter setStateDialog,
    required bool isMobile,
  }) {
    // "Add New Phase" Card Content
    Widget buildAddNewPhaseContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Phase',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          CustomDropdownButtonFormField<String>(
            label: 'Phase Name',
            hint: 'Select phase name',
            value: _currentTemplatePhaseName.isEmpty
                ? null
                : (state.phases.any((p) => p.name == _currentTemplatePhaseName)
                      ? _currentTemplatePhaseName
                      : null),
            items: state.phases.isEmpty
                ? []
                : state.phases.map((p) {
                    return DropdownMenuItem(value: p.name, child: Text(p.name));
                  }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selectedPhase = state.phases.firstWhere(
                  (p) => p.name == value,
                );
                setStateDialog(() {
                  _currentTemplatePhaseName = value;
                  _currentTemplatePhaseId = selectedPhase.id;
                  _currentTemplatePhaseNameController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          CustomTextInput(
            hint: 'Or type custom phase name',
            controller: _currentTemplatePhaseNameController,
            onChanged: (value) {
              if (value.isNotEmpty && _currentTemplatePhaseName.isNotEmpty) {
                setStateDialog(() {
                  _currentTemplatePhaseName = '';
                  _currentTemplatePhaseId = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              CustomButton(
                text: isMobile ? 'Add' : 'Add Activity',
                onPressed: () {
                  setStateDialog(() {
                    _addTemplateActivity();
                  });
                },
                size: ButtonSize.sm,
                variant: ButtonVariant.outline,
                icon: const Icon(Icons.add, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isMobile ? 200 : 300,
            child: _currentTemplateActivities.isEmpty
                ? const Center(
                    child: Text(
                      'No activities added yet',
                      style: TextStyle(color: AppTheme.gray500),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: false,
                    itemCount: _currentTemplateActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _currentTemplateActivities[index];
                      final activityId = activity['id'] as String;
                      final nameController =
                          _currentTemplateActivityControllers[activityId] ??=
                              TextEditingController();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.gray50,
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        CustomDropdownButtonFormField<String>(
                                          label: 'Activity',
                                          hint: 'Select activity',
                                          value:
                                              activity['name']
                                                  .toString()
                                                  .isEmpty
                                              ? null
                                              : (state.activities.any(
                                                      (a) =>
                                                          a.name ==
                                                          activity['name'],
                                                    )
                                                    ? activity['name']
                                                          .toString()
                                                    : null),
                                          items: state.activities.isEmpty
                                              ? []
                                              : state.activities.map((a) {
                                                  return DropdownMenuItem(
                                                    value: a.name,
                                                    child: Text(a.name),
                                                  );
                                                }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              final selectedActivity = state
                                                  .activities
                                                  .firstWhere(
                                                    (a) => a.name == value,
                                                  );
                                              setStateDialog(() {
                                                _updateTemplateActivity(
                                                  activityId,
                                                  'name',
                                                  value,
                                                );
                                                _updateTemplateActivity(
                                                  activityId,
                                                  'activityId',
                                                  selectedActivity.id,
                                                );
                                                nameController.clear();
                                              });
                                            }
                                          },
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.red500,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        _removeTemplateActivity(activityId);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CustomTextInput(
                                hint: 'Or type custom activity',
                                controller: nameController,
                                onChanged: (value) {
                                  setStateDialog(() {
                                    _updateTemplateActivity(
                                      activityId,
                                      'name',
                                      value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Save Phase',
            onPressed:
                ((_currentTemplatePhaseName.isNotEmpty ||
                        _currentTemplatePhaseNameController.text
                            .trim()
                            .isNotEmpty) &&
                    _currentTemplateActivities.isNotEmpty)
                ? () {
                    setStateDialog(() {
                      _saveTemplatePhase(context, state);
                    });
                  }
                : null,
            isFullWidth: true,
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      );
    }

    // "Saved Phases" Card Content
    Widget buildSavedPhasesContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Saved Phases (${_savedTemplatePhases.length})',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isMobile ? 200 : 300,
            child: _savedTemplatePhases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No phases added yet',
                          style: TextStyle(color: AppTheme.gray500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMobile
                              ? 'Add phases using the form above'
                              : 'Add phases using the form on the left',
                          style: const TextStyle(color: AppTheme.gray600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: false,
                    itemCount: _savedTemplatePhases.length,
                    itemBuilder: (context, phaseIndex) {
                      final phase = _savedTemplatePhases[phaseIndex];
                      final activitiesDetails =
                          phase['activitiesDetails'] as List<dynamic>? ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomBadge(
                                          text: 'Phase ${phaseIndex + 1}',
                                          variant: BadgeVariant.outline,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          phase['phaseName'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.red500,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        _removeSavedTemplatePhase(phaseIndex);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...activitiesDetails.asMap().entries.map((entry) {
                                final actIndex = entry.key;
                                final activity =
                                    entry.value as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gray50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${actIndex + 1}. ${activity['name']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.gray700,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Return layout based on screen size
    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: buildAddNewPhaseContent(),
            ),
            const SizedBox(height: 16),
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: buildSavedPhasesContent(),
            ),
          ],
        ),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: CustomCard(
                padding: const EdgeInsets.all(24),
                child: buildAddNewPhaseContent(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: CustomCard(
                padding: const EdgeInsets.all(24),
                child: buildSavedPhasesContent(),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _openTemplateAddDialog() {
    _editingTemplateId = null;
    _templateNameController.clear();
    _currentTemplatePhaseName = '';
    _currentTemplatePhaseId = null;
    _currentTemplatePhaseNameController.clear();
    _currentTemplateActivities.clear();
    _savedTemplatePhases.clear();
    for (var controller in _currentTemplateActivityControllers.values) {
      controller.dispose();
    }
    _currentTemplateActivityControllers.clear();
    final bloc = context.read<EntityBloc>();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: BlocProvider.value(
            value: bloc,
            child: BlocListener<EntityBloc, EntityState>(
              listenWhen: (previous, current) {
                return previous.isCreating && !current.isCreating;
              },
              listener: (context, state) {
                if (state.errorMessage == null || state.errorMessage!.isEmpty) {
                  Navigator.of(ctx).pop();
                }
              },
              child: Container(
                constraints: const BoxConstraints.tightFor(
                  width: 1000,
                  height: 800,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    final state = context.watch<EntityBloc>().state;
                    return Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: AppTheme.gray900,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Add Template',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.gray600,
                                    ),
                                    onPressed: state.isCreating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomTextInput(
                                          label: 'Template Name',
                                          controller: _templateNameController,
                                          hint: 'Enter template name',
                                        ),
                                        const SizedBox(height: 24),
                                        Expanded(
                                          child: _buildTemplateFormLayout(
                                            context: context,
                                            state: state,
                                            setStateDialog: setStateDialog,
                                            isMobile:
                                                constraints.maxWidth < 768,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: state.isCreating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  CustomButton(
                                    text: 'Create Template',
                                    onPressed: state.isCreating
                                        ? null
                                        : () {
                                            if (_templateNameController.text
                                                .trim()
                                                .isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please enter template name',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }

                                            if (_savedTemplatePhases.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please add at least one phase',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }

                                            // Build template data from saved phases
                                            final phasesData =
                                                _savedTemplatePhases.map((
                                                  phase,
                                                ) {
                                                  return {
                                                    'phaseId':
                                                        phase['phaseId']
                                                            as String,
                                                    'activities':
                                                        phase['activities']
                                                            as List<String>,
                                                  };
                                                }).toList();

                                            final templateData = {
                                              'templateName': _toTitleCase(
                                                _templateNameController.text
                                                    .trim(),
                                              ),
                                              'phases': phasesData,
                                            };

                                            context.read<EntityBloc>().add(
                                              CreateTemplate(
                                                templateData: templateData,
                                              ),
                                            );
                                          },
                                    size: ButtonSize.lg,
                                    icon: const Icon(
                                      Icons.save,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (state.isCreating)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTemplateEditDialog(TemplateEntity entity) {
    _editingTemplateId = entity.id;
    _templateNameController.text = entity.templateName;
    _currentTemplatePhaseName = '';
    _currentTemplatePhaseId = null;
    _currentTemplatePhaseNameController.clear();
    _currentTemplateActivities.clear();
    _savedTemplatePhases.clear();
    for (var controller in _currentTemplateActivityControllers.values) {
      controller.dispose();
    }
    _currentTemplateActivityControllers.clear();

    // Pre-fill saved phases from entity
    final state = context.read<EntityBloc>().state;
    for (var phase in entity.phases) {
      final activitiesList = phase.activities.map((a) {
        final activityId = a.activityId;
        // Use activityId if it's a valid ID, otherwise use name
        return activityId.isNotEmpty &&
                state.activities.any((act) => act.id == activityId)
            ? activityId
            : a.name;
      }).toList();

      _savedTemplatePhases.add({
        'phaseId': phase.phaseId,
        'phaseName': phase.name,
        'activities': activitiesList,
        'activitiesDetails': phase.activities
            .map((a) => {'name': a.name})
            .toList(),
      });
    }

    final bloc = context.read<EntityBloc>();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: BlocProvider.value(
            value: bloc,
            child: BlocListener<EntityBloc, EntityState>(
              listenWhen: (previous, current) {
                return previous.isUpdating && !current.isUpdating;
              },
              listener: (context, state) {
                if (state.errorMessage == null || state.errorMessage!.isEmpty) {
                  Navigator.of(ctx).pop();
                }
              },
              child: Container(
                constraints: const BoxConstraints.tightFor(
                  width: 1100,
                  height: 850,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    final state = context.watch<EntityBloc>().state;
                    return Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: AppTheme.gray900,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Edit Template',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.gray600,
                                    ),
                                    onPressed: state.isUpdating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomTextInput(
                                          label: 'Template Name',
                                          controller: _templateNameController,
                                          hint: 'Enter template name',
                                        ),
                                        const SizedBox(height: 24),
                                        Expanded(
                                          child: _buildTemplateFormLayout(
                                            context: context,
                                            state: state,
                                            setStateDialog: setStateDialog,
                                            isMobile:
                                                constraints.maxWidth < 768,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: state.isUpdating
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  CustomButton(
                                    text: 'Update Template',
                                    onPressed: state.isUpdating
                                        ? null
                                        : () {
                                            if (_templateNameController.text
                                                .trim()
                                                .isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please enter template name',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }

                                            if (_savedTemplatePhases.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please add at least one phase',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.red500,
                                                ),
                                              );
                                              return;
                                            }

                                            // Build template data from saved phases
                                            final phasesData =
                                                _savedTemplatePhases.map((
                                                  phase,
                                                ) {
                                                  return {
                                                    'phaseId':
                                                        phase['phaseId']
                                                            as String,
                                                    'activities':
                                                        phase['activities']
                                                            as List<String>,
                                                  };
                                                }).toList();

                                            final templateData = {
                                              'templateName': _toTitleCase(
                                                _templateNameController.text
                                                    .trim(),
                                              ),
                                              'phases': phasesData,
                                            };

                                            context.read<EntityBloc>().add(
                                              UpdateTemplate(
                                                id: _editingTemplateId!,
                                                templateData: templateData,
                                              ),
                                            );
                                          },
                                    size: ButtonSize.lg,
                                    icon: const Icon(
                                      Icons.save,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (state.isUpdating)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic entity) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Row(
        children: [
          // Toggle status
          IconButton(
            icon: Icon(
              (entity.status ?? 'active') == 'active'
                  ? Icons.toggle_on
                  : Icons.toggle_off,
            ),
            color: (entity.status ?? 'active') == 'active'
                ? AppTheme.green600
                : AppTheme.gray500,
            onPressed: () {
              _updateEntityStatus(
                context,
                entity.id,
                (entity.status ?? 'active') == 'active' ? 'inactive' : 'active',
              );
            },
          ),
          // Three-dot menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                if (widget.entityType == EntityType.staff) {
                  context.read<EntityBloc>().add(const LoadDesignations());
                  context.read<EntityBloc>().add(const LoadZones());
                  context.read<EntityBloc>().add(const LoadDepartments());
                  _openStaffEditDialog(entity);
                } else if (widget.entityType == EntityType.template) {
                  context.read<EntityBloc>().add(const LoadPhases());
                  context.read<EntityBloc>().add(const LoadActivities());
                  context.read<EntityBloc>().add(const LoadStaff());
                  _openTemplateEditDialog(entity as TemplateEntity);
                }
              } else if (value == 'changePassword') {
                _showChangePasswordDialog(context, entity);
              } else if (value == 'delete') {
                _deleteEntity(context, entity.id);
              }
            },
            itemBuilder: (BuildContext context) {
              final items = <PopupMenuEntry<String>>[];

              if (widget.entityType == EntityType.staff ||
                  widget.entityType == EntityType.template) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                );
              }

              if (widget.entityType == EntityType.staff) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'changePassword',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Change Password'),
                      ],
                    ),
                  ),
                );
              }

              items.add(
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.red500,
                      ),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.red500)),
                    ],
                  ),
                ),
              );

              return items;
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
    }

    // Web layout - original behavior
    return Row(
      children: [
        // Toggle status (for all)
        IconButton(
          icon: Icon(
            (entity.status ?? 'active') == 'active'
                ? Icons.toggle_on
                : Icons.toggle_off,
          ),
          color: (entity.status ?? 'active') == 'active'
              ? AppTheme.green600
              : AppTheme.gray500,
          onPressed: () {
            _updateEntityStatus(
              context,
              entity.id,
              (entity.status ?? 'active') == 'active' ? 'inactive' : 'active',
            );
          },
        ),
        if (widget.entityType == EntityType.staff) ...[
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.read<EntityBloc>().add(const LoadDesignations());
              context.read<EntityBloc>().add(const LoadZones());
              context.read<EntityBloc>().add(const LoadDepartments());
              _openStaffEditDialog(entity);
            },
          ),
        ] else if (widget.entityType == EntityType.template) ...[
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.read<EntityBloc>().add(const LoadPhases());
              context.read<EntityBloc>().add(const LoadActivities());
              context.read<EntityBloc>().add(const LoadStaff());
              _openTemplateEditDialog(entity as TemplateEntity);
            },
          ),
        ],
        if (widget.entityType == EntityType.staff) ...[
          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(Icons.lock_reset_outlined),
            onPressed: () => _showChangePasswordDialog(context, entity),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: AppTheme.red500,
          onPressed: () => _deleteEntity(context, entity.id),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, dynamic entity) async {
    final newPassController = TextEditingController();
    final confirmController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 500, height: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.gray600),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter a new password for this staff member',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextInput(
                          label: 'New Password',
                          controller: newPassController,
                          hint: 'Enter new password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextInput(
                          label: 'Confirm Password',
                          controller: confirmController,
                          hint: 'Confirm new password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.blue50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.blue200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.blue600,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Password must be at least 8 characters long',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.blue700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.gray600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: 'Update Password',
                        onPressed: () {
                          final np = newPassController.text.trim();
                          final cp = confirmController.text.trim();

                          if (np.isEmpty || cp.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                backgroundColor: AppTheme.red500,
                              ),
                            );
                            return;
                          }

                          if (np.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 8 characters long',
                                ),
                                backgroundColor: AppTheme.red500,
                              ),
                            );
                            return;
                          }

                          if (np != cp) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: AppTheme.red500,
                              ),
                            );
                            return;
                          }

                          if ((entity.email ?? '').isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Staff email is missing'),
                                backgroundColor: AppTheme.red500,
                              ),
                            );
                            return;
                          }

                          context.read<EntityBloc>().add(
                            ChangeStaffPassword(
                              staffId: entity.staffId,
                              email: entity.email ?? '',
                              newPassword: np,
                              confirmPassword: cp,
                            ),
                          );
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppTheme.primaryForeground : AppTheme.gray900,
            ),
          ),
        ),
      ),
    );
  }
}
