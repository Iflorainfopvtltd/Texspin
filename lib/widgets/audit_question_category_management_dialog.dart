import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';
import 'audit_question_category_form_dialog.dart';

class AuditQuestionCategoryManagementDialog extends StatefulWidget {
  const AuditQuestionCategoryManagementDialog({super.key});

  @override
  State<AuditQuestionCategoryManagementDialog> createState() =>
      _AuditQuestionCategoryManagementDialogState();
}

class _AuditQuestionCategoryManagementDialogState
    extends State<AuditQuestionCategoryManagementDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAuditQuestionCategories();
      if (response['auditQusCategories'] != null) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            response['auditQusCategories'],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
      }
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
          AuditQuestionCategoryFormDialog(onSuccess: _fetchCategories),
    );
  }

  void _openEditDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AuditQuestionCategoryFormDialog(
        category: category,
        onSuccess: _fetchCategories,
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> category) async {
    final id = category['_id'] ?? category['id'];
    final currentStatus = (category['status'] ?? 'active')
        .toString()
        .toLowerCase();
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

    try {
      await _apiService.updateAuditQuestionCategoryStatus(
        id: id,
        status: newStatus,
      );
      await _fetchCategories();
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

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final name = category['name'] ?? 'Unknown';
    final id = category['_id'] ?? category['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
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
        await _apiService.deleteAuditQuestionCategory(id: id);
        await _fetchCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
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

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories.where((cat) {
      final name = (cat['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          const Icon(
            Icons.category_outlined,
            color: AppTheme.gray600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audit Question Categories',
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
          CustomTextInput(
            controller: _searchController,
            hint: 'Search categories...',
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
          Expanded(
            child: _isLoading && _categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _categories.isEmpty
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
                          onPressed: _fetchCategories,
                        ),
                      ],
                    ),
                  )
                : _filteredCategories.isEmpty
                ? const Center(child: Text('No categories found'))
                : ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final name = category['name'] ?? 'Unknown';
                      final status = (category['status'] ?? 'active')
                          .toString()
                          .toLowerCase();

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
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.gray900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    CustomBadge(
                                      text: status.toUpperCase(),
                                      variant: status == 'active'
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
                                    onPressed: () => _openEditDialog(category),
                                    color: AppTheme.blue600,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      status == 'active'
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleStatus(category),
                                    color: status == 'active'
                                        ? AppTheme.green600
                                        : AppTheme.gray500,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteCategory(category),
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
