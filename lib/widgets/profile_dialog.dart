import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_manager.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

class ProfileDialog extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileDialog({
    super.key,
    this.onLogout,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
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

  void _handleLogout() {
    Navigator.of(context).pop(); // Close dialog first
    if (widget.onLogout != null) {
      widget.onLogout!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : (isMediumScreen ? 40 : 80),
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : (isMediumScreen ? 600 : 700),
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
_buildHeader(context),
            // // Header with gradient
            // Container(
            //   padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.only(
            //       topLeft: Radius.circular(isSmallScreen ? 16 : 24),
            //       topRight: Radius.circular(isSmallScreen ? 16 : 24),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.person,
            //         color: Colors.white,
            //         size: isSmallScreen ? 24 : 28,
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Text(
            //           'Profile',
            //           style: TextStyle(
            //             color: Colors.white,
            //             fontSize: isSmallScreen ? 20 : 24,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //       IconButton(
            //         icon: const Icon(Icons.close, color: Colors.white),
            //         onPressed: () => Navigator.of(context).pop(),
            //         padding: EdgeInsets.zero,
            //         constraints: const BoxConstraints(),
            //       ),
            //     ],
            //   ),
            // ),

            // // Content
            Flexible(
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                                Text(
                                  _error!,
                                  style: TextStyle(color: AppTheme.gray600),
                                  textAlign: TextAlign.center,
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
                          ),
                        )
                      : _staff == null
                          ? const Center(child: Text('No profile data'))
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Profile Avatar and Name
                                  Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                _getRoleColor(_staff!.role),
                                                _getRoleColor(_staff!.role).withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getRoleColor(_staff!.role).withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: isSmallScreen ? 50 : 60,
                                            backgroundColor: Colors.transparent,
                                            child: Text(
                                              _staff!.fullName.isNotEmpty
                                                  ? _staff!.fullName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 36 : 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _staff!.fullName,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 22 : 26,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.gray900,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 12 : 16,
                                            vertical: isSmallScreen ? 6 : 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _getRoleColor(_staff!.role),
                                                _getRoleColor(_staff!.role).withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getRoleColor(_staff!.role).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _staff!.role.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 10 : 12,
                                            vertical: isSmallScreen ? 4 : 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.gray100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _staff!.staffId,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 13 : 14,
                                              color: AppTheme.gray700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 32),

                                  // Contact Information Card
                                  _buildInfoCard(
                                    title: 'Contact Information',
                                    icon: Icons.contact_mail,
                                    isSmallScreen: isSmallScreen,
                                    children: [
                                      _buildInfoRow(
                                        Icons.email_outlined,
                                        'Email',
                                        _staff!.email,
                                        isSmallScreen,
                                      ),
                                      if (_staff!.mobile != null) ...[
                                        SizedBox(height: isSmallScreen ? 12 : 16),
                                        _buildInfoRow(
                                          Icons.phone_outlined,
                                          'Mobile',
                                          _staff!.mobile!,
                                          isSmallScreen,
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Work Information Card
                                  _buildInfoCard(
                                    title: 'Work Information',
                                    icon: Icons.work_outline,
                                    isSmallScreen: isSmallScreen,
                                    children: [
                                      if (_staff!.designation != null)
                                        _buildInfoRow(
                                          Icons.badge_outlined,
                                          'Designation',
                                          _staff!.designation!,
                                          isSmallScreen,
                                        ),
                                      if (_staff!.department != null) ...[
                                        SizedBox(height: isSmallScreen ? 12 : 16),
                                        _buildInfoRow(
                                          Icons.business_outlined,
                                          'Department',
                                          _staff!.department!,
                                          isSmallScreen,
                                        ),
                                      ],
                                      if (_staff!.zone != null) ...[
                                        SizedBox(height: isSmallScreen ? 12 : 16),
                                        _buildInfoRow(
                                          Icons.location_on_outlined,
                                          'Zone',
                                          _staff!.zone!,
                                          isSmallScreen,
                                        ),
                                      ],
                                      if (_staff!.workCategory != null) ...[
                                        SizedBox(height: isSmallScreen ? 12 : 16),
                                        _buildInfoRow(
                                          Icons.category_outlined,
                                          'Work Category',
                                          _staff!.workCategory!,
                                          isSmallScreen,
                                        ),
                                      ],
                                      SizedBox(height: isSmallScreen ? 12 : 16),
                                      _buildInfoRow(
                                        Icons.info_outline,
                                        'Status',
                                        _staff!.status.toUpperCase(),
                                        isSmallScreen,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 32),

                                  // Logout Button
                                  if (widget.onLogout != null)
                                      CustomButton(
                                        text: 'Logout',
                                        onPressed: _handleLogout,
                                        variant: ButtonVariant.secondary,
                                        size: isSmallScreen ? ButtonSize.default_ : ButtonSize.lg,
                                        isFullWidth: true,
                                        icon: Icon(
                                          Icons.logout,
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: AppTheme.gray200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isSmallScreen ? 18 : 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: isSmallScreen ? 16 : 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: AppTheme.gray900,
                  fontWeight: FontWeight.w600,
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

 Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppTheme.gray600, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Prodile',
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