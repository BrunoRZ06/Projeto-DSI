import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChange;

  const AppBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  static const _tabs = <(IconData, String)>[
    (LucideIcons.compass, 'Match'),
<<<<<<< HEAD
    (LucideIcons.wallet, 'Gastos'),
=======
    (LucideIcons.map, 'Explorar'),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    (LucideIcons.route, 'Roteiros'),
    (LucideIcons.trophy, 'Missões'),
    (LucideIcons.user, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
=======
    final cs = Theme.of(context).colorScheme;
    // Fundo e borda acompanham o tema: surface no dark (#1E1E1E), branco no light
    final bgColor = cs.surface;
    final borderColor = cs.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final (icon, label) = _tabs[i];
              final isActive = activeTab == i;
<<<<<<< HEAD
              final color = isActive ? AppColors.coral : AppColors.mutedForeground;
=======
              // Ativo: coral; Inativo: onSurfaceVariant (#A1A1A1 dark / #7B8494 light)
              final color = isActive ? AppColors.coral : cs.onSurfaceVariant;
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
              return InkWell(
                onTap: () => onTabChange(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22, color: color),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
