import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';
import '../widgets/audit_question_form_dialog.dart';

class AuditQuestionsManagementDialog extends StatefulWidget {
  const AuditQuestionsManagementDialog({super.key});

  @override
  State<AuditQuestionsManagementDialog> createState() =>
      _AuditQuestionsManagementDialogState();
}

class _AuditQuestionsManagementDialogState
    extends State<AuditQuestionsManagementDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AuditQuestion> _auditQuestions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAuditQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAuditQuestions();
      final auditQuestions = (response['auditQuestions'] as List)
          .map((json) => AuditQuestion.fromJson(json))
          .toList();

      setState(() {
        _auditQuestions = auditQuestions;
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AuditQuestionFormDialog(onSuccess: _fetchAuditQuestions),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            AuditQuestionFormDialog(onSuccess: _fetchAuditQuestions),
      );
    }
  }

  void _openEditDialog(AuditQuestion auditQuestion) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuditQuestionFormDialog(
            auditQuestion: auditQuestion,
            onSuccess: _fetchAuditQuestions,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AuditQuestionFormDialog(
          auditQuestion: auditQuestion,
          onSuccess: _fetchAuditQuestions,
        ),
      );
    }
  }

  Future<void> _toggleStatus(AuditQuestion auditQuestion) async {
    final newStatus = auditQuestion.status == 'active' ? 'inactive' : 'active';

    try {
      await _apiService.updateAuditQuestionStatus(
        id: auditQuestion.id,
        status: newStatus,
      );
      await _fetchAuditQuestions();
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

  Future<void> _deleteAuditQuestion(AuditQuestion auditQuestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audit Question'),
        content: const Text('Are you sure you want to delete this question?'),
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
        await _apiService.deleteAuditQuestion(id: auditQuestion.id);
        await _fetchAuditQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audit question deleted successfully'),
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

  List<AuditQuestion> get _filteredAuditQuestions {
    if (_searchQuery.isEmpty) return _auditQuestions;
    return _auditQuestions.where((auditQuestion) {
      return auditQuestion.question.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (auditQuestion.answer?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
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
          const Icon(Icons.quiz_outlined, color: AppTheme.gray600, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audit Questions Management',
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
            hint: 'Search audit questions...',
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
            child: _isLoading && _auditQuestions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _auditQuestions.isEmpty
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
                          onPressed: _fetchAuditQuestions,
                        ),
                      ],
                    ),
                  )
                : _filteredAuditQuestions.isEmpty
                ? const Center(child: Text('No audit questions found'))
                : ListView.builder(
                    itemCount: _filteredAuditQuestions.length,
                    itemBuilder: (context, index) {
                      final auditQuestion = _filteredAuditQuestions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CustomCard(
                          padding: const EdgeInsets.all(12),
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
                                          auditQuestion.question,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                        if (auditQuestion.answer != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Answer: ${auditQuestion.answer}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        CustomBadge(
                                          text: auditQuestion.status
                                              .toUpperCase(),
                                          variant:
                                              auditQuestion.status == 'active'
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
                                        onPressed: () =>
                                            _openEditDialog(auditQuestion),
                                        color: AppTheme.blue600,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          auditQuestion.status == 'active'
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _toggleStatus(auditQuestion),
                                        color: auditQuestion.status == 'active'
                                            ? AppTheme.green600
                                            : AppTheme.gray500,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _deleteAuditQuestion(auditQuestion),
                                        color: AppTheme.red600,
                                      ),
                                    ],
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
