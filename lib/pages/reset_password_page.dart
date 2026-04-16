import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.destructive : AppColors.foreground,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reset() async {
    if (_password.text.length < 6) {
      _toast('A senha deve ter pelo menos 6 caracteres', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: _password.text));
      _toast('Senha atualizada com sucesso!');
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => context.go('/'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.mutedForeground),
                        SizedBox(width: 4),
                        Text('Voltar',
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Nova Senha',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.foreground)),
                  const SizedBox(height: 8),
                  const Text(
                    'Digite sua nova senha abaixo.',
                    style: TextStyle(fontSize: 15, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _password,
                    hint: 'Nova senha',
                    icon: LucideIcons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _reset,
                    child: Text(_loading ? 'Salvando...' : 'Atualizar Senha'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
