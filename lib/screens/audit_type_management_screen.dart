import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';

class AuditTypeManagementScreen extends StatefulWidget {
  const AuditTypeManagementScreen({super.key});

  @override
  State<AuditTypeManagementScreen> createState() => _AuditTypeManagementScreenState();
}

class _AuditTypeManagementScreenState extends State<AuditTypeManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<AuditType> _auditTypes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  AuditType? _editingAuditType;

  @override
  void initState() {
    super.initState();
    _fetchAuditTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAuditTypes();
      final auditTypes = (response['auditTypes'] as List)
          .map((json) => AuditType.fromJson(json))
          .toList();
      
      setState(() {
        _auditTypes = auditTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createAuditType() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.createAuditType(name: _nameController.text.trim());
      _nameController.clear();
      await _fetchAuditTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit type created successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateAuditType() async {
    if (_editingAuditType == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateAuditType(
        id: _editingAuditType!.id,
        name: _nameController.text.trim(),
      );
      _nameController.clear();
      _editingAuditType = null;
      await _fetchAuditTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit type updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(AuditType auditType) async {
    final newStatus = auditType.status == 'active' ? 'inactive' : 'active';
    
    try {
      await _apiService.updateAuditTypeStatus(
        id: auditType.id,
        status: newStatus,
      );
      await _fetchAuditTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAuditType(AuditType auditType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Type'),
        content: Text('Are you sure you want to delete "${auditType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteAuditType(id: auditType.id);
        await _fetchAuditTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit type deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _startEditing(AuditType auditType) {
    setState(() {
      _editingAuditType = auditType;
      _nameController.text = auditType.name;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingAuditType = null;
      _nameController.clear();
    });
  }

  List<AuditType> get _filteredAuditTypes {
    if (_searchQuery.isEmpty) return _auditTypes;
    return _auditTypes.where((auditType) {
      return auditType.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Type Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create/Edit Form
            CustomCard(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingAuditType == null ? 'Create Audit Type' : 'Edit Audit Type',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    controller: _nameController,
                    hint: 'Enter audit type name',
                    label: 'Name',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: _editingAuditType == null ? 'Create' : 'Update',
                          onPressed: _editingAuditType == null ? _createAuditType : _updateAuditType,
                          isLoading: _isLoading,
                        ),
                      ),
                      if (_editingAuditType != null) ...[
                        const SizedBox(width: 12),
                        CustomButton(
                          text: 'Cancel',
                          onPressed: _cancelEditing,
                          variant: ButtonVariant.outline,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search
            CustomTextInput(
              controller: _searchController,
              hint: 'Search audit types...',
              onChanged: (value) => setState(() => _searchQuery = value),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : const Icon(Icons.search, size: 20),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading && _auditTypes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _auditTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppTheme.red500),
                              const SizedBox(height: 16),
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Retry',
                                onPressed: _fetchAuditTypes,
                              ),
                            ],
                          ),
                        )
                      : _filteredAuditTypes.isEmpty
                          ? const Center(
                              child: Text('No audit types found'),
                            )
                          : ListView.builder(
                              itemCount: _filteredAuditTypes.length,
                              itemBuilder: (context, index) {
                                final auditType = _filteredAuditTypes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CustomCard(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                auditType.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.gray900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              CustomBadge(
                                                text: auditType.status.toUpperCase(),
                                                variant: auditType.status == 'active'
                                                    ? BadgeVariant.default_
                                                    : BadgeVariant.secondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () => _startEditing(auditType),
                                              color: AppTheme.blue600,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                auditType.status == 'active'
                                                    ? Icons.toggle_on
                                                    : Icons.toggle_off,
                                                size: 24,
                                              ),
                                              onPressed: () => _toggleStatus(auditType),
                                              color: auditType.status == 'active'
                                                  ? AppTheme.green600
                                                  : AppTheme.gray500,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              onPressed: () => _deleteAuditType(auditType),
                                              color: AppTheme.red600,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}