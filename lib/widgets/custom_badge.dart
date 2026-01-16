import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeVariant { default_, secondary, destructive, outline }

class CustomBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;

  const CustomBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.default_,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case BadgeVariant.default_:
        backgroundColor = AppTheme.primary;
        textColor = AppTheme.primaryForeground;
        break;
      case BadgeVariant.secondary:
        backgroundColor = AppTheme.secondary;
        textColor = AppTheme.secondaryForeground;
        break;
      case BadgeVariant.destructive:
        backgroundColor = AppTheme.destructive;
        textColor = AppTheme.destructiveForeground;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.foreground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: variant == BadgeVariant.outline
            ? Border.all(color: AppTheme.border)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

