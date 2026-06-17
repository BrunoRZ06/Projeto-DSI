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
    final ratingController = ValueNotifier<double>(existing?.rating ?? 5.0);
    final textController = TextEditingController(text: existing?.text ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Avaliação' : 'Nova Avaliação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: ratingController,
                      builder: (_, value, __) {
                        return Slider(
                          min: 1.0,
                          max: 5.0,
                          divisions: 4,
                          value: value,
                          label: value.toStringAsFixed(1),
                          onChanged: (v) => ratingController.value = v,
                        );
                      },
                    ),
                  ),
                ],
              ),
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
                      return ReviewTile(
                        review: review,
                        onEdit: () async {
                          await _showEditDialog(context, ref, existing: review);
                        },
                        onDelete: () async {
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
                        },
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
