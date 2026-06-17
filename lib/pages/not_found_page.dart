import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('404',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.coral)),
            const SizedBox(height: 12),
<<<<<<< HEAD
            const Text('Página não encontrada',
                style: TextStyle(
                    fontSize: 16, color: AppColors.mutedForeground)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar para o início'),
=======
            Text('Página não encontrada',
                style: TextStyle(
                    fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Voltar para o início'),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
            ),
          ],
        ),
      ),
    );
  }
}
