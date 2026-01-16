import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_input.dart';
import 'staff_performance_details_dialog.dart';

class StaffPerformanceListDialog extends StatefulWidget {
  const StaffPerformanceListDialog({super.key});

  @override
  State<StaffPerformanceListDialog> createState() =>
      _StaffPerformanceListDialogState();
}

class _StaffPerformanceListDialogState
    extends State<StaffPerformanceListDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getStaff();
      if (response['staff'] is List) {
        _staffList = List<Map<String, dynamic>>.from(response['staff']);
        _filterStaff();
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterStaff() {
    setState(() {
      _filteredStaff = _staffList.where((staff) {
        final matchesSearch =
            (staff['firstName'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (staff['lastName'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (staff['email'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Add more filter logic here if needed
        return matchesSearch;
      }).toList();
    });
  }

  void _showStaffDetails(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => StaffPerformanceDetailsDialog(
        staffId: staff['_id'] ?? staff['id'],
        staffName: '${staff['firstName']} ${staff['lastName']}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextInput(
                      hint: 'Search staff...',
                      controller: _searchController,
                      onChanged: (val) {
                        _searchQuery = val;
                        _filterStaff();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStaff.isEmpty
                  ? const Center(child: Text('No staff found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStaff.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final staff = _filteredStaff[index];
                        final name =
                            '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'
                                .trim();
                        final role = staff['role'] ?? 'Staff';
                        final department = staff['department'] ?? 'N/A';

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.gray200),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.blue100,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: AppTheme.blue600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '$role • $department',
                            style: const TextStyle(color: AppTheme.gray600),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: AppTheme.gray600,
                          ),
                          onTap: () => _showStaffDetails(staff),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppTheme.gray600),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  'Select a staff member to view details',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: AppTheme.gray500,
          ),
        ],
      ),
    );
  }
}
