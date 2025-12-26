import 'package:flutter/material.dart';
import '../models/audit_main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/staff_audit_task_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/staff_audit_task_submission_dialog.dart';
import '../utils/shared_preferences_manager.dart';

class StaffAuditTasksScreen extends StatefulWidget {
  const StaffAuditTasksScreen({super.key});

  @override
  State<StaffAuditTasksScreen> createState() => _StaffAuditTasksScreenState();
}

class _StaffAuditTasksScreenState extends State<StaffAuditTasksScreen> {
  final ApiService _apiService = ApiService();
  List<AuditMain> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String? _currentStaffId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      _currentStaffId = staffId;

      final response = await _apiService.getStaffAuditMains(staffId: staffId);
      List<dynamic> list = [];

      if (response.containsKey('audits')) {
        list = response['audits'] as List;
      } else if (response.containsKey('auditMains')) {
        list = response['auditMains'] as List;
      } else if (response.containsKey('data')) {
        list = response['data'] as List;
      } else {
        // Try finding first list value
        for (var val in response.values) {
          if (val is List) {
            list = val;
            break;
          }
        }
      }

      setState(() {
        _tasks = list.map((item) => AuditMain.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTaskResponse(
    String auditId,
    String questionId,
    String action, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToAuditQuestion(
        auditId: auditId,
        questionId: questionId,
        action: action,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task $action successfully')));
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String auditId, String questionId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            CustomTextInput(
              label: 'Reason',
              controller: reasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleTaskResponse(
                  auditId,
                  questionId,
                  'reject',
                  reason: reasonController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Tasks'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _tasks.isEmpty
          ? const Center(child: Text('No audit tasks found'))
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return StaffAuditTaskCard(
                    task: task,
                    currentStaffId: _currentStaffId,
                    onAccept: (qId) =>
                        _handleTaskResponse(task.id, qId, 'approve'),
                    onReject: (qId) => _showRejectDialog(task.id, qId),
                    onSubmit: () {
                      showDialog(
                        context: context,
                        builder: (context) => StaffAuditTaskSubmissionDialog(
                          task: task,
                          onSubmitted: _loadTasks,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
