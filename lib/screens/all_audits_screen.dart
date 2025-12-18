import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';

class AllAuditsScreen extends StatefulWidget {
  const AllAuditsScreen({super.key});

  @override
  State<AllAuditsScreen> createState() => _AllAuditsScreenState();
}

class _AllAuditsScreenState extends State<AllAuditsScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Audits'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: CustomCard(
            padding: EdgeInsets.all(isMobile ? 32 : 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: isMobile ? 64 : 80,
                  color: AppTheme.gray500,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'All Audits',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This feature will display all audit records and templates.\nComing soon!',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}