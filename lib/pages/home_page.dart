import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'map_explorer_page.dart';
import 'match_quiz_page.dart';
import 'profile_page.dart';
import 'quests_page.dart';
import 'itineraries_page.dart';
import '../providers/city_provider.dart';

/// Container principal com bottom nav — equivale ao Index.tsx do React.
/// A decisão de mostrar login ou home agora é do router (via redirect),
/// então aqui a gente assume que o usuário já está autenticado.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    // Loading inicial enquanto o Supabase hidrata a sessão.
    if (authAsync.isLoading) {
      return const _LoadingScaffold();
    }

    // Se o stream de auth falhar (sem rede, token inválido, etc.) mostra
    // tela de erro em vez de travar em loading.
    if (authAsync.hasError) {
      return _ErrorScaffold(
        message: 'Não foi possível verificar sua sessão.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }

    final activeTab = ref.watch(activeTabProvider);

    final pages = <Widget>[
      MatchQuizPage(
        onCityFound: (city) {
          ref.read(cityProvider.notifier).setCity(city);
          ref.read(activeTabProvider.notifier).setTab(1);
        },
      ),
      const MapExplorerPage(),
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
                Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
