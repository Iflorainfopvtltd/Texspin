import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/single_select_dropdown.dart';
import '../widgets/multi_select_dropdown.dart';
import 'dart:developer' as developer;

class MomFormDialog extends StatefulWidget {
  final Map<String, dynamic> audit;
  final Map<String, dynamic>? mom;

  const MomFormDialog({super.key, required this.audit, this.mom});
  // ... (lines 18-222 remain unchanged behavior, but we are replacing imports and submit)

  // We need to target specific chunks. I will split this into two chunks.
  // Chunk 1: Imports
  // Chunk 2: _submit call

  @override
  State<MomFormDialog> createState() => _MomFormDialogState();
}

class _MomFormDialogState extends State<MomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  String? _selectedType;
  final List<String> _types = [
    'Start',
    'End',
    'Methodology',
    'Observation',
    'Plan',
    'Transection',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  PlatformFile? _selectedFile;

  List<Map<String, dynamic>> _allStaff = [];
  List<String> _selectedTexspinStaffIds = [];

  List<dynamic> _visitors = [];
  List<String> _selectedVisitorIds = [];

  List<Map<String, dynamic>> _observations = [];

  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    if (widget.audit['visitCompanyMemberName'] != null) {
      _visitors = List<dynamic>.from(widget.audit['visitCompanyMemberName']);
    }

    if (widget.mom != null) {
      _initializeEditMode();
    } else {
      if (widget.audit['companyName'] != null) {
        _companyNameController.text = widget.audit['companyName'];
      }
      _addObservation();
    }
    _loadData();
  }

  void _initializeEditMode() {
    final mom = widget.mom!;
    _selectedType = mom['selectType'];
    _titleController.text = mom['momTitle'] ?? '';
    _companyNameController.text = mom['companyName'] ?? '';
    _venueController.text = mom['venue'] ?? '';
    _agendaController.text = mom['agendaPoints'] ?? '';

    if (mom['date'] != null) {
      _selectedDate = DateTime.parse(mom['date']);
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
    if (mom['time'] != null) {
      // Assuming time is stored clearly or parsing logic is robust enough
      // The stored format seems to be 'hh:mm a'
      _timeController.text = mom['time'];
      // Try to parse back to TimeOfDay if needed for logic, though purely display might be fine
      // Simple parsing attempt:
      try {
        final parts = mom['time'].split(' '); // "03:30" "PM"
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        if (parts[1] == 'PM' && hour != 12) hour += 12;
        if (parts[1] == 'AM' && hour == 12) hour = 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        // Fallback or ignore
      }
    }

    if (mom['texspinStaff'] != null) {
      // Assuming it's already a list of strings/IDs or list of objects
      // If backend sends populated objects:
      if (mom['texspinStaff'] is List) {
        _selectedTexspinStaffIds = (mom['texspinStaff'] as List)
            .map(
              (e) => e is Map ? (e['_id'] ?? e['id']).toString() : e.toString(),
            )
            .toList();
      }
    }
    if (mom['visitorStaff'] != null) {
      if (mom['visitorStaff'] is List) {
        _selectedVisitorIds = (mom['visitorStaff'] as List)
            .map(
              (e) => e is Map ? (e['_id'] ?? e['id']).toString() : e.toString(),
            )
            .toList();
      }
    }

    if (mom['discussionAndObservation'] != null) {
      final obsList = mom['discussionAndObservation'] as List;
      _observations = obsList
          .map(
            (e) => {
              'observation': e['observationName'] ?? e['observation'] ?? '',
              'department': e['department'] is Map
                  ? (e['department']['_id'] ?? e['department']['id'])
                  : e['department'],
              'staff': e['staff'] is Map
                  ? (e['staff']['_id'] ?? e['staff']['id'])
                  : e['staff'],
            },
          )
          .toList();
    } else {
      _addObservation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyNameController.dispose();
    _venueController.dispose();
    _agendaController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _fileController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staffResponse = await _apiService.getStaff();
      final deptResponse = await _apiService.getDepartments();

      if (mounted) {
        setState(() {
          if (staffResponse['staff'] != null) {
            _allStaff = List<Map<String, dynamic>>.from(staffResponse['staff']);
          }
          if (deptResponse['departments'] != null) {
            _departments = List<Map<String, dynamic>>.from(
              deptResponse['departments'],
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _addObservation() {
    setState(() {
      _observations.add({'observation': '', 'department': null, 'staff': null});
    });
  }

  void _removeObservation(int index) {
    if (_observations.length > 1) {
      setState(() {
        _observations.removeAt(index);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _timeController.text = DateFormat('hh:mm a').format(dt);
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'xlsx'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _fileController.text = _selectedFile!.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Manual validation for custom widgets not wrapped in FormField or failing validation
    if (_selectedDate == null) {
      _showError('Please select date');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select time');
      return;
    }
    // Optional: Enforce staff selection? Assuming yes based on context.
    if (_selectedTexspinStaffIds.isEmpty) {
      _showError('Please select at least one Texspin staff');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final timeStr = DateFormat('hh:mm a').format(dt);

      final Map<String, dynamic> data = {
        'selectType': _selectedType,
        'momTitle': _titleController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'date': dateStr,
        'time': timeStr,
        'venue': _venueController.text.trim(),
        'agendaPoints': _agendaController.text.trim(),
        'texspinStaff': jsonEncode(_selectedTexspinStaffIds),
        'visitorStaff': jsonEncode(_selectedVisitorIds),
        'discussionAndObservation': jsonEncode(
          _observations
              .map(
                (e) => {
                  'observationName': e['observation'],
                  'department': e['department'],
                  'staff': e['staff'],
                },
              )
              .toList(),
        ),
      };

      if (widget.mom != null) {
        // Update
        await _apiService.updateMom(
          auditId: widget.audit['_id'] ?? widget.audit['id'],
          momId: widget.mom!['_id'] ?? widget.mom!['id'],
          data: data,
          filePath: kIsWeb ? null : _selectedFile?.path,
          fileBytes: _selectedFile?.bytes,
          fileName: _selectedFile?.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MOM updated successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create
        await _apiService.createMom(
          auditId: widget.audit['_id'] ?? widget.audit['id'],
          data: data,
          filePath: kIsWeb ? null : _selectedFile?.path,
          fileBytes: _selectedFile?.bytes,
          fileName: _selectedFile?.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MOM created successfully'),
              backgroundColor: AppTheme.green500,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError('Error saving MOM: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.destructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type
        CustomDropdownButtonFormField<String>(
          label: 'Select Type',
          items: _types
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          value: _selectedType,
          onChanged: (val) => setState(() => _selectedType = val),
          validator: (v) => v == null ? 'Required' : null,
          hint: 'Select Type',
        ),
        const SizedBox(height: 16),
        // Title
        CustomTextInput(
          label: 'MOM Title',
          controller: _titleController,
          hint: 'Enter title',
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        // Company
        CustomTextInput(
          label: 'Company Name',
          controller: _companyNameController,
          hint: 'Enter company name',
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        // Date & Time
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 16),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        const SizedBox(height: 16),
        // Venue
        CustomTextInput(
          label: 'Venue',
          controller: _venueController,
          hint: 'Conference Room',
        ),
        const SizedBox(height: 16),
        // Texspin Staff
        MultiSelectDropdown<Map<String, dynamic>>(
          label: 'Select Texspin Staff',
          options: _allStaff,
          selectedIds: _selectedTexspinStaffIds,
          onSelectionChanged: (ids) =>
              setState(() => _selectedTexspinStaffIds = ids),
          getDisplayText: (item) =>
              '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}',
          getId: (item) => (item['_id'] ?? item['id'] ?? '').toString(),
          hintText: 'Select Staff',
        ),
        const SizedBox(height: 16),
        // Visitor Staff
        MultiSelectDropdown<dynamic>(
          label: 'Select Visitor Staff',
          options: _visitors,
          selectedIds: _selectedVisitorIds,
          onSelectionChanged: (ids) =>
              setState(() => _selectedVisitorIds = ids),
          getDisplayText: (item) =>
              item is Map ? (item['name'] ?? 'Unknown') : item.toString(),
          getId: (item) => item is Map
              ? (item['_id'] ?? item['id'] ?? '').toString()
              : item.toString(),
          hintText: 'Select Visitors',
        ),
        const SizedBox(height: 16),
        // Agenda
        CustomTextInput(
          label: 'Agenda Points',
          controller: _agendaController,
          hint: 'Enter agenda points',
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildObservationsSection(),
        const SizedBox(height: 24),
        // File Picker
        GestureDetector(
          onTap: _pickFile,
          child: AbsorbPointer(
            child: CustomTextInput(
              label: 'Other Documents',
              controller: _fileController,
              hint: 'Choose File',
              suffixIcon: const Icon(Icons.attach_file),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mom != null ? 'Edit MOM' : 'Create MOM'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: formContent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border)),
                      ),
                      child: _buildFooter(),
                    ),
                  ],
                ),
              ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.background,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    Flexible(child: SingleChildScrollView(child: formContent)),
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.mom != null ? 'Edit MOM' : 'Create MOM',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.foreground,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: CustomTextInput(
          label: 'Date',
          controller: _dateController,
          hint: 'Select Date',
          suffixIcon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _selectTime,
      child: AbsorbPointer(
        child: CustomTextInput(
          label: 'Time',
          controller: _timeController,
          hint: 'Select Time',
          suffixIcon: const Icon(Icons.access_time),
        ),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Observations',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: _addObservation,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._observations.asMap().entries.map((entry) {
          final index = entry.key;
          final obs = entry.value;

          // User request: Show all staff (no filtering by department)
          List<Map<String, dynamic>> filteredStaff = _allStaff;

          return Card(
            key: ObjectKey(obs),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Observation ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () => _removeObservation(index),
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.destructive,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  CustomTextInput(
                    label: 'Observation',
                    controller: TextEditingController(text: obs['observation'])
                      ..selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: (obs['observation'] as String).length,
                        ),
                      ),
                    onChanged: (val) => obs['observation'] = val,
                    hint: 'Enter observation',
                  ),
                  const SizedBox(height: 12),
                  SingleSelectDropdown<Map<String, dynamic>>(
                    label: 'Department',
                    options: _departments,
                    selectedId: obs['department'],
                    onSelectionChanged: (val) {
                      setState(() {
                        obs['department'] = val;
                        // Staff is not reset, allowing flexibility as requested
                      });
                    },
                    getDisplayText: (d) => d['name'] ?? '',
                    getId: (d) => (d['_id'] ?? d['id'] ?? '').toString(),
                    hintText: 'Select Department',
                    isRequired: true,
                    key: ValueKey('dept_${index}'),
                  ),
                  const SizedBox(height: 12),
                  SingleSelectDropdown<Map<String, dynamic>>(
                    label: 'Staff',
                    options: filteredStaff,
                    selectedId: obs['staff'],
                    onSelectionChanged: (val) {
                      setState(() {
                        obs['staff'] = val;
                        // Auto-select department if not selected (Helper feature)
                        if (val != null && obs['department'] == null) {
                          final selectedStaff = _allStaff.firstWhere(
                            (s) =>
                                (s['_id'] ?? s['id'] ?? '').toString() == val,
                            orElse: () => {},
                          );
                          if (selectedStaff.isNotEmpty) {
                            final staffDept = selectedStaff['department'];
                            if (staffDept != null) {
                              if (staffDept is Map) {
                                obs['department'] =
                                    (staffDept['_id'] ?? staffDept['id'])
                                        .toString();
                              } else {
                                obs['department'] = staffDept.toString();
                              }
                            }
                          }
                        }
                      });
                    },
                    getDisplayText: (s) =>
                        '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                    getId: (s) => (s['_id'] ?? s['id'] ?? '').toString(),
                    hintText: 'Select Staff',
                    isRequired: true,
                    key: ValueKey(
                      'staff_${index}',
                    ), // Key depends on index, not department
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(widget.mom != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
