import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

enum AuthMode { login, signup, forgot }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _mode = AuthMode.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
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

  Future<void> _handleEmailAuth() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _toast('Preencha todos os campos', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      if (_mode == AuthMode.signup) {
        await supabase.auth.signUp(
          email: _email.text,
          password: _password.text,
          data: {'full_name': _name.text},
        );
        _toast('Conta criada! Verifique seu email.');
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text,
          password: _password.text,
        );
        _toast('Login realizado!');
      }
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Erro na autenticação', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgot() async {
    if (_email.text.isEmpty) {
      _toast('Insira seu email', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.auth.resetPasswordForEmail(
        _email.text,
        redirectTo: 'io.supabase.bairromatch://reset-password',
      );
      _toast('Email de recuperação enviado!');
    } on AuthException catch (e) {
      _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (_) {
      _toast('Erro ao entrar com Google', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == AuthMode.forgot) return _buildForgot();
    return _buildLoginSignup();
  }

  Widget _buildForgot() {
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
                    onTap: () => setState(() => _mode = AuthMode.login),
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
                  Text('Recuperar Senha',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.foreground)),
                  const SizedBox(height: 8),
                  const Text(
                    'Enviaremos um link de recuperação para seu email.',
                    style: TextStyle(fontSize: 15, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _email,
                    hint: 'seu@email.com',
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _handleForgot,
                    child: Text(_loading ? 'Enviando...' : 'Enviar Link'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSignup() {
    final isLogin = _mode == AuthMode.login;
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
                  const Text('BAIRROMATCH',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Bem-vindo de volta' : 'Criar conta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLogin
                        ? 'Entre para continuar sua jornada.'
                        : 'Comece sua aventura de viagem.',
                    style: const TextStyle(fontSize: 15, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogle,
                    icon: const Icon(LucideIcons.chrome, size: 18),
                    label: const Text('Entrar com Google'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou com email',
                            style: TextStyle(
                                color: AppColors.mutedForeground.withValues(alpha: 0.9),
                                fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!isLogin) ...[
                    AppTextField(
                        controller: _name, hint: 'Seu nome', icon: LucideIcons.user),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    controller: _email,
                    hint: 'seu@email.com',
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _password,
                    hint: 'Senha',
                    icon: LucideIcons.lock,
                    obscureText: true,
                  ),
                  if (isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => setState(() => _mode = AuthMode.forgot),
                        child: const Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _handleEmailAuth,
                    child: Text(_loading
                        ? 'Carregando...'
                        : (isLogin ? 'Entrar' : 'Criar Conta')),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin ? 'Não tem conta? ' : 'Já tem conta? ',
                          style: const TextStyle(
                              color: AppColors.mutedForeground, fontSize: 14),
                        ),
                        InkWell(
                          onTap: () => setState(() =>
                              _mode = isLogin ? AuthMode.signup : AuthMode.login),
                          child: Text(
                            isLogin ? 'Criar conta' : 'Entrar',
                            style: const TextStyle(
                                color: AppColors.coral,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
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
