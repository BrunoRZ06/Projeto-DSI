import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/city_location.dart';
import '../models/match_history.dart';
import '../providers/city_provider.dart';
import '../providers/match_history_provider.dart';
import '../services/city_dataset_service.dart';
import '../theme/app_theme.dart';

enum _MatchHistorySortOption {
  newest,
  oldest,
  highestScore,
  lowestScore,
}

class MatchHistoryPage extends ConsumerStatefulWidget {
  const MatchHistoryPage({super.key});

  @override
  ConsumerState<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends ConsumerState<MatchHistoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _MatchHistorySortOption _sortOption = _MatchHistorySortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String _formatScore(double score) => '${score.toStringAsFixed(0)}%';

  List<MatchHistory> _applyFilters(List<MatchHistory> items) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = items.where((item) {
      if (query.isEmpty) return true;
      return item.city.toLowerCase().contains(query) ||
          item.bestDistrict.toLowerCase().contains(query);
    }).toList();

    switch (_sortOption) {
      case _MatchHistorySortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _MatchHistorySortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _MatchHistorySortOption.highestScore:
        filtered.sort((a, b) => b.score.compareTo(a.score));
      case _MatchHistorySortOption.lowestScore:
        filtered.sort((a, b) => a.score.compareTo(b.score));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Histórico de Matches'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: historyState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.coral,
                  strokeWidth: 2,
                ),
              ),
              error: (error, _) => _HistoryMessage(
                icon: LucideIcons.circleAlert,
                title: 'Erro ao carregar histórico',
                message: error.toString(),
                action: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(matchHistoryProvider.notifier).load(),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Tentar novamente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _HistoryMessage(
                    icon: LucideIcons.sparkles,
                    title: 'Nenhum match salvo',
                    message:
                        'Pesquise uma cidade no Match para salvar seus resultados recentes.',
                  );
                }

                final visibleItems = _applyFilters(items);

                return RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: () =>
                      ref.read(matchHistoryProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    itemCount: visibleItems.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _MatchHistoryFilters(
                              controller: _searchController,
                              sortOption: _sortOption,
                              onSearchChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onSortChanged: (value) {
                                if (value == null) return;
                                setState(() => _sortOption = value);
                              },
                            ),
                            if (visibleItems.isEmpty) ...[
                              const SizedBox(height: 32),
                              _FilteredHistoryEmptyState(
                                onClear: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            ],
                          ],
                        );
                      }

                      final item = visibleItems[index - 1];
                      return _MatchHistoryTile(
                        item: item,
                        createdAt: _formatDate(item.createdAt),
                        score: _formatScore(item.score),
                        onOpen: () {
                          ref.read(cityProvider.notifier).setCity(
                                CityLocation(
                                  name: item.city,
                                  lat: item.latitude,
                                  lng: item.longitude,
                                  district: item.bestDistrict,
                                ),
                              );
                          ref
                              .read(rankingPreferencesProvider.notifier)
                              .setPreferences(
                                RankingPreferences(
                                  budget: item.budgetPreference,
                                  tourismDistance: item.tourismPreference,
                                  safetyPriority: item.safetyPreference,
                                ),
                              );
                          ref.read(activeTabProvider.notifier).setTab(1);
                          Navigator.of(context).pop();
                        },
                        onDelete: item.id == null
                            ? null
                            : () async {
                                await ref
                                    .read(matchHistoryProvider.notifier)
                                    .remove(item.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Match removido'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchHistoryFilters extends StatelessWidget {
  final TextEditingController controller;
  final _MatchHistorySortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_MatchHistorySortOption?> onSortChanged;

  const _MatchHistoryFilters({
    required this.controller,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Buscar por cidade ou bairro',
            prefixIcon: Icon(LucideIcons.search, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<_MatchHistorySortOption>(
          initialValue: sortOption,
          onChanged: onSortChanged,
          decoration: const InputDecoration(
            labelText: 'Ordenar por',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: _MatchHistorySortOption.newest,
              child: Text('Mais recentes'),
            ),
            DropdownMenuItem(
              value: _MatchHistorySortOption.oldest,
              child: Text('Mais antigos'),
            ),
            DropdownMenuItem(
              value: _MatchHistorySortOption.highestScore,
              child: Text('Maior match'),
            ),
            DropdownMenuItem(
              value: _MatchHistorySortOption.lowestScore,
              child: Text('Menor match'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilteredHistoryEmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredHistoryEmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          LucideIcons.search,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'Nenhum match encontrado',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onClear,
          child: const Text('Limpar filtro'),
        ),
      ],
    );
  }
}

class _MatchHistoryTile extends StatelessWidget {
  final MatchHistory item;
  final String createdAt;
  final String score;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const _MatchHistoryTile({
    required this.item,
    required this.createdAt,
    required this.score,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 18,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.bestDistrict,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score de match • $createdAt',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'open') onOpen();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Abrir no mapa')),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Excluir histórico',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
