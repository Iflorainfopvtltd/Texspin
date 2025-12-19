import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';

class CreateAuditTemplateScreen extends StatefulWidget {
  const CreateAuditTemplateScreen({super.key});

  @override
  State<CreateAuditTemplateScreen> createState() => _CreateAuditTemplateScreenState();
}

class _CreateAuditTemplateScreenState extends State<CreateAuditTemplateScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Audit Template'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add functionality to create new audit template
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create template functionality coming soon!')),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                  Icons.description_outlined,
                  size: isMobile ? 64 : 80,
                  color: AppTheme.gray500,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Create Audit Template',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This feature will allow you to create custom audit templates\nusing audit types, segments, and questions.\nComing soon!',
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