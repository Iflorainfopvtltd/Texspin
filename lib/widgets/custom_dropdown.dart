import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomDropdownButtonFormField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? Function(T?)? validator;
  final Widget? suffixIcon;

  const CustomDropdownButtonFormField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.value,
    this.items,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.foreground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.mutedForeground),
            errorText: errorText,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.ring, width: 3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.destructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.destructive, width: 3),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.mutedForeground,
          ),
          iconEnabledColor: AppTheme.mutedForeground,
          iconDisabledColor: AppTheme.gray300,
          isExpanded: true,
        ),
      ],
    );
  }
}

