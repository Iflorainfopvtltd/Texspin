import 'package:flutter/material.dart';
import '../utils/shared_preferences_manager.dart';
import 'staff_performance_list_dialog.dart';
import 'staff_performance_details_dialog.dart';

class StaffPerformanceEntryDialog extends StatefulWidget {
  const StaffPerformanceEntryDialog({super.key});

  @override
  State<StaffPerformanceEntryDialog> createState() =>
      _StaffPerformanceEntryDialogState();
}

class _StaffPerformanceEntryDialogState
    extends State<StaffPerformanceEntryDialog> {
  bool _isLoading = true;
  String? _role;
  String? _staffId;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final loginData = await SharedPreferencesManager.getLoginData();
    if (loginData != null) {
      final role = loginData['role'];
      String? staffId;

      if (loginData['staff'] is Map) {
        staffId = loginData['staff']['_id'] ?? loginData['staff']['id'];
      }

      if (mounted) {
        setState(() {
          _role = role;
          _staffId = staffId;
          _isLoading = false;
        });
      }
    } else {
      // Fallback or error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_role == 'admin' || _role == 'manager') {
      return const StaffPerformanceListDialog();
    } else if (_staffId != null) {
      return StaffPerformanceDetailsDialog(staffId: _staffId!);
    } else {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Unable to determine user role or staff ID.'),
        ),
      );
    }
  }
}
