import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_button.dart';
import 'dart:developer' as developer;

class EndPhaseFormsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const EndPhaseFormsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<EndPhaseFormsScreen> createState() => _EndPhaseFormsScreenState();
}

class _EndPhaseFormsScreenState extends State<EndPhaseFormsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _endPhaseForms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEndPhaseForms();
  }

  Future<void> _fetchEndPhaseForms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getEndPhaseForms();
      final allForms = response['endPhaseForms'] as List<dynamic>;
      
      // Filter forms for this project
      final projectForms = allForms.where((form) {
        final project = form['apqpProject'];
        return project != null && project['_id'] == widget.projectId;
      }).toList();

      setState(() {
        _endPhaseForms = projectForms.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching end phase forms: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteForm(String formId) async {
    try {
      await _apiService.deleteEndPhaseForm(id: formId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('End phase form deleted successfully'),
              ],
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        _fetchEndPhaseForms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _acceptForm(String formId) async {
    try {
      await _apiService.acceptEndPhaseForm(id: formId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('End phase form accepted'),
              ],
            ),
            backgroundColor: AppTheme.green500,
          ),
        );
        _fetchEndPhaseForms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  Future<void> _rejectForm(String formId) async {
    try {
      await _apiService.rejectEndPhaseForm(id: formId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('End phase form rejected'),
              ],
            ),
            backgroundColor: AppTheme.yellow500,
          ),
        );
        _fetchEndPhaseForms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.red500,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String formId, String phaseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete End Phase Form'),
        content: Text('Are you sure you want to delete the end phase form for $phaseName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () {
              Navigator.pop(context);
              _deleteForm(formId);
            },
            variant: ButtonVariant.destructive,
            size: ButtonSize.sm,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'End Phase Forms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              widget.projectName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                        onPressed: _fetchEndPhaseForms,
                        variant: ButtonVariant.outline,
                      ),
                    ],
                  ),
                )
              : _endPhaseForms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, size: 64, color: AppTheme.gray500),
                          const SizedBox(height: 16),
                          const Text(
                            'No end phase forms found',
                            style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: isMobile
                              ? _buildMobileView()
                              : isTablet
                                  ? _buildTabletView()
                                  : _buildDesktopView(),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildMobileView() {
    return Column(
      children: _endPhaseForms.map((form) => _buildMobileCard(form)).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> form) {
    final formId = form['_id'] as String;
    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final date = _formatDate(form['date'] as String?);
    final reviewNo = form['reviewNo'] as String? ?? 'N/A';
    final teamLeader = form['teamLeader'] as Map<String, dynamic>?;
    final teamLeaderName = teamLeader != null
        ? '${teamLeader['firstName']} ${teamLeader['lastName']}'
        : 'N/A';
    final teamMembers = form['teamMembers'] as List<dynamic>? ?? [];
    final attachments = form['attachments'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  phaseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              CustomBadge(text: reviewNo, variant: BadgeVariant.secondary),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Date', date),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, 'Team Leader', teamLeaderName),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.people, 'Team Members', '${teamMembers.length}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.attach_file, 'Attachments', '${attachments.length}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  onPressed: () => _acceptForm(formId),
                  variant: ButtonVariant.default_,
                  size: ButtonSize.sm,
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  onPressed: () => _rejectForm(formId),
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.red500),
                onPressed: () => _showDeleteConfirmation(formId, phaseName),
              ),
            ],
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildTabletView() {
    return _buildDesktopView();
  }

  Widget _buildDesktopView() {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'End Phase Forms',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppTheme.blue50),
              columns: const [
                DataColumn(label: Text('Phase', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Review No', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Team Leader', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Team Members', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: _endPhaseForms.map((form) => _buildDataRow(form)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> form) {
    final formId = form['_id'] as String;
    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final date = _formatDate(form['date'] as String?);
    final reviewNo = form['reviewNo'] as String? ?? 'N/A';
    final teamLeader = form['teamLeader'] as Map<String, dynamic>?;
    final teamLeaderName = teamLeader != null
        ? '${teamLeader['firstName']} ${teamLeader['lastName']}'
        : 'N/A';
    final teamMembers = form['teamMembers'] as List<dynamic>? ?? [];
    final attachments = form['attachments'] as List<dynamic>? ?? [];

    return DataRow(
      cells: [
        DataCell(Text(phaseName)),
        DataCell(CustomBadge(text: reviewNo, variant: BadgeVariant.secondary)),
        DataCell(Text(date)),
        DataCell(Text(teamLeaderName)),
        DataCell(Text('${teamMembers.length} members')),
        DataCell(Text('${attachments.length} files')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.green600),
                onPressed: () => _acceptForm(formId),
                tooltip: 'Accept',
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.yellow600),
                onPressed: () => _rejectForm(formId),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.red500),
                onPressed: () => _showDeleteConfirmation(formId, phaseName),
                tooltip: 'Delete',
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
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
