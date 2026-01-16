import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_card.dart';

enum AuditOption {
  createTemplate,
  auditSegment,
  auditType,
  auditQuestionCategory,
  auditQuestions,
  getAllAudits,
  createAudit,
}

class AuditDialog extends StatefulWidget {
  final Function(AuditOption type) onAuditSelected;

  const AuditDialog({super.key, required this.onAuditSelected});

  @override
  State<AuditDialog> createState() => _AuditDialogState();
}

class _AuditDialogState extends State<AuditDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _auditOptions = [
    {
      'type': AuditOption.createTemplate,
      'title': 'Create Audit Template',
      'icon': Icons.description_outlined,
      'color': AppTheme.blue600,
    },
    {
      'type': AuditOption.auditSegment,
      'title': 'Audit Segment',
      'icon': Icons.segment_outlined,
      'color': AppTheme.green600,
    },
    {
      'type': AuditOption.auditType,
      'title': 'Audit Type',
      'icon': Icons.category_outlined,
      'color': AppTheme.purple600,
    },
    {
      'type': AuditOption.auditQuestionCategory,
      'title': 'Audit Question Category',
      'icon': Icons.label_outline,
      'color': AppTheme.orange600,
    },
    {
      'type': AuditOption.auditQuestions,
      'title': 'Audit Questions',
      'icon': Icons.quiz_outlined,
      'color': AppTheme.yellow600,
    },
    {
      'type': AuditOption.getAllAudits,
      'title': 'Get All Audits',
      'icon': Icons.list_alt_outlined,
      'color': AppTheme.red600,
    },
  ];

  List<Map<String, dynamic>> get _filteredOptions {
    if (_searchQuery.isEmpty) {
      return _auditOptions;
    }
    return _auditOptions.where((option) {
      return option['title'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight - keyboard - 40,
                maxWidth: 800,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboard),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context),
                        _buildSearchBar(),
                        _buildGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
            Icons.assignment_outlined,
            color: AppTheme.gray600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audit Management',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomTextInput(
        controller: _searchController,
        hint: 'Search audit options...',
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
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
    );
  }

  Widget _buildGrid() {
    final width = MediaQuery.of(context).size.width;

    int crossCount = 4; // default for web

    if (width < 600) {
      crossCount = 2; // mobile
    } else if (width < 900) {
      crossCount = 3; // tablet
    }

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _filteredOptions.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: AppTheme.gray300),
                  const SizedBox(height: 12),
                  Text(
                    'No results found',
                    style: TextStyle(fontSize: 16, color: AppTheme.gray600),
                  ),
                ],
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  return _AuditCard(
                    title: option['title'] as String,
                    icon: option['icon'] as IconData,
                    color: option['color'] as Color,
                    onTap: () {
                      widget.onAuditSelected(option['type'] as AuditOption);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AuditCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
