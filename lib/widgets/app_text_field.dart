import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Input padronizado com ícone à esquerda — equivale ao `<Input className="pl-10 h-12 bg-secondary...">`
/// usado em várias telas do projeto original.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmitted;

  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: AppColors.mutedForeground),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}
