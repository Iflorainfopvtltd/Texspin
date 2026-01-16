import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import 'dart:developer' as developer;

class TaskUpdatesScreen extends StatefulWidget {
  final bool isDialog;

  const TaskUpdatesScreen({super.key, this.isDialog = false});

  @override
  State<TaskUpdatesScreen> createState() => _TaskUpdatesScreenState();
}

class _TaskUpdatesScreenState extends State<TaskUpdatesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _approvals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getProjectApprovals();
      setState(() {
        _approvals = (response['approvals'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching approvals: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTaskStatus(
    Map<String, dynamic> approval,
    String action, {
    String? rejectionReason,
  }) async {
    try {
      final projectId = approval['projectId']?.toString() ?? '';
      final phaseId = approval['phaseId']?.toString() ?? '';
      final activityId = approval['activityId']?.toString() ?? '';

      final response = await _apiService.updateApqpActivityStatus(
        projectId: projectId,
        phaseId: phaseId,
        activityId: activityId,
        fileAction: action, // 'approve' or 'reject'
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        // Use the message from API response if available, otherwise use default
        final successMessage =
            response['message']?.toString() ??
            (action == 'approve'
                ? 'Task approved successfully'
                : 'Task rejected successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: action == 'approve'
                ? AppTheme.green500
                : AppTheme.red500,
          ),
        );
        _fetchApprovals(); // Refresh the list
      }
    } catch (e) {
      developer.log('Error updating task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _showRejectDialog(Map<String, dynamic> approval, String activityName) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "$activityName"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Reject',
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppTheme.red500,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateTaskStatus(
                approval,
                'reject',
                rejectionReason: reasonController.text.trim(),
              );
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> approval, String activityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: Text('Are you sure you want to approve "$activityName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Approve',
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus(approval, 'approve');
            },
            variant: ButtonVariant.default_,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $fileName...'),
          backgroundColor: AppTheme.blue600,
        ),
      );

      // Construct full URL using ApiService baseUrl
      final String fullUrl = ApiService.baseUrl + fileUrl;
      final Uri url = Uri.parse(fullUrl);

      developer.log('Downloading file from: $fullUrl');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$fileName download started')),
                ],
              ),
              backgroundColor: AppTheme.green500,
            ),
          );
        }
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      developer.log('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error downloading $fileName: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (widget.isDialog) {
      // Dialog version without Scaffold and AppBar
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Custom header for dialog
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: AppTheme.gray200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.blue100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: AppTheme.blue600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Task Updates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.gray900,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: _buildContent(isMobile)),
          ],
        ),
      );
    }

    // Regular screen version with Scaffold and AppBar
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.gray900,
        ),
        title: const Text(
          'New Project Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
      ),
      body: _buildContent(isMobile),
    );
  }

  Widget _buildContent(bool isMobile) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
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
                  onPressed: _fetchApprovals,
                  variant: ButtonVariant.outline,
                ),
              ],
            ),
          )
        : _approvals.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: AppTheme.gray500),
                SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: isMobile ? _buildMobileView() : _buildDesktopView(),
              ),
            ),
          );
  }

  Widget _buildMobileView() {
    return Column(
      children: _approvals
          .map((approval) => _buildMobileCard(approval))
          .toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> approval) {
    final projectName =
        approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final activityName =
        approval['activityName']?.toString() ?? 'Unknown Activity';
    final uploadedBy = approval['uploadedBy']?.toString() ?? 'Unknown';
    final fileUrl = approval['fileUrl']?.toString() ?? '';
    final fileName = fileUrl.split('/').last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.red200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    color: AppTheme.red500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                      Text(
                        phaseName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.business, 'Project', projectName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Uploaded by', uploadedBy),
            const SizedBox(height: 16),
            // Download button
            if (fileUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Download File',
                    onPressed: () => _downloadFile(fileUrl, fileName),
                    variant: ButtonVariant.outline,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.download,
                      size: 16,
                      color: AppTheme.blue600,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    onPressed: () => _showApproveDialog(approval, activityName),
                    variant: ButtonVariant.default_,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () => _showRejectDialog(approval, activityName),
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.sm,
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopView() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APQP Task Approvals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          DataTable(
            headingRowColor: MaterialStateProperty.all(AppTheme.blue50),
            columns: const [
              DataColumn(
                label: Text(
                  'Project',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phase',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Activity',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Uploaded By',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows: _approvals
                .map((approval) => _buildDataRow(approval))
                .toList(),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> approval) {
    final projectName =
        approval['projectName']?.toString() ?? 'Unknown Project';
    final phaseName = approval['phaseName']?.toString() ?? 'Unknown Phase';
    final activityName =
        approval['activityName']?.toString() ?? 'Unknown Activity';
    final uploadedBy = approval['uploadedBy']?.toString() ?? 'Unknown';
    final fileUrl = approval['fileUrl']?.toString() ?? '';
    final fileName = fileUrl.split('/').last;

    return DataRow(
      cells: [
        DataCell(
          Text(projectName, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        DataCell(Text(phaseName, overflow: TextOverflow.ellipsis, maxLines: 1)),
        DataCell(
          Text(activityName, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        DataCell(
          Text(uploadedBy, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fileUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.download, color: AppTheme.blue600),
                  onPressed: () => _downloadFile(fileUrl, fileName),
                  tooltip: 'Download File',
                ),
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.green600,
                ),
                onPressed: () => _showApproveDialog(approval, activityName),
                tooltip: 'Approve',
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.red500),
                onPressed: () => _showRejectDialog(approval, activityName),
                tooltip: 'Reject',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gray600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
