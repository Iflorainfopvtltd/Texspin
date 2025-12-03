import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;

  const CustomProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
  });

  Color getProgressColor(double progress) {
    if (progress < 30) return AppTheme.red500;
    if (progress < 70) return AppTheme.yellow500;
    return AppTheme.green500;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value / 100,
        minHeight: height,
        backgroundColor: backgroundColor ?? AppTheme.gray200,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? getProgressColor(value),
        ),
      ),
    );
  }
}

