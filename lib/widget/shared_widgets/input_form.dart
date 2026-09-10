// --- Custom Widget ---
import 'package:admin/app_constants/app_colors.dart';
import 'package:flutter/material.dart'; 
class InputForm extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  const InputForm({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        validator: validator ??
            (v) => (v == null || v.isEmpty) ? "Required field" : null,
        decoration: inputDecoration(hintText,
            icon: Icon(icon, color: AppColors.primary), suffix: suffixIcon),
      ),
    );
  }
}

InputDecoration inputDecoration(String label, {Icon? icon, Widget? suffix}) {
  return InputDecoration(
    prefixIcon: icon,
    suffixIcon: suffix,
    hintText: label,
    hintStyle: const TextStyle(fontWeight: FontWeight.w500),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
