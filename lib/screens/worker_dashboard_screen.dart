import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/profile_dialog.dart';

class WorkerDashboardScreen extends StatelessWidget {
  final Function(Project project) onViewProject;
  final VoidCallback? onLogout;
  final String? userName;

  const WorkerDashboardScreen({
    super.key,
    required this.onViewProject,
    this.onLogout,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Worker Dashboard',
      subtitle: 'Worker',
      userName: userName ?? 'Worker',
      navigationItems: [
        NavigationItem(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),
        NavigationItem(
          icon: Icons.folder_outlined,
          label: 'New Projects',
          onTap: () {},
        ),
        NavigationItem(
          icon: Icons.check_circle_outline,
          label: 'Audit Tasks',
          onTap: () {},
        ),
        NavigationItem(
          icon: Icons.assignment_outlined,
          label: 'Department Tasks',
          onTap: () {},
        ),

        NavigationItem(
          icon: Icons.person_outline,
          label: 'Individual Tasks',
          onTap: () {},
        ),
        NavigationItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        NavigationItem(
          icon: Icons.account_circle_outlined,
          label: 'Profile',
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => ProfileDialog(onLogout: onLogout),
            );
          },
        ),
      ],
      onLogout: onLogout,
      onNotification: () {},
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 80, color: AppTheme.yellow600),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, ${userName ?? 'Worker'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'current dashboard data',
                    style: TextStyle(fontSize: 18, color: AppTheme.gray600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
