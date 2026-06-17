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
    (LucideIcons.map, 'Explorar'),
    (LucideIcons.route, 'Roteiros'),
    (LucideIcons.trophy, 'Missões'),
    (LucideIcons.user, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Fundo e borda acompanham o tema: surface no dark (#1E1E1E), branco no light
    final bgColor = cs.surface;
    final borderColor = cs.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
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
              // Ativo: coral; Inativo: onSurfaceVariant (#A1A1A1 dark / #7B8494 light)
              final color = isActive ? AppColors.coral : cs.onSurfaceVariant;
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
