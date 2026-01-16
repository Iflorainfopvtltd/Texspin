import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_badge.dart';
import '../widgets/audit_question_form_dialog.dart';

class AuditQuestionsManagementScreen extends StatefulWidget {
  const AuditQuestionsManagementScreen({super.key});

  @override
  State<AuditQuestionsManagementScreen> createState() =>
      _AuditQuestionsManagementScreenState();
}

class _AuditQuestionsManagementScreenState
    extends State<AuditQuestionsManagementScreen> {
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
        content: Text('Are you sure you want to delete this question?'),
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

  void _startEditing(AuditQuestion auditQuestion) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Questions Management'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomCard(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.gray900,
                                            ),
                                          ),
                                          if (auditQuestion.answer != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Answer: ${auditQuestion.answer}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
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
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _startEditing(auditQuestion),
                                          color: AppTheme.blue600,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            auditQuestion.status == 'active'
                                                ? Icons.toggle_on
                                                : Icons.toggle_off,
                                            size: 24,
                                          ),
                                          onPressed: () =>
                                              _toggleStatus(auditQuestion),
                                          color:
                                              auditQuestion.status == 'active'
                                              ? AppTheme.green600
                                              : AppTheme.gray500,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          onPressed: () => _deleteAuditQuestion(
                                            auditQuestion,
                                          ),
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
      ),
    );
  }
}
