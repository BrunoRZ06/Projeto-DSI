import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'budget_page.dart';
import 'match_and_explore_page.dart';
import 'profile_page.dart';
import 'quests_page.dart';
import 'itineraries_page.dart';
import '../providers/city_provider.dart';

/// Container principal com bottom nav.
/// Aba 0: Match + Explorar (unificados)
/// Aba 1: Gastos (BudgetPage) ← antes era "Explorar"
/// Aba 2: Roteiros
/// Aba 3: Missões
/// Aba 4: Perfil
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    if (authAsync.isLoading) {
      return const _LoadingScaffold();
    }

    if (authAsync.hasError) {
      return _ErrorScaffold(
        message: 'Não foi possível verificar sua sessão.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }

    final activeTab = ref.watch(activeTabProvider);

    // Aba 0 agora é a tela unificada Match + Explorar.
    // Quando o quiz termina, a própria MatchAndExplorePage exibe o mapa
    // na metade inferior — sem troca de aba.
    final pages = <Widget>[
      const MatchAndExplorePage(),
      const BudgetPage(),
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
                const Icon(Icons.cloud_off,
                    size: 48, color: AppColors.mutedForeground),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.foreground),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
