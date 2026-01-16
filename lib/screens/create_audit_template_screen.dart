import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/audit_template_form_dialog.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';

class CreateAuditTemplateScreen extends StatefulWidget {
  const CreateAuditTemplateScreen({super.key});

  @override
  State<CreateAuditTemplateScreen> createState() =>
      _CreateAuditTemplateScreenState();
}

class _CreateAuditTemplateScreenState extends State<CreateAuditTemplateScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AuditTemplate> _auditTemplates = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAuditTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAuditTemplates();
      final auditTemplates = (response['auditTemplates'] as List)
          .map((json) => AuditTemplate.fromJson(json))
          .toList();

      setState(() {
        _auditTemplates = auditTemplates;
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
      builder: (context) =>
          AuditTemplateFormDialog(onSuccess: _fetchAuditTemplates),
    );
  }

  void _openEditDialog(AuditTemplate auditTemplate) {
    showDialog(
      context: context,
      builder: (context) => AuditTemplateFormDialog(
        auditTemplate: auditTemplate,
        onSuccess: _fetchAuditTemplates,
      ),
    );
  }

  Future<void> _toggleStatus(AuditTemplate auditTemplate) async {
    final newStatus = auditTemplate.status == 'active' ? 'inactive' : 'active';

    try {
      await _apiService.updateAuditTemplateStatus(
        id: auditTemplate.id,
        status: newStatus,
      );
      await _fetchAuditTemplates();
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

  Future<void> _deleteAuditTemplate(AuditTemplate auditTemplate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Template'),
        content: Text(
          'Are you sure you want to delete "${auditTemplate.name}"?',
        ),
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
        await _apiService.deleteAuditTemplate(id: auditTemplate.id);
        await _fetchAuditTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audit template deleted successfully'),
            ),
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

  List<AuditTemplate> get _filteredAuditTemplates {
    if (_searchQuery.isEmpty) return _auditTemplates;
    return _auditTemplates.where((auditTemplate) {
      return auditTemplate.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          auditTemplate.auditSegment.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          auditTemplate.auditType.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Basic responsiveness check
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Audit Template')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
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
              hint: 'Search audit templates...',
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
              child: _isLoading && _auditTemplates.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _auditTemplates.isEmpty
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
                            onPressed: _fetchAuditTemplates,
                          ),
                        ],
                      ),
                    )
                  : _filteredAuditTemplates.isEmpty
                  ? const Center(child: Text('No audit templates found'))
                  : ListView.builder(
                      itemCount: _filteredAuditTemplates.length,
                      itemBuilder: (context, index) {
                        final auditTemplate = _filteredAuditTemplates[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            auditTemplate.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.gray900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              CustomBadge(
                                                text: auditTemplate
                                                    .auditSegment
                                                    .name,
                                                variant: BadgeVariant.secondary,
                                              ),
                                              CustomBadge(
                                                text: auditTemplate
                                                    .auditType
                                                    .name,
                                                variant: BadgeVariant.outline,
                                              ),
                                              CustomBadge(
                                                text: auditTemplate.status
                                                    .toUpperCase(),
                                                variant:
                                                    auditTemplate.status ==
                                                        'active'
                                                    ? BadgeVariant.default_
                                                    : BadgeVariant.secondary,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${auditTemplate.auditQuestions.length} questions',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Actions - adapt for mobile (maybe popup menu or just icons if enough space)
                                    // Using icons effectively
                                    if (!isMobile)
                                      _buildDesktopActions(auditTemplate)
                                    else
                                      _buildMobileActions(auditTemplate),
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

  Widget _buildDesktopActions(AuditTemplate auditTemplate) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _openEditDialog(auditTemplate),
          color: AppTheme.blue600,
        ),
        IconButton(
          icon: Icon(
            auditTemplate.status == 'active'
                ? Icons.toggle_on
                : Icons.toggle_off,
            size: 20,
          ),
          onPressed: () => _toggleStatus(auditTemplate),
          color: auditTemplate.status == 'active'
              ? AppTheme.green600
              : AppTheme.gray500,
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: () => _deleteAuditTemplate(auditTemplate),
          color: AppTheme.red600,
        ),
      ],
    );
  }

  Widget _buildMobileActions(AuditTemplate auditTemplate) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _openEditDialog(auditTemplate);
            break;
          case 'toggle':
            _toggleStatus(auditTemplate);
            break;
          case 'delete':
            _deleteAuditTemplate(auditTemplate);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppTheme.blue600),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  auditTemplate.status == 'active'
                      ? Icons.toggle_on
                      : Icons.toggle_off,
                  size: 20,
                  color: auditTemplate.status == 'active'
                      ? AppTheme.green600
                      : AppTheme.gray500,
                ),
                SizedBox(width: 8),
                Text(
                  auditTemplate.status == 'active' ? 'Deactivate' : 'Activate',
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: AppTheme.red600),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
