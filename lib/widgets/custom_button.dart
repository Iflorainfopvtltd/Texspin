import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { default_, destructive, outline, secondary, ghost, link }

enum ButtonSize { sm, default_, lg }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.default_,
    this.size = ButtonSize.default_,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.default_:
        backgroundColor = AppTheme.primary;
        foregroundColor = AppTheme.primaryForeground;
        borderSide = null;
        break;
      case ButtonVariant.destructive:
        backgroundColor = AppTheme.destructive;
        foregroundColor = AppTheme.destructiveForeground;
        borderSide = null;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.foreground;
        borderSide = BorderSide(color: AppTheme.border);
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.secondary;
        foregroundColor = AppTheme.secondaryForeground;
        borderSide = null;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.foreground;
        borderSide = null;
        break;
      case ButtonVariant.link:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.primary;
        borderSide = null;
        break;
    }

    double height;
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case ButtonSize.sm:
        height = 32;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        fontSize = 14;
        break;
      case ButtonSize.default_:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 16;
        break;
      case ButtonSize.lg:
        height = 40;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8);
        fontSize = 16;
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: foregroundColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (variant == ButtonVariant.link) {
      return TextButton(
        onPressed: isDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        ),
        child: content,
      );
    }

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        color: isDisabled ? backgroundColor.withOpacity(0.5) : backgroundColor,
        border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(padding: padding, child: content),
        ),
      ),
    );
  }
}
