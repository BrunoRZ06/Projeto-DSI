import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/itinerary.dart';
import '../providers/itinerary_provider.dart';
import '../theme/app_theme.dart';
import 'itinerary_form_page.dart';

/// Tela de detalhes de um roteiro — mostra o itinerário completo e permite
/// editar ou excluir o roteiro.
class ItineraryDetailPage extends ConsumerWidget {
  final Itinerary itinerary;

  const ItineraryDetailPage({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa a lista para mostrar dados atualizados após edição.
    final listAsync = ref.watch(itineraryProvider);
    final current = listAsync.asData?.value
            .where((i) => i.id == itinerary.id)
            .firstOrNull ??
        itinerary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          current.name,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.pencil, color: AppColors.coral),
            tooltip: 'Editar',
            onPressed: () => _openEdit(context, current),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: AppColors.destructive),
            tooltip: 'Excluir',
            onPressed: () => _confirmDelete(context, ref, current),
          ),
        ],
      ),
      body: current.places.isEmpty
          ? _EmptyPlaces(onAdd: () => _openEdit(context, current))
          : _ItineraryBody(itinerary: current),
    );
  }

  Future<void> _openEdit(BuildContext context, Itinerary current) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ItineraryFormPage(existing: current)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Itinerary current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir roteiro?'),
        content:
            Text('O roteiro "${current.name}" será removido permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(itineraryProvider.notifier).remove(current.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao excluir roteiro'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ─── Corpo principal com a lista de lugares ───────────────────────────────────

class _ItineraryBody extends StatelessWidget {
  final Itinerary itinerary;

  const _ItineraryBody({required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        // ── Header do roteiro ──────────────────────────────────────────────
        _HeaderInfo(itinerary: itinerary),
        const SizedBox(height: 24),

        // ── Linha separadora ───────────────────────────────────────────────
        Row(children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${itinerary.placeCount} local${itinerary.placeCount != 1 ? 'is' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
        ]),
        const SizedBox(height: 16),

        // ── Lista de locais ────────────────────────────────────────────────
        ...itinerary.places.asMap().entries.map((entry) {
          final idx = entry.key;
          final place = entry.value;
          return _PlaceTimelineTile(
            place: place,
            index: idx + 1,
            isLast: idx == itinerary.places.length - 1,
          );
        }),

        // ── Notas ──────────────────────────────────────────────────────────
        if (itinerary.notes != null && itinerary.notes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.notebookPen,
                    size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    itinerary.notes!,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Header com metadados do roteiro ─────────────────────────────────────────

class _HeaderInfo extends StatelessWidget {
  final Itinerary itinerary;

  const _HeaderInfo({required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(children: [
          Icon(LucideIcons.mapPin, size: 14, color: AppColors.coral),
          const SizedBox(width: 6),
          Text(
            '${itinerary.cityName}  ·  ${itinerary.districtName}',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ]),
        if (itinerary.date != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(LucideIcons.calendar,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              _formatDate(itinerary.date!),
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          _StatChip(
              icon: LucideIcons.mapPin,
              label: '${itinerary.placeCount} locais'),
          const SizedBox(width: 8),
          ..._countByCategories(itinerary.places).entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StatChip(
                      label: '${e.value} ${e.key.label.toLowerCase()}'),
                ),
              ),
        ]),
      ],
    );
  }

  Map<PlaceCategory, int> _countByCategories(List<Place> places) {
    final map = <PlaceCategory, int>{};
    for (final p in places) {
      map[p.category] = (map[p.category] ?? 0) + 1;
    }
    return map;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _StatChip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

// ─── Tile de lugar com linha de timeline ─────────────────────────────────────

class _PlaceTimelineTile extends StatelessWidget {
  final Place place;
  final int index;
  final bool isLast;

  const _PlaceTimelineTile({
    required this.place,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da timeline
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Conteúdo do card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(place.category.emoji,
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        if (place.rating != null) ...[
                          Icon(LucideIcons.star,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.description,
                        style: TextStyle(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (place.address != null) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(LucideIcons.navigation,
                            size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address!,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyPlaces extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPlaces({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mapPinOff,
                  size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Nenhum local adicionado',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Edite o roteiro para adicionar pontos de interesse.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: Icon(LucideIcons.plus, size: 16),
                label: Text('Adicionar Locais'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
}
