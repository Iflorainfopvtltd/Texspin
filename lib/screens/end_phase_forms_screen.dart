import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_badge.dart';
import '../widgets/custom_button.dart';
import '../widgets/end_phase_form_dialog.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

class EndPhaseFormsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Project? project;
  final String? userRole;

  const EndPhaseFormsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.project,
    this.userRole,
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

  void _showTeamMembers(List<dynamic> teamMembers, bool isMobile) {
    if (isMobile) {
      // Show dialog for mobile
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Team Members'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index] as Map<String, dynamic>;
                final name = '${member['firstName']} ${member['lastName']}';
                final email = member['email'] ?? '';
                final staffId = member['staffId'] ?? '';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.blue100,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.blue600),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('$email\n$staffId'),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      // Show popup menu for desktop/tablet
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );

      showMenu(
        context: context,
        position: position,
        items: teamMembers.map((member) {
          final memberMap = member as Map<String, dynamic>;
          final name = '${memberMap['firstName']} ${memberMap['lastName']}';
          final email = memberMap['email'] ?? '';
          
          return PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  void _showAttachments(List<dynamic> attachments, bool isMobile) {
    if (isMobile) {
      // Show dialog for mobile
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Attachments'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final attachment = attachments[index] as Map<String, dynamic>;
                final fileName = attachment['fileName'] ?? 'Unknown';
                final fileUrl = attachment['fileUrl'] ?? '';
                
                return ListTile(
                  leading: const Icon(Icons.attach_file, color: AppTheme.blue600),
                  title: Text(fileName),
                  trailing: IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.blue600),
                    onPressed: () => _downloadFile(fileUrl, fileName),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      // Show popup menu for desktop/tablet
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );

      showMenu(
        context: context,
        position: position,
        items: attachments.map((attachment) {
          final attachmentMap = attachment as Map<String, dynamic>;
          final fileName = attachmentMap['fileName'] ?? 'Unknown';
          final fileUrl = attachmentMap['fileUrl'] ?? '';
          
          return PopupMenuItem(
            onTap: () => _downloadFile(fileUrl, fileName),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: AppTheme.gray600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.download, size: 16, color: AppTheme.blue600),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  void _downloadFile(String fileUrl, String fileName) {
    // TODO: Implement file download
    // For web: use html.AnchorElement
    // For mobile: use path_provider and dio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: AppTheme.blue600,
      ),
    );
  }

  void _editForm(Map<String, dynamic> form, bool isMobile) {
    if (widget.project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project data not available'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    final phase = form['phase'] as Map<String, dynamic>?;
    final phaseId = phase?['_id'] ?? '';
    final phaseName = phase?['name'] ?? 'Unknown Phase';
    final formId = form['_id'] as String?;

    if (isMobile) {
      // Show full screen dialog for mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Edit End Phase Form'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: EndPhaseFormDialog(
              projectId: widget.projectId,
              phaseId: phaseId,
              phaseName: phaseName,
              project: widget.project!,
              isEditMode: true,
              existingFormData: form,
              formId: formId,
              onSuccess: () {
                Navigator.pop(context);
                _fetchEndPhaseForms();
              },
            ),
          ),
        ),
      );
    } else {
      // Show dialog for desktop/tablet
      showDialog(
        context: context,
        builder: (context) => EndPhaseFormDialog(
          projectId: widget.projectId,
          phaseId: phaseId,
          phaseName: phaseName,
          project: widget.project!,
          isEditMode: true,
          existingFormData: form,
          formId: formId,
          onSuccess: () {
            _fetchEndPhaseForms();
          },
        ),
      );
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
          InkWell(
            onTap: () => _showTeamMembers(teamMembers, true),
            child: _buildInfoRow(
              Icons.people,
              'Team Members',
              '${teamMembers.length} members',
              isClickable: true,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showAttachments(attachments, true),
            child: _buildInfoRow(
              Icons.attach_file,
              'Attachments',
              '${attachments.length} files',
              isClickable: true,
            ),
          ),
          const SizedBox(height: 16),
          // Show action buttons only for non-admin users
          if (widget.userRole != 'admin')
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Edit',
                    onPressed: () => _editForm(form, true),
                    variant: ButtonVariant.default_,
                    size: ButtonSize.sm,
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Delete',
                    onPressed: () => _showDeleteConfirmation(formId, phaseName),
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.sm,
                    icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                  ),
                ),
              ],
            )
          else
            // Show read-only message for admin users
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.blue200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: AppTheme.blue600),
                  SizedBox(width: 8),
                  Text(
                    'View Only',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.blue600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
        DataCell(
          InkWell(
            onTap: () => _showTeamMembers(teamMembers, false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${teamMembers.length} members'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.blue600),
              ],
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _showAttachments(attachments, false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${attachments.length} files'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.blue600),
              ],
            ),
          ),
        ),
        DataCell(
          widget.userRole != 'admin'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.blue600),
                    onPressed: () => _editForm(form, false),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red500),
                    onPressed: () => _showDeleteConfirmation(formId, phaseName),
                    tooltip: 'Delete',
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.blue50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.blue200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 14, color: AppTheme.blue600),
                        SizedBox(width: 4),
                        Text(
                          'View Only',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.blue600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isClickable = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isClickable ? AppTheme.blue600 : AppTheme.gray600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.gray600,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isClickable ? AppTheme.blue600 : AppTheme.gray900,
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ),
              if (isClickable)
                const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.blue600),
            ],
          ),
        ),
      ],
    );
  }
}
