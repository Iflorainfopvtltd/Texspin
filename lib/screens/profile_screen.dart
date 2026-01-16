import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Staff? _staff;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staffId = await SharedPreferencesManager.getStaffId();
      if (staffId == null || staffId.isEmpty) {
        throw Exception('No staff ID found');
      }

      final response = await _apiService.getStaffById(staffId: staffId);

      if (response['staff'] != null) {
        setState(() {
          _staff = Staff.fromJson(response['staff']);
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Profile'),
        // backgroundColor: AppTheme.primary,
        // foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.red500),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppTheme.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Retry',
                    onPressed: _loadProfile,
                    variant: ButtonVariant.default_,
                    size: ButtonSize.default_,
                  ),
                ],
              ),
            )
          : _staff == null
          ? const Center(child: Text('No profile data'))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    CustomCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              _staff!.fullName.isNotEmpty
                                  ? _staff!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _staff!.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(_staff!.role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _staff!.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _staff!.staffId,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Information
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.email, 'Email', _staff!.email),
                          if (_staff!.mobile != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone,
                              'Mobile',
                              _staff!.mobile!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Work Information
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_staff!.designation != null)
                            _buildInfoRow(
                              Icons.work,
                              'Designation',
                              _staff!.designation!,
                            ),
                          if (_staff!.department != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.business,
                              'Department',
                              _staff!.department!,
                            ),
                          ],
                          if (_staff!.zone != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.location_on,
                              'Zone',
                              _staff!.zone!,
                            ),
                          ],
                          if (_staff!.workCategory != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.category,
                              'Work Category',
                              _staff!.workCategory!,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.info, 'Status', _staff!.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    if (widget.onLogout != null)
                      CustomButton(
                        text: 'Logout',
                        onPressed: widget.onLogout,
                        variant: ButtonVariant.destructive,
                        size: ButtonSize.lg,
                        isFullWidth: true,
                        icon: const Icon(
                          Icons.logout,
                          size: 20,
                          color: AppTheme.primaryForeground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.gray600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.gray900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return AppTheme.blue500;
      case 'staff':
        return AppTheme.green500;
      case 'worker':
        return AppTheme.yellow500;
      default:
        return AppTheme.gray500;
    }
  }
}
