import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/auth_page.dart';
import '../pages/home_page.dart';
import '../pages/not_found_page.dart';
import '../pages/reset_password_page.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthNotifier(ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      // /reset-password é acessível em qualquer estado (o usuário chega
      // nela pelo link do email antes de ter sessão nova).
      if (location == '/reset-password') return null;

      // Enquanto o Firebase ainda restaura a sessão (refresh da página), não
      // redireciona — evita deslogar o usuário no reload. A HomePage mostra um
      // loading até resolver.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.asData?.value != null;

      // Sem sessão: manda pro login, exceto se já estiver lá.
      if (!isLoggedIn && location != '/auth') {
        return '/auth';
      }

      // Com sessão: não deixa ficar na tela de login.
      if (isLoggedIn && location == '/auth') {
        return '/';
      }

      return null;
    },
  );
});

/// Ouve mudanças de auth e notifica o GoRouter para reconstruir rotas.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}
