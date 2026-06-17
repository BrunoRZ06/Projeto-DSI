import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/district_review.dart';
import '../services/review_service.dart';
import 'auth_provider.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

/// Stream com a lista de avaliações para um `districtKey`.
final reviewsProvider = StreamProvider.family<List<DistrictReview>, String>((ref, districtKey) {
  return ref.watch(reviewServiceProvider).watchReviews(districtKey);
});

/// Stream com estatísticas (média/contagem) para um `districtKey`.
final reviewStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, districtKey) {
  return ref.watch(reviewServiceProvider).watchStats(districtKey);
});

/// Busca a avaliação do usuário atual (se existir) para o distrito.
final userReviewProvider = FutureProvider.family<DistrictReview?, String>((ref, districtKey) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(reviewServiceProvider).fetchUserReview(districtKey, user.uid);
});

/// Controller com métodos de ação (create/update/delete).
final reviewControllerProvider = Provider((ref) => ReviewController(ref));

class ReviewController {
  final Ref ref;
  ReviewController(this.ref);

  Future<DistrictReview> createReview({
    required String districtKey,
    required String city,
    required String district,
    required double rating,
    required String text,
    double? latitude,
    double? longitude,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Usuário não autenticado');

    final review = DistrictReview(
      id: '',
      districtKey: districtKey,
      city: city,
      district: district,
      userId: user.uid,
      rating: rating,
      text: text,
      latitude: latitude,
      longitude: longitude,
    );

    return ref.read(reviewServiceProvider).createReview(review);
  }

  Future<void> updateReview(DistrictReview review) async {
    await ref.read(reviewServiceProvider).updateReview(review);
  }

  Future<void> deleteReview(String id) async {
    await ref.read(reviewServiceProvider).deleteReview(id);
  }
}
