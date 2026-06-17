import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

enum AuthMode { login, signup, forgot }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  AuthMode _mode = AuthMode.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  static const _keyRememberMe = 'remember_me';
  static const _keyEmail = 'saved_email';

  // Regex simples pra email — evita chamar o Supabase com entrada claramente inválida.
  static final _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRememberMe) ?? false;
    if (remember) {
      final savedEmail = prefs.getString(_keyEmail) ?? '';
      setState(() {
        _rememberMe = true;
        _email.text = savedEmail;
      });
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_keyEmail, _email.text.trim());
    } else {
      await prefs.remove(_keyEmail);
    }
  }

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
        backgroundColor: error ? AppColors.destructive : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Valida os campos de login/cadastro. Retorna mensagem de erro ou null se ok.
  String? _validateForm({required bool isSignup}) {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty || (isSignup && name.isEmpty)) {
      return 'Preencha todos os campos';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Informe um email válido';
    }
    if (isSignup) {
      if (name.length < 2) {
        return 'Informe seu nome completo';
      }
      if (password.length < 8) {
        return 'A senha deve ter pelo menos 8 caracteres';
      }
    } else {
      if (password.length < 6) {
        return 'Senha muito curta';
      }
    }
    return null;
  }

  Future<void> _handleEmailAuth() async {
    final isSignup = _mode == AuthMode.signup;
    final validationError = _validateForm(isSignup: isSignup);
    if (validationError != null) {
      _toast(validationError, error: true);
      return;
    }

    setState(() => _loading = true);
    final auth = ref.read(authControllerProvider);
    try {
      if (isSignup) {
        await auth.signUp(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
        );
        _toast('Conta criada! Verifique seu email para confirmar.');
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
        await _saveRememberMe();
        _toast('Login realizado!');
        if (mounted) context.go('/');
      }
    } catch (e) {
      _toast(AuthController.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _toast('Insira seu email', error: true);
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _toast('Informe um email válido', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).resetPassword(email);
      _toast('Email de recuperação enviado!');
    } catch (e) {
      _toast(AuthController.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      _toast(AuthController.friendlyError(e), error: true);
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        SizedBox(width: 4),
                        Text('Voltar',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Recuperar Senha',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Enviaremos um link de recuperação para seu email.',
                    style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  Text('BAIRROMATCH',
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLogin
                        ? 'Entre para continuar sua jornada.'
                        : 'Comece sua aventura de viagem.',
                    style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogle,
                    icon: Icon(Icons.login, size: 18),
                    label: Text('Entrar com Google'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou com email',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                                fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: AppColors.coral,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            'Lembrar meu email',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _mode = AuthMode.forgot),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                                color: AppColors.coral,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                        InkWell(
                          onTap: () => setState(() =>
                              _mode = isLogin ? AuthMode.signup : AuthMode.login),
                          child: Text(
                            isLogin ? 'Criar conta' : 'Entrar',
                            style: TextStyle(
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
