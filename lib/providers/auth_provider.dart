import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Stream do estado de autenticação do Supabase.
/// Equivale ao `supabase.auth.onAuthStateChange` + `getSession` do React.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Usuário atual (null se não logado). Observa o authStateProvider.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.valueOrNull?.session?.user ?? supabase.auth.currentUser;
});

/// Indica se já temos um usuário logado no momento — útil para route guards
/// e para decisões síncronas de UI sem precisar de `when` no AsyncValue.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Controller com os métodos de autenticação. A UI usa este provider em vez
/// de chamar `supabase.auth.*` diretamente — deixa a lógica de backend
/// centralizada, facilita testar e trocar o provedor no futuro.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  /// Cadastra um novo usuário.
  /// [fullName] é salvo em `user_metadata.full_name`.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      // Redireciona a confirmação de email pra abrir o app.
      emailRedirectTo: 'io.supabase.bairromatch://login-callback',
    );
  }

  /// Login com email e senha.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Envia email de recuperação de senha.
  Future<void> resetPassword(String email) async {
    return supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.bairromatch://reset-password',
    );
  }

  /// Atualiza a senha do usuário logado.
  Future<UserResponse> updatePassword(String newPassword) {
    return supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Login via OAuth do Google. Retorna quando o fluxo é iniciado
  /// (o callback real chega pelo `onAuthStateChange`).
  Future<bool> signInWithGoogle() {
    return supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.bairromatch://login-callback',
    );
  }

  Future<void> signOut() => supabase.auth.signOut();

  /// Traduz mensagens do Supabase para português, para exibir ao usuário.
  /// Sempre registra o erro original via debugPrint para facilitar o debug.
  static String friendlyError(Object error) {
    debugPrint('Auth error: $error');
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email ou senha incorretos.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Confirme seu email antes de entrar.';
      }
      if (msg.contains('user already registered')) {
        return 'Já existe uma conta com este email.';
      }
      if (msg.contains('password should be')) {
        return 'A senha não atende aos requisitos mínimos.';
      }
      if (msg.contains('rate limit')) {
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      }
      return error.message;
    }
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
}
