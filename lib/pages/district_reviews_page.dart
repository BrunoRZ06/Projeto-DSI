import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_review.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/review_tile.dart';

class DistrictReviewsPage extends ConsumerWidget {
  final String districtKey;
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  const DistrictReviewsPage({
    required this.districtKey,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    super.key,
  });

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, {DistrictReview? existing}) async {
    final isEditing = existing != null;
    final ratingController = ValueNotifier<double>(existing?.rating ?? 0.0);
    final textController = TextEditingController(text: existing?.text ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Avaliação' : 'Nova Avaliação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: ratingController,
                builder: (_, value, __) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final filled = value >= starValue;
                      return IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints: const BoxConstraints(),
                        splashRadius: 22,
                        tooltip: '$starValue',
                        onPressed: () => ratingController.value = starValue.toDouble(),
                        icon: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Conte como é o bairro...'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final rating = ratingController.value;
                final text = textController.text.trim();
                if (rating < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione ao menos 1 estrela.')),
                  );
                  return;
                }
                final controller = ref.read(reviewControllerProvider);
                try {
                  if (isEditing) {
                    final ex = existing;
                    final updated = DistrictReview(
                      id: ex.id,
                      districtKey: ex.districtKey,
                      city: ex.city,
                      district: ex.district,
                      userId: ex.userId,
                      rating: rating,
                      text: text,
                      latitude: ex.latitude,
                      longitude: ex.longitude,
                    );
                    await controller.updateReview(updated);
                  } else {
                    await controller.createReview(
                      districtKey: districtKey,
                      city: city,
                      district: district,
                      rating: rating,
                      text: text,
                      latitude: latitude,
                      longitude: longitude,
                    );
                  }
                  Navigator.of(ctx).pop();
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(districtKey));
    final statsAsync = ref.watch(reviewStatsProvider(districtKey));
    final userReviewAsync = ref.watch(userReviewProvider(districtKey));
    final isAuth = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(district)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) {
                final avg = (stats['average'] as double?) ?? 0.0;
                final count = (stats['count'] as int?) ?? 0;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                    Row(children: [
                      Icon(LucideIcons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('${avg.toStringAsFixed(1)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('· $count avaliações', style: TextStyle(color: Colors.grey)),
                    ]),
                    if (isAuth)
                      ElevatedButton(
                        onPressed: () async {
                          final existing = userReviewAsync.value;
                          await _showEditDialog(context, ref, existing: existing);
                        },
                        child: Text(userReviewAsync.value == null ? 'Avaliar' : 'Editar minha avaliação'),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) return Center(child: Text('Ainda não há avaliações.')); 
                  return ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final review = reviews[i];
                      final isOwn = userReviewAsync.value?.id == review.id;
                      Future<void> confirmAndDelete() async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Confirmar exclusão'),
                            content: Text('Deseja excluir sua avaliação?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar')),
                              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Excluir')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(reviewControllerProvider).deleteReview(review.id);
                        }
                      }

                      final tile = ReviewTile(
                        review: review,
                        onEdit: () async {
                          await _showEditDialog(context, ref, existing: review);
                        },
                        onDelete: confirmAndDelete,
                      );

                      // Só permite arrastar para apagar a própria avaliação.
                      if (!isOwn) return tile;

                      return Dismissible(
                        key: ValueKey('review-${review.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.trash2, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await confirmAndDelete();
                          return false;
                        },
                        child: tile,
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erro: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAuth
          ? FloatingActionButton(
              onPressed: () async {
                final existing = userReviewAsync.value;
                await _showEditDialog(context, ref, existing: existing);
              },
              child: Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}
