import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'auth_page.dart';
import 'map_explorer_page.dart';
import 'match_quiz_page.dart';
import 'profile_page.dart';
import 'quests_page.dart';

/// Container principal com bottom nav — equivale ao Index.tsx do React.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authAsync = ref.watch(authStateProvider);

    // Loading inicial enquanto o Supabase hidrata a sessão.
    if (authAsync.isLoading) {
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

    if (user == null) {
      return const AuthPage();
    }

    final activeTab = ref.watch(activeTabProvider);

    final pages = <Widget>[
      MatchQuizPage(
        onCityFound: (city) {
          ref.read(cityProvider.notifier).state = city;
          ref.read(activeTabProvider.notifier).state = 1;
        },
      ),
      const MapExplorerPage(),
      const QuestsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: activeTab, children: pages),
      bottomNavigationBar: AppBottomNav(
        activeTab: activeTab,
        onTabChange: (i) => ref.read(activeTabProvider.notifier).state = i,
      ),
    );
  }
}
