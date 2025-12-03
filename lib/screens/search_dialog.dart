import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_input.dart';
import '../widgets/custom_card.dart';

enum EntityType {
  designation,
  zone,
  department,
  phase,
  staff,
  activity,
  template,
  workCategory,
}

class SearchDialog extends StatefulWidget {
  final Function(EntityType type) onEntitySelected;

  const SearchDialog({super.key, required this.onEntitySelected});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _entities = [
    {
      'type': EntityType.designation,
      'title': 'Designation',
      'icon': Icons.work_outline,
      'color': AppTheme.blue600,
    },
    {
      'type': EntityType.zone,
      'title': 'Zone',
      'icon': Icons.location_on_outlined,
      'color': AppTheme.green600,
    },
    {
      'type': EntityType.department,
      'title': 'Department',
      'icon': Icons.business_outlined,
      'color': AppTheme.purple600,
    },
    {
      'type': EntityType.phase,
      'title': 'Phase',
      'icon': Icons.timeline_outlined,
      'color': AppTheme.yellow600,
    },
    {
      'type': EntityType.staff,
      'title': 'Staff',
      'icon': Icons.person_outline,
      'color': AppTheme.gray600,
    },
    {
      'type': EntityType.activity,
      'title': 'Activity',
      'icon': Icons.task_alt_outlined,
      'color': AppTheme.blue600,
    },
    {
      'type': EntityType.template,
      'title': 'Template',
      'icon': Icons.description_outlined,
      'color': AppTheme.yellow600,
    },
    {
      'type': EntityType.workCategory,
      'title': 'Work Category',
      'icon': Icons.category_outlined,
      'color': AppTheme.red600,
    },
  ];

  List<Map<String, dynamic>> get _filteredEntities {
    if (_searchQuery.isEmpty) {
      return _entities;
    }
    return _entities.where((entity) {
      return entity['title'].toString().toLowerCase().contains(
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
      backgroundColor: Colors.transparent,
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
          const Icon(Icons.search, color: AppTheme.gray600, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Search & Manage',
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
        hint: 'Search features...',
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
        child: _filteredEntities.isEmpty
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
                itemCount: _filteredEntities.length,
                itemBuilder: (context, index) {
                  final entity = _filteredEntities[index];
                  return _EntityCard(
                    title: entity['title'] as String,
                    icon: entity['icon'] as IconData,
                    color: entity['color'] as Color,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onEntitySelected(entity['type'] as EntityType);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EntityCard({
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(   
              title,
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
