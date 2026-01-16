import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAlert extends StatelessWidget {
  final String message;
  final AlertVariant variant;
  final Widget? icon;

  const CustomAlert({
    super.key,
    required this.message,
    this.variant = AlertVariant.default_,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case AlertVariant.default_:
        backgroundColor = AppTheme.blue50;
        textColor = AppTheme.blue900;
        borderColor = AppTheme.blue200;
        break;
      case AlertVariant.destructive:
        backgroundColor = AppTheme.red500.withOpacity(0.1);
        textColor = AppTheme.destructive;
        borderColor = AppTheme.destructive;
        break;
      case AlertVariant.success:
        backgroundColor = AppTheme.green100;
        textColor = AppTheme.green600;
        borderColor = AppTheme.green500;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AlertVariant { default_, destructive, success }

