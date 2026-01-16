import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/shared_preferences_manager.dart';
import 'add_inquiry_dialog.dart';

class DashboardLayout extends StatefulWidget {
  final String title;
  final String subtitle;
  final String userName;
  final List<NavigationItem> navigationItems;
  final Widget child;
  final VoidCallback? onLogout;
  final VoidCallback? onNotification;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.navigationItems,
    required this.child,
    this.onLogout,
    this.onNotification,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;
  bool _canAddInquiry = false;

  @override
  void initState() {
    super.initState();
    _checkUserPermissions();
  }

  Future<void> _checkUserPermissions() async {
    try {
      final loginData = await SharedPreferencesManager.getLoginData();
      if (loginData != null) {
        final role = loginData['role'];
        final staff = loginData['staff'];
        if (role == 'staff' &&
            staff is Map &&
            staff['department'] == 'Marketing') {
          if (mounted) {
            setState(() {
              _canAddInquiry = true;
            });
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SafeArea(
        child: Row(
          children: [
            // Side Navigation (Desktop)
            if (!isMobile)
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: AppTheme.gray200, width: 1),
                  ),
                ),
                child: _buildSideNav(),
              ),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(isMobile),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
      // Mobile Drawer
      drawer: isMobile ? Drawer(child: SafeArea(child: _buildSideNav())) : null,
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.gray200, width: 1)),
      ),
      child: Builder(
        builder: (BuildContext context) {
          return Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
              ],
              const Spacer(),
              if (_canAddInquiry)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddInquiryDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Inquiry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (widget.onNotification != null)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: widget.onNotification,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.red500,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 16),
              isMobile
                  ? PopupMenuButton(
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.blue100,
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppTheme.blue600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.blue100,
                                    child: Text(
                                      widget.userName.isNotEmpty
                                          ? widget.userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.blue600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.userName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.gray900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.subtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                        if (widget.onLogout != null)
                          PopupMenuItem(
                            onTap: widget.onLogout,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: AppTheme.gray600,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : InkWell(
                      onTap: () {
                        try {
                          final profileItem = widget.navigationItems.firstWhere(
                            (item) => item.label == 'Profile',
                          );
                          profileItem.onTap();
                        } catch (_) {
                          // Profile item not found
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.blue100,
                              child: Text(
                                widget.userName.isNotEmpty
                                    ? widget.userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppTheme.blue600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSideNav() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Image.asset('assets/images/LOGOh2.jpg', height: 60),
        ),

        Divider(height: 1, color: Colors.grey[300]),
        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.navigationItems.length,
            itemBuilder: (context, index) {
              final item = widget.navigationItems[index];
              final isSelected = _selectedIndex == index;
              return _buildNavItem(item, isSelected, index);
            },
          ),
        ),
        // Logout
        if (widget.onLogout != null) ...[
          Divider(height: 1, color: Colors.grey[300]),
          _buildNavItem(
            NavigationItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: widget.onLogout!,
            ),
            false,
            -1,
          ),
        ],
      ],
    );
  }

  Widget _buildNavItem(NavigationItem item, bool isSelected, int index) {
    return Builder(
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 900;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.blue50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected ? AppTheme.blue600 : AppTheme.gray600,
              size: 20,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? AppTheme.blue600 : AppTheme.gray700,
              ),
            ),
            onTap: () async {
              if (index >= 0) {
                setState(() {
                  _selectedIndex = index;
                });
              }

              // Close drawer on mobile if it's open
              if (isMobile && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }

              // Execute the callback
              final result = item.onTap();

              // If it's a Future, wait for it to complete
              if (result is Future) {
                await result;
              }

              // Reset to Dashboard (index 0) after action completes, but only for non-Dashboard items
              if (index > 0 && mounted) {
                setState(() {
                  _selectedIndex = 0;
                });
              }
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final dynamic Function() onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
