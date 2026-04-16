import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/quest.dart';
import '../providers/quest_provider.dart';
import '../theme/app_theme.dart';

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key});

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends ConsumerState<QuestsPage> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(completedQuestsProvider);
    final totalXp = defaultQuests
        .where((q) => completed.contains(q.id))
        .fold<int>(0, (sum, q) => sum + q.xp);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 GAMIFIQUE SUA VIAGEM',
                        style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('Missões Locais',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.foreground)),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete missões para ganhar XP e desbloquear recompensas.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 24),
                    _XpSummary(
                      totalXp: totalXp,
                      done: completed.length,
                      total: defaultQuests.length,
                    ),
                    const SizedBox(height: 24),
                    for (var i = 0; i < defaultQuests.length; i++) ...[
                      _QuestCard(
                        quest: defaultQuests[i],
                        isDone: completed.contains(defaultQuests[i].id),
                        isExpanded: _expandedId == defaultQuests[i].id,
                        onToggle: () => setState(() =>
                            _expandedId = _expandedId == defaultQuests[i].id
                                ? null
                                : defaultQuests[i].id),
                        onComplete: () {
                          final q = defaultQuests[i];
                          ref.read(completedQuestsProvider.notifier).complete(q.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('+${q.xp} XP ganhos! 🎉'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                      ),
                      if (i < defaultQuests.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.camera,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpSummary extends StatelessWidget {
  final int totalXp;
  final int done;
  final int total;

  const _XpSummary({
    required this.totalXp,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalXp XP',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground)),
                Text('$done/$total missões completas',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$done',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final bool isDone;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onComplete;

  const _QuestCard({
    required this.quest,
    required this.isDone,
    required this.isExpanded,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isDone ? LucideIcons.check : quest.icon,
                        size: 20,
                        color: isDone ? AppColors.success : AppColors.coral,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone
                                  ? AppColors.mutedForeground
                                  : AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(quest.subtitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('+${quest.xp} XP',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coralDark)),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(quest.details,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.mutedForeground)),
                    const SizedBox(height: 12),
                    if (!isDone)
                      ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40)),
                        child: const Text('Completar Missão'),
                      )
                    else
                      const Row(
                        children: [
                          Icon(LucideIcons.check,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Missão completada!',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
