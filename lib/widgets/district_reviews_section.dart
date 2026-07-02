import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_review.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import 'review_dialog.dart';
import 'review_tile.dart';

/// Seção de avaliações que expande no próprio lugar (sem abrir nova tela).
///
/// Mostra a média/contagem com um botão "Avaliações" que expande para revelar
/// as avaliações existentes e o botão para criar/editar a sua avaliação, que
/// abre o popup [showReviewDialog] com estrelas e comentário.
class DistrictReviewsSection extends ConsumerStatefulWidget {
  final String districtKey;
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  const DistrictReviewsSection({
    required this.districtKey,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    super.key,
  });

  @override
  ConsumerState<DistrictReviewsSection> createState() =>
      _DistrictReviewsSectionState();
}

class _DistrictReviewsSectionState
    extends ConsumerState<DistrictReviewsSection> {
  bool _expanded = false;

  Future<void> _openDialog({DistrictReview? existing}) {
    return showReviewDialog(
      context,
      ref,
      districtKey: widget.districtKey,
      city: widget.city,
      district: widget.district,
      latitude: widget.latitude,
      longitude: widget.longitude,
      existing: existing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(reviewStatsProvider(widget.districtKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.star, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            stats.when(
              data: (s) {
                final avg = (s['average'] as double?) ?? 0.0;
                final count = (s['count'] as int?) ?? 0;
                return Text('${avg.toStringAsFixed(1)} · $count avaliações',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant));
              },
              loading: () => Text('Carregando avaliações...',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              error: (_, __) => Text('Sem avaliações',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.coral, padding: EdgeInsets.zero),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Avaliações',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Icon(
                    _expanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _buildExpanded(context),
        ),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final userReviewAsync = ref.watch(userReviewProvider(widget.districtKey));
    final reviewsAsync = ref.watch(reviewsProvider(widget.districtKey));

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAuth)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(
                  userReviewAsync.value == null
                      ? LucideIcons.star
                      : LucideIcons.edit2,
                  size: 16,
                ),
                label: Text(userReviewAsync.value == null
                    ? 'Avaliar'
                    : 'Editar minha avaliação'),
                onPressed: () => _openDialog(existing: userReviewAsync.value),
              ),
            ),
          const SizedBox(height: 12),
          reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Ainda não há avaliações.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                );
              }
              final currentUid = ref.watch(currentUserProvider)?.uid;
              return Column(
                children: [
                  for (var i = 0; i < reviews.length; i++) ...[
                    _buildReviewTile(context, reviews[i], currentUid),
                    if (i < reviews.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, __) => Text('Erro: $e',
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(
      BuildContext context, DistrictReview review, String? currentUid) {
    Future<void> confirmAndDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja excluir sua avaliação?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir')),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(reviewControllerProvider).deleteReview(review.id);
      }
    }

    final tile = ReviewTile(
      review: review,
      onEdit: () => _openDialog(existing: review),
      onDelete: confirmAndDelete,
    );

    final isOwn = currentUid != null && currentUid == review.userId;
    if (!isOwn) return tile;

    return Dismissible(
      key: ValueKey('review-${review.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await confirmAndDelete();
        return false;
      },
      child: tile,
    );
  }
}
