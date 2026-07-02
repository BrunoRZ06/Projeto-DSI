import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/district_review.dart';
import '../providers/review_provider.dart';

/// Popup "Nova Avaliação" com estrelas clicáveis (1–5) e comentário.
///
/// Reutilizado tanto na seção inline de avaliações quanto em telas dedicadas,
/// garantindo uma única fonte de verdade para o formulário de avaliação.
Future<void> showReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required String districtKey,
  required String city,
  required String district,
  required double latitude,
  required double longitude,
  DistrictReview? existing,
}) async {
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
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
                  final updated = DistrictReview(
                    id: existing.id,
                    districtKey: existing.districtKey,
                    city: existing.city,
                    district: existing.district,
                    userId: existing.userId,
                    rating: rating,
                    text: text,
                    latitude: existing.latitude,
                    longitude: existing.longitude,
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
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}
