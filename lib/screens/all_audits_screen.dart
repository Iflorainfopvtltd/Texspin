import 'package:flutter/material.dart';
import '../widgets/all_audits_dialog.dart';

class AllAuditsScreen extends StatelessWidget {
  const AllAuditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AllAuditsDialog(isFullScreen: true);
  }
}
