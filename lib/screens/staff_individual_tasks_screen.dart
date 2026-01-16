import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/staff_individual_task_card.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/staff_individual_task_details_dialog.dart';
import '../widgets/staff_individual_task_submission_dialog.dart';

class StaffIndividualTasksScreen extends StatefulWidget {
  const StaffIndividualTasksScreen({super.key});

  @override
  State<StaffIndividualTasksScreen> createState() =>
      _StaffIndividualTasksScreenState();
}

class _StaffIndividualTasksScreenState
    extends State<StaffIndividualTasksScreen> {
  final ApiService _apiService = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

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
      final response = await _apiService.getTasks();
      if (response['tasks'] != null) {
        setState(() {
          List<Task> parsedTasks = (response['tasks'] as List)
              .map((task) => Task.fromJson(task))
              .toList();

          parsedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _tasks = parsedTasks;
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

  Future<void> _handleTaskResponse(
    String taskId,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiService.respondToTask(
        taskId: taskId,
        status: status,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task $status successfully')));
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

  void _showRejectDialog(String taskId) {
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
                  taskId,
                  'rejected',
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
        title: const Text('Individual Tasks'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _tasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return StaffIndividualTaskCard(
                    task: task,
                    onAccept: () => _handleTaskResponse(task.id, 'approved'),
                    onReject: () => _showRejectDialog(task.id),
                    onViewDetails: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            StaffIndividualTaskDetailsDialog(task: task),
                      );
                    },
                    onSubmit: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            StaffIndividualTaskSubmissionDialog(
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
