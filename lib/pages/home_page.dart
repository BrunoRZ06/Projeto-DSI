import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
<<<<<<< HEAD
import 'budget_page.dart';
import 'match_and_explore_page.dart';
=======
import 'map_explorer_page.dart';
import 'match_quiz_page.dart';
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
import 'profile_page.dart';
import 'quests_page.dart';
import 'itineraries_page.dart';
import '../providers/city_provider.dart';

<<<<<<< HEAD
/// Container principal com bottom nav.
/// Aba 0: Match + Explorar (unificados)
/// Aba 1: Gastos (BudgetPage) ← antes era "Explorar"
/// Aba 2: Roteiros
/// Aba 3: Missões
/// Aba 4: Perfil
=======
/// Container principal com bottom nav — equivale ao Index.tsx do React.
/// A decisão de mostrar login ou home agora é do router (via redirect),
/// então aqui a gente assume que o usuário já está autenticado.
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

<<<<<<< HEAD
=======
    // Loading inicial enquanto o Supabase hidrata a sessão.
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    if (authAsync.isLoading) {
      return const _LoadingScaffold();
    }

<<<<<<< HEAD
=======
    // Se o stream de auth falhar (sem rede, token inválido, etc.) mostra
    // tela de erro em vez de travar em loading.
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    if (authAsync.hasError) {
      return _ErrorScaffold(
        message: 'Não foi possível verificar sua sessão.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }

    final activeTab = ref.watch(activeTabProvider);

<<<<<<< HEAD
    // Aba 0 agora é a tela unificada Match + Explorar.
    // Quando o quiz termina, a própria MatchAndExplorePage exibe o mapa
    // na metade inferior — sem troca de aba.
    final pages = <Widget>[
      const MatchAndExplorePage(),
      const BudgetPage(),
=======
    final pages = <Widget>[
      MatchQuizPage(
        onCityFound: (city) {
          ref.read(cityProvider.notifier).setCity(city);
          ref.read(activeTabProvider.notifier).setTab(1);
        },
      ),
      const MapExplorerPage(),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
      const ItinerariesPage(),
      const QuestsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: activeTab, children: pages),
      bottomNavigationBar: AppBottomNav(
        activeTab: activeTab,
        onTabChange: (i) => ref.read(activeTabProvider.notifier).setTab(i),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.coral,
          ),
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
<<<<<<< HEAD
                const Icon(Icons.cloud_off,
                    size: 48, color: AppColors.mutedForeground),
=======
                Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
<<<<<<< HEAD
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.foreground),
=======
                  style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
<<<<<<< HEAD
                  child: const Text('Tentar novamente'),
=======
                  child: Text('Tentar novamente'),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
