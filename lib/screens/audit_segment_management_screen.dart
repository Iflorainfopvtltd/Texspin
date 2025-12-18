import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';

class AuditSegmentManagementScreen extends StatefulWidget {
  const AuditSegmentManagementScreen({super.key});

  @override
  State<AuditSegmentManagementScreen> createState() => _AuditSegmentManagementScreenState();
}

class _AuditSegmentManagementScreenState extends State<AuditSegmentManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<AuditSegment> _auditSegments = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  AuditSegment? _editingAuditSegment;

  @override
  void initState() {
    super.initState();
    _fetchAuditSegments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditSegments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAuditSegments();
      final auditSegments = (response['auditSegments'] as List)
          .map((json) => AuditSegment.fromJson(json))
          .toList();
      
      setState(() {
        _auditSegments = auditSegments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createAuditSegment() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.createAuditSegment(name: _nameController.text.trim());
      _nameController.clear();
      await _fetchAuditSegments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit segment created successfully')),
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

  Future<void> _updateAuditSegment() async {
    if (_editingAuditSegment == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateAuditSegment(
        id: _editingAuditSegment!.id,
        name: _nameController.text.trim(),
      );
      _nameController.clear();
      _editingAuditSegment = null;
      await _fetchAuditSegments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit segment updated successfully')),
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

  Future<void> _toggleStatus(AuditSegment auditSegment) async {
    final newStatus = auditSegment.status == 'active' ? 'inactive' : 'active';
    
    try {
      await _apiService.updateAuditSegmentStatus(
        id: auditSegment.id,
        status: newStatus,
      );
      await _fetchAuditSegments();
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

  Future<void> _deleteAuditSegment(AuditSegment auditSegment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Segment'),
        content: Text('Are you sure you want to delete "${auditSegment.name}"?'),
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
        await _apiService.deleteAuditSegment(id: auditSegment.id);
        await _fetchAuditSegments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit segment deleted successfully')),
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

  void _startEditing(AuditSegment auditSegment) {
    setState(() {
      _editingAuditSegment = auditSegment;
      _nameController.text = auditSegment.name;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingAuditSegment = null;
      _nameController.clear();
    });
  }

  List<AuditSegment> get _filteredAuditSegments {
    if (_searchQuery.isEmpty) return _auditSegments;
    return _auditSegments.where((auditSegment) {
      return auditSegment.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Segment Management'),
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
                    _editingAuditSegment == null ? 'Create Audit Segment' : 'Edit Audit Segment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    controller: _nameController,
                    hint: 'Enter audit segment name',
                    label: 'Name',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: _editingAuditSegment == null ? 'Create' : 'Update',
                          onPressed: _editingAuditSegment == null ? _createAuditSegment : _updateAuditSegment,
                          isLoading: _isLoading,
                        ),
                      ),
                      if (_editingAuditSegment != null) ...[
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
              hint: 'Search audit segments...',
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
              child: _isLoading && _auditSegments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _auditSegments.isEmpty
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
                                onPressed: _fetchAuditSegments,
                              ),
                            ],
                          ),
                        )
                      : _filteredAuditSegments.isEmpty
                          ? const Center(
                              child: Text('No audit segments found'),
                            )
                          : ListView.builder(
                              itemCount: _filteredAuditSegments.length,
                              itemBuilder: (context, index) {
                                final auditSegment = _filteredAuditSegments[index];
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
                                                auditSegment.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.gray900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              CustomBadge(
                                                text: auditSegment.status.toUpperCase(),
                                                variant: auditSegment.status == 'active'
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
                                              onPressed: () => _startEditing(auditSegment),
                                              color: AppTheme.blue600,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                auditSegment.status == 'active'
                                                    ? Icons.toggle_on
                                                    : Icons.toggle_off,
                                                size: 24,
                                              ),
                                              onPressed: () => _toggleStatus(auditSegment),
                                              color: auditSegment.status == 'active'
                                                  ? AppTheme.green600
                                                  : AppTheme.gray500,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              onPressed: () => _deleteAuditSegment(auditSegment),
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