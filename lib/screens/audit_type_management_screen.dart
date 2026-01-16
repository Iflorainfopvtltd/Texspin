import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';
import '../widgets/audit_type_form_dialog.dart';

class AuditTypeManagementScreen extends StatefulWidget {
  const AuditTypeManagementScreen({super.key});

  @override
  State<AuditTypeManagementScreen> createState() =>
      _AuditTypeManagementScreenState();
}

class _AuditTypeManagementScreenState extends State<AuditTypeManagementScreen> {
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

  Future<void> _toggleStatus(AuditType auditType) async {
    final newStatus = auditType.status == 'active' ? 'inactive' : 'active';

    try {
      await _apiService.updateAuditTypeStatus(
        id: auditType.id,
        status: newStatus,
      );
      await _fetchAuditTypes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _startEditing(AuditType auditType) {
    showDialog(
      context: context,
      builder: (context) => AuditTypeFormDialog(
        auditType: auditType,
        onSuccess: _fetchAuditTypes,
      ),
    );
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
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                AuditTypeFormDialog(onSuccess: _fetchAuditTypes),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.red500,
                          ),
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
                  ? const Center(child: Text('No audit types found'))
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      onPressed: () =>
                                          _deleteAuditType(auditType),
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
