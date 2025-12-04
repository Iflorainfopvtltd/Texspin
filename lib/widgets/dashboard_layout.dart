import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Row(
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
      // Mobile Drawer
      drawer: isMobile
          ? Drawer(
              child: _buildSideNav(),
            )
          : null,
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          const SizedBox(width: 8),
          Text(
            'Thursday, December 4, 2025',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray600,
            ),
          ),
          const Spacer(),
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
          Row(
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
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Column(
      children: [
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
           child: Image.asset(
                        'assets/images/LOGOh2.jpg',
                        height: 60,
                      ),
         ),
      

      Divider(height: 1,color: Colors.grey[300],),
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
          Divider(height: 1,color: Colors.grey[300],),
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
        onTap: () {
          if (index >= 0) {
            setState(() {
              _selectedIndex = index;
            });
          }
          item.onTap();
        },
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
