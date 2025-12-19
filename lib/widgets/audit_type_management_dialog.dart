import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';
import '../widgets/audit_type_form_dialog.dart';

class AuditTypeManagementDialog extends StatefulWidget {
  const AuditTypeManagementDialog({super.key});

  @override
  State<AuditTypeManagementDialog> createState() => _AuditTypeManagementDialogState();
}

class _AuditTypeManagementDialogState extends State<AuditTypeManagementDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<AuditType> _auditTypes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAuditTypes();
  }

  @override
  void dispose() {
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

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AuditTypeFormDialog(
        onSuccess: _fetchAuditTypes,
      ),
    );
  }

  void _openEditDialog(AuditType auditType) {
    showDialog(
      context: context,
      builder: (context) => AuditTypeFormDialog(
        auditType: auditType,
        onSuccess: _fetchAuditTypes,
      ),
    );
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



  List<AuditType> get _filteredAuditTypes {
    if (_searchQuery.isEmpty) return _auditTypes;
    return _auditTypes.where((auditType) {
      return auditType.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints.tightFor(width: 800, height: 600),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent()),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _openCreateDialog,
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: AppTheme.gray600, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audit Type Management',
              style: TextStyle(
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
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                                padding: const EdgeInsets.only(bottom: 8),
                                child: CustomCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              auditType.name,
                                              style: const TextStyle(
                                                fontSize: 14,
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
                                            icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () => _openEditDialog(auditType),
                                            color: AppTheme.blue600,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              auditType.status == 'active'
                                                  ? Icons.toggle_on
                                                  : Icons.toggle_off,
                                              size: 20,
                                            ),
                                            onPressed: () => _toggleStatus(auditType),
                                            color: auditType.status == 'active'
                                                ? AppTheme.green600
                                                : AppTheme.gray500,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 18),
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
    );
  }
}