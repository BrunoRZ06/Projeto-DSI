import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_review.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ReviewTile extends ConsumerWidget {
  final DistrictReview review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewTile({required this.review, this.onEdit, this.onDelete, super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Cor da bolinha da nota conforme a avaliação (1–5):
  /// ruim → vermelho, média → amarelo, boa → azul, excelente → verde.
  Color _ratingColor(double rating) {
    if (rating < 2.5) return AppColors.destructive;
    if (rating < 3.5) return AppColors.warning;
    if (rating < 4.5) return AppColors.primary;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentUserProvider);
    final isOwner = current != null && current.uid == review.userId;
    final ratingColor = _ratingColor(review.rating);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ratingColor,
            child: Text(
              review.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.userId == current?.uid ? 'Você' : review.userId.substring(0, 6),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(review.text),
                if (isOwner && (onEdit != null || onDelete != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: Icon(LucideIcons.edit2, size: 18),
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(LucideIcons.trash2, size: 18),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
