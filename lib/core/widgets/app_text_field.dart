import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool enabled;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.value,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textHint, size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
