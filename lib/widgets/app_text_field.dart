import 'package:flutter/material.dart';

/// Input padronizado com ícone à esquerda.
/// Todas as cores vêm do Theme.of(context) — funciona em light e dark mode
/// sem nenhuma referência a AppColors estáticos.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Lê o colorScheme UMA vez para o contexto atual (light ou dark)
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: (_) => onSubmitted?.call(),
      onChanged: onChanged,
      // Texto digitado herda onSurface do inputDecorationTheme,
      // mas reforçamos aqui para garantir contraste.
      style: TextStyle(fontSize: 15, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        // hintStyle vem do inputDecorationTheme configurado no AppTheme —
        // usa onSurfaceVariant (#A1A1A1 dark / #7B8494 light) automaticamente.
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: cs.onSurfaceVariant),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}
