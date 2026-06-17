import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_auth_service.dart';

/// Stream do estado de autenticação do Firebase.
/// Equivale ao `onAuthStateChange` do Supabase.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

/// Usuário atual (null se não logado). Observa o authStateProvider.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Indica se já temos um usuário logado no momento — útil para route guards
/// e para decisões síncronas de UI sem precisar de `when` no AsyncValue.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Controller com os métodos de autenticação. A UI usa este provider em vez
/// de chamar `FirebaseAuth.instance` diretamente — deixa a lógica de backend
/// centralizada, facilita testar e trocar o provedor no futuro.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(firebaseAuthServiceProvider));
});

// Serviço de autenticação Firebase (provido separadamente)
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

class AuthController {
  final FirebaseAuthService _authService;

  AuthController(this._authService);

  /// Cadastra um novo usuário.
  /// O [fullName] não é usado diretamente no cadastro Firebase, mas pode ser
  /// salvo posteriormente no Firestore (ex.: após o cadastro).
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Firebase Auth não aceita metadados no signUp; podemos ignorar o nome
    // ou salvar no Firestore depois com o userId.
    final userCredential = await _authService.signUpWithEmail(email.trim(), password.trim());
    // Opcional: salvar o nome no perfil do Firebase User
    await userCredential.user?.updateDisplayName(fullName.trim());
    return userCredential;
  }

  /// Login com email e senha.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _authService.signInWithEmail(email.trim(), password.trim());
  }

  /// Envia email de recuperação de senha.
  Future<void> resetPassword(String email) async {
    return _authService.sendPasswordResetEmail(email.trim());
  }

  /// Atualiza a senha do usuário logado.
  Future<void> updatePassword(String newPassword) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuário não está logado');
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() => _authService.signOut();

  /// Traduz mensagens do FirebaseAuth para português, para exibir ao usuário.
  /// Sempre registra o erro original via debugPrint para facilitar o debug.
  static String friendlyError(Object error) {
    debugPrint('Auth error: $error');
    if (error is FirebaseAuthException) {
      final code = error.code;
      switch (code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou senha incorretos.';
        case 'email-already-in-use':
          return 'Já existe uma conta com este email.';
        case 'weak-password':
          return 'A senha deve ter pelo menos 6 caracteres.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
        case 'operation-not-allowed':
          return 'Este método de login não está habilitado.';
        default:
          return error.message ?? 'Ocorreu um erro na autenticação.';
      }
    }
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
}