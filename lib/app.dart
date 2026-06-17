import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

<<<<<<< HEAD
=======
import 'providers/theme_provider.dart';
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class VibeCoralQuestApp extends ConsumerWidget {
  const VibeCoralQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
<<<<<<< HEAD
=======
    final themeMode = ref.watch(themeModeProvider);
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a

    return MaterialApp.router(
      title: 'BairroMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
<<<<<<< HEAD
=======
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
      routerConfig: router,
    );
  }
}
