import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/itinerary.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../providers/itinerary_provider.dart';
import '../theme/app_theme.dart';
import 'itinerary_detail_page.dart';
import 'itinerary_form_page.dart';

class ItinerariesPage extends ConsumerWidget {
  const ItinerariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(cityProvider);
    final itinerariesAsync = ref.watch(itineraryProvider);
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            children: [
              itinerariesAsync.when(
                data: (list) => _ItinerariesContent(
                  itineraries: list,
                  cityName: city.name,
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erro ao carregar roteiros\n$e',
                        textAlign: TextAlign.center),
                  ),
                ),
              ),
              if (user != null)
                Positioned(
                  bottom: 24,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: SizedBox(
                      width: 220,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ItineraryFormPage()),
                        ),
                        icon: Icon(LucideIcons.plus, size: 18),
                        label: Text('Novo Roteiro',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          shadowColor: AppColors.coral.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItinerariesContent extends ConsumerStatefulWidget {
  final List<Itinerary> itineraries;
  final String cityName;

  const _ItinerariesContent({
    required this.itineraries,
    required this.cityName,
  });

  @override
  ConsumerState<_ItinerariesContent> createState() =>
      _ItinerariesContentState();
}

class _ItinerariesContentState extends ConsumerState<_ItinerariesContent> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Itinerary> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return widget.itineraries;
    return widget.itineraries
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.cityName.toLowerCase().contains(q) ||
            i.districtName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLANEJE SUA AVENTURA',
                  style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text('Roteiros',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(
                'Monte itinerarios personalizados com os melhores locais do bairro.',
                style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.mapPin,
                        size: 14, color: AppColors.coral),
                    const SizedBox(width: 6),
                    Text(widget.cityName,
                        style: TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar roteiro...',
                  prefixIcon: Icon(LucideIcons.search,
                      size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x,
                              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(
                  hasSearch: _search.isNotEmpty,
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ItineraryCard(
                    itinerary: items[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ItineraryDetailPage(itinerary: items[i]))),
                    onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ItineraryFormPage(existing: items[i]))),
                    onDelete: () => _delete(context, items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, Itinerary item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir roteiro?'),
        content:
            Text('O roteiro "${item.name}" sera removido permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(itineraryProvider.notifier).remove(item.id);
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

class _ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItineraryCard({
    required this.itinerary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.coral, AppColors.coralDark]),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(itinerary.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(LucideIcons.ellipsisVertical,
                            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onSelected: (v) {
                          if (v == 'edit') onEdit();
                          if (v == 'delete') onDelete();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(LucideIcons.pencil,
                                  size: 16, color: Theme.of(context).colorScheme.onSurface),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(LucideIcons.trash2,
                                  size: 16, color: AppColors.destructive),
                              SizedBox(width: 10),
                              Text('Excluir',
                                  style: TextStyle(
                                      color: AppColors.destructive)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(LucideIcons.mapPin,
                        size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          '${itinerary.cityName}  x  ${itinerary.districtName}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  if (itinerary.date != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(LucideIcons.calendar,
                          size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(_fmt(itinerary.date!),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  if (itinerary.places.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...itinerary.places
                            .take(5)
                            .map((p) => _PlacePill(place: p)),
                        if (itinerary.places.length > 5)
                          _MorePill(count: itinerary.places.length - 5),
                      ],
                    )
                  else
                    Text('Nenhum local adicionado ainda',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${itinerary.placeCount} local${itinerary.placeCount != 1 ? "is" : ""}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text('Ver detalhes',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.arrowRight,
                        size: 14, color: AppColors.coral),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePill extends StatelessWidget {
  final Place place;
  const _PlacePill({required this.place});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(place.category.emoji, style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(place.name,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      );
}

class _MorePill extends StatelessWidget {
  final int count;
  const _MorePill({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.coralLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('+$count mais',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.coral,
                fontWeight: FontWeight.w600)),
      );
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onClear;

  const _EmptyState({required this.hasSearch, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.map,
                size: 52, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'Nenhum roteiro encontrado' : 'Sem roteiros ainda',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Tente outra pesquisa.'
                  : 'Crie seu primeiro roteiro personalizado\npara o bairro selecionado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onClear,
                child: Text('Limpar pesquisa'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
