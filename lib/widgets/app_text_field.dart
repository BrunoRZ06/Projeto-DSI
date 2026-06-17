import 'package:flutter/material.dart';

<<<<<<< HEAD
import '../theme/app_theme.dart';

/// Input padronizado com ícone à esquerda — equivale ao `<Input className="pl-10 h-12 bg-secondary...">`
/// usado em várias telas do projeto original.
=======
/// Input padronizado com ícone à esquerda.
/// Todas as cores vêm do Theme.of(context) — funciona em light e dark mode
/// sem nenhuma referência a AppColors estáticos.
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmitted;
<<<<<<< HEAD
=======
  final ValueChanged<String>? onChanged;
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a

  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
<<<<<<< HEAD
=======
    this.onChanged,
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
    // Lê o colorScheme UMA vez para o contexto atual (light ou dark)
    final cs = Theme.of(context).colorScheme;

>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: (_) => onSubmitted?.call(),
<<<<<<< HEAD
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: AppColors.mutedForeground),
=======
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
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}
