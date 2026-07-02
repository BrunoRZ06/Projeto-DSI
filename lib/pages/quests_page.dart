import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/user_quest.dart';
import '../models/city_quest.dart';
import '../providers/auth_provider.dart';
import '../providers/user_quest_provider.dart';
import '../providers/city_quest_provider.dart';
import '../providers/firestore_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'quest_form_page.dart';
import 'city_quest_form_page.dart';

enum _QuestSortOption {
  newest,
  oldest,
  xpHigh,
  xpLow,
}

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key});

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends ConsumerState<QuestsPage> {
  String? _expandedId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _QuestSortOption _sortOption = _QuestSortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Missões do usuário ─────────────────────────────────────────────────

  Future<void> _openCreateQuest() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _toast('Faça login para criar quests.', error: true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuestFormPage()),
    );
  }

  Future<void> _openEditQuest(UserQuest quest) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuestFormPage(existing: quest)),
    );
  }

  Future<void> _deleteQuest(UserQuest quest) async {
    final confirmed = await _confirmDelete(quest.title);
    if (confirmed != true) return;
    try {
      await ref.read(userQuestsProvider.notifier).remove(quest.id);
      if (quest.photoUrl != null && quest.photoUrl!.isNotEmpty) {
        await SupabaseService.deleteQuestPhoto(quest.photoUrl!);
      }
      if (_expandedId == 'user-${quest.id}') {
        setState(() => _expandedId = null);
      }
      _toast('Quest excluída.');
    } catch (_) {
      _toast('Não foi possível excluir a quest.', error: true);
    }
  }

  // ─── Missões da cidade ──────────────────────────────────────────────────

  Future<void> _openCreateCityQuest(String city) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _toast('Faça login para criar missões.', error: true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CityQuestFormPage(cityName: city)),
    );
  }

  Future<void> _openEditCityQuest(CityQuest quest) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CityQuestFormPage(existing: quest, cityName: quest.cityName),
      ),
    );
  }

  Future<void> _deleteCityQuest(CityQuest quest) async {
    final confirmed = await _confirmDelete(quest.title);
    if (confirmed != true) return;
    final ok =
        await ref.read(cityQuestsControllerProvider.notifier).remove(quest.id);
    if (ok) {
      if (quest.photoUrl != null && quest.photoUrl!.isNotEmpty) {
        await SupabaseService.deleteQuestPhoto(quest.photoUrl!);
      }
      if (_expandedId == 'city-${quest.id}') {
        setState(() => _expandedId = null);
      }
      _toast('Missão excluída.');
    } else {
      _toast('Não foi possível excluir a missão.', error: true);
    }
  }

  Future<void> _seedCity(String city) async {
    await ref.read(cityQuestsControllerProvider.notifier).seedExamples();
    _toast('Missões de exemplo adicionadas para $city!');
  }

  Future<bool?> _confirmDelete(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir?'),
        content: Text('"$title" será removida permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Envolve um item em um [Dismissible] para permitir apagar arrastando.
  /// A remoção real é feita por [onConfirmed]; como as listas são reativas,
  /// retornamos `false` para o próprio provider atualizar a lista.
  Widget _swipeToDelete({
    required Key key,
    required Future<void> Function() onConfirmed,
    required Widget child,
  }) {
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await onConfirmed();
        return false;
      },
      child: child,
    );
  }

  void _completeQuest(String id, int xp) {
    ref.read(completeQuestProvider(id));
    _toast('+$xp XP ganhos! 🎉');
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? AppColors.destructive
            : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<UserQuest> _applySearchAndSort(List<UserQuest> quests) {
    final normalized = _searchQuery.trim().toLowerCase();
    final filtered = quests.where((q) {
      if (normalized.isEmpty) return true;
      return q.title.toLowerCase().contains(normalized);
    }).toList();

    DateTime byDate(UserQuest q) =>
        q.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    switch (_sortOption) {
      case _QuestSortOption.newest:
        filtered.sort((a, b) => byDate(b).compareTo(byDate(a)));
      case _QuestSortOption.oldest:
        filtered.sort((a, b) => byDate(a).compareTo(byDate(b)));
      case _QuestSortOption.xpHigh:
        filtered.sort((a, b) => b.xp.compareTo(a.xp));
      case _QuestSortOption.xpLow:
        filtered.sort((a, b) => a.xp.compareTo(b.xp));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final completedAsync = ref.watch(completedQuestsProvider);

    return completedAsync.when(
      data: (completed) => _buildContent(completed),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erro ao carregar missões 😕\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<String> completed) {
    final currentUser = ref.watch(currentUserProvider);
    final currentCity = ref.watch(currentCityNameProvider);

    final userQuestsAsync = ref.watch(userQuestsProvider);
    final allUserQuests = userQuestsAsync.asData?.value ?? <UserQuest>[];
    // Missões do usuário desta cidade (legadas sem cidade aparecem sempre).
    final userQuests = allUserQuests
        .where((q) => q.cityName == null || q.cityName == currentCity)
        .toList();

    final cityQuestsAsync = ref.watch(cityQuestsControllerProvider);
    final cityQuests = cityQuestsAsync.asData?.value ?? <CityQuest>[];

    final totalXpCity = cityQuests
        .where((q) => completed.contains(q.id))
        .fold<int>(0, (sum, q) => sum + q.xp);
    final totalXpUser = userQuests
        .where((q) => completed.contains(q.id))
        .fold<int>(0, (sum, q) => sum + q.xp);

    final allQuestIds = {
      for (final q in cityQuests) q.id,
      for (final q in userQuests) q.id,
    };

    final totalXp = totalXpCity + totalXpUser;
    final doneCount = completed.where(allQuestIds.contains).length;
    final totalCount = cityQuests.length + userQuests.length;

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
                    Text('🏆 GAMIFIQUE SUA VIAGEM',
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
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 14, color: AppColors.coral),
                        const SizedBox(width: 4),
                        Text(
                          currentCity,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _XpSummary(
                        totalXp: totalXp, done: doneCount, total: totalCount),
                    const SizedBox(height: 28),

                    // ─── Missões da cidade ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Missões de $currentCity',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ),
                        if (currentUser != null)
                          TextButton.icon(
                            onPressed: () => _openCreateCityQuest(currentCity),
                            icon: Icon(LucideIcons.plus, size: 14),
                            label: Text('Nova'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.coral),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    cityQuestsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => const _EmptyInfo(
                          message:
                              'Não foi possível carregar as missões da cidade.'),
                      data: (quests) {
                        if (quests.isEmpty) {
                          return _CityEmptyState(
                            city: currentCity,
                            canEdit: currentUser != null,
                            onSeed: () => _seedCity(currentCity),
                            onCreate: () => _openCreateCityQuest(currentCity),
                          );
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < quests.length; i++) ...[
                              _swipeToDelete(
                                key: ValueKey('city-${quests[i].id}'),
                                onConfirmed: () => _deleteCityQuest(quests[i]),
                                child: _CityQuestCard(
                                  quest: quests[i],
                                  isDone: completed.contains(quests[i].id),
                                  isExpanded: _expandedId == 'city-${quests[i].id}',
                                  canEdit: currentUser != null,
                                  onToggle: () => setState(() => _expandedId =
                                      _expandedId == 'city-${quests[i].id}'
                                          ? null
                                          : 'city-${quests[i].id}'),
                                  onComplete: () =>
                                      _completeQuest(quests[i].id, quests[i].xp),
                                  onEdit: () => _openEditCityQuest(quests[i]),
                                  onDelete: () => _deleteCityQuest(quests[i]),
                                ),
                              ),
                              if (i < quests.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // ─── Missões do usuário ─────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Suas quests',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        if (currentUser != null)
                          TextButton.icon(
                            onPressed: _openCreateQuest,
                            icon: Icon(LucideIcons.plus, size: 14),
                            label: Text('Nova quest'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.coral),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentUser == null)
                      const _EmptyInfo(
                        message:
                            'Faça login para criar e gerenciar quests personalizadas.',
                      )
                    else
                      userQuestsAsync.when(
                        loading: () => Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (_) {
                          if (userQuests.isEmpty) {
                            return const _EmptyInfo(
                              message:
                                  'Você ainda não tem quests nesta cidade. Crie uma!',
                            );
                          }
                          final visibleQuests = _applySearchAndSort(userQuests);
                          return Column(
                            children: [
                              _UserQuestControls(
                                controller: _searchController,
                                sortOption: _sortOption,
                                onSearchChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                onSortChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _sortOption = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              if (visibleQuests.isEmpty)
                                const _EmptyInfo(
                                  message:
                                      'Nenhuma quest encontrada para este filtro.',
                                ),
                              for (var i = 0; i < visibleQuests.length; i++) ...[
                                _swipeToDelete(
                                  key: ValueKey('user-${visibleQuests[i].id}'),
                                  onConfirmed: () => _deleteQuest(visibleQuests[i]),
                                  child: _UserQuestCard(
                                    quest: visibleQuests[i],
                                    isDone: completed.contains(visibleQuests[i].id),
                                    isExpanded: _expandedId == 'user-${visibleQuests[i].id}',
                                    onToggle: () => setState(() => _expandedId =
                                        _expandedId == 'user-${visibleQuests[i].id}'
                                            ? null
                                            : 'user-${visibleQuests[i].id}'),
                                    onComplete: () =>
                                        _completeQuest(visibleQuests[i].id, visibleQuests[i].xp),
                                    onEdit: () => _openEditQuest(visibleQuests[i]),
                                    onDelete: () => _deleteQuest(visibleQuests[i]),
                                  ),
                                ),
                                if (i < visibleQuests.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  onPressed: _openCreateQuest,
                  child: Icon(LucideIcons.plus, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserQuestControls extends StatelessWidget {
  final TextEditingController controller;
  final _QuestSortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_QuestSortOption?> onSortChanged;

  const _UserQuestControls({
    required this.controller,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Buscar por título da quest',
              prefixIcon: Icon(LucideIcons.search, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_QuestSortOption>(
            initialValue: sortOption,
            onChanged: onSortChanged,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: _QuestSortOption.newest,
                child: Text('Data de criação (mais recente)'),
              ),
              DropdownMenuItem(
                value: _QuestSortOption.oldest,
                child: Text('Data de criação (mais antiga)'),
              ),
              DropdownMenuItem(
                value: _QuestSortOption.xpHigh,
                child: Text('XP (maior para menor)'),
              ),
              DropdownMenuItem(
                value: _QuestSortOption.xpLow,
                child: Text('XP (menor para maior)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpSummary extends StatelessWidget {
  final int totalXp;
  final int done;
  final int total;

  const _XpSummary(
      {required this.totalXp, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalXp XP',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text('$done/$total missões completas',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
            child: Center(
              child: Text('$done',
                  style: TextStyle(
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

/// Cartão de missão de cidade (com foto, CRUD e completar).
class _CityQuestCard extends StatelessWidget {
  final CityQuest quest;
  final bool isDone;
  final bool isExpanded;
  final bool canEdit;
  final VoidCallback onToggle;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CityQuestCard({
    required this.quest,
    required this.isDone,
    required this.isExpanded,
    required this.canEdit,
    required this.onToggle,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _icon => iconFromName(quest.iconName);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onEdit,
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
                            : AppColors.coralLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isDone ? LucideIcons.check : _icon,
                        size: 20,
                        color: isDone ? AppColors.success : AppColors.coralDark,
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
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (quest.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(quest.subtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _XpBadge(xp: quest.xp),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onToggle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      splashRadius: 16,
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
                    if (quest.photoUrl != null) ...[
                      _QuestPhoto(url: quest.photoUrl!),
                      const SizedBox(height: 12),
                    ],
                    if (quest.details.isNotEmpty)
                      Text(quest.details,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    if (quest.locationHint != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin,
                              size: 14, color: AppColors.coral),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(quest.locationHint!,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.coral)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (!isDone)
                      ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40)),
                        child: Text('Completar Missão'),
                      )
                    else
                      Row(
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
                    if (canEdit) ...[
                      const SizedBox(height: 10),
                      _EditDeleteRow(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserQuestCard extends StatelessWidget {
  final UserQuest quest;
  final bool isDone;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserQuestCard({
    required this.quest,
    required this.isDone,
    required this.isExpanded,
    required this.onToggle,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onEdit,
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
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
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
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (quest.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(quest.subtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _XpBadge(xp: quest.xp),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onToggle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      splashRadius: 16,
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
                    if (quest.photoUrl != null) ...[
                      _QuestPhoto(url: quest.photoUrl!),
                      const SizedBox(height: 12),
                    ],
                    if (quest.details.isNotEmpty) ...[
                      Text(quest.details,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      const SizedBox(height: 12),
                    ],
                    if (!isDone)
                      ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40)),
                        child: Text('Completar Missão'),
                      )
                    else
                      Row(
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
                    const SizedBox(height: 10),
                    _EditDeleteRow(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('+$xp XP',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.coralDark)),
    );
  }
}

class _EditDeleteRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EditDeleteRow({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: Icon(LucideIcons.pencil, size: 16),
            label: Text('Editar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(LucideIcons.trash2, size: 16),
            label: Text('Excluir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestPhoto extends StatelessWidget {
  final String url;
  const _QuestPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(LucideIcons.imageOff,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Estado vazio das missões de cidade: oferece semear exemplos ou criar.
class _CityEmptyState extends StatelessWidget {
  final String city;
  final bool canEdit;
  final VoidCallback onSeed;
  final VoidCallback onCreate;

  const _CityEmptyState({
    required this.city,
    required this.canEdit,
    required this.onSeed,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ainda não há missões para $city.',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (canEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSeed,
                    icon: Icon(LucideIcons.sparkles, size: 16),
                    label: Text('Sugerir exemplos'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: Icon(LucideIcons.plus, size: 16),
                    label: Text('Criar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyInfo extends StatelessWidget {
  final String message;
  const _EmptyInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
