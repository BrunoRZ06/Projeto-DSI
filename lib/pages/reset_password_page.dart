import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
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
    final password = _password.text;
    final confirm = _confirmPassword.text;

    if (password.length < 8) {
      _toast('A senha deve ter pelo menos 8 caracteres', error: true);
      return;
    }
    if (password != confirm) {
      _toast('As senhas não coincidem', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).updatePassword(password);
      _toast('Senha atualizada com sucesso!');
      if (mounted) context.go('/');
    } catch (e) {
      _toast(AuthController.friendlyError(e), error: true);
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
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmPassword,
                    hint: 'Confirmar nova senha',
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
