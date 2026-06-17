import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/district_review.dart';

class ReviewService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('district_reviews');

  Stream<List<DistrictReview>> watchReviews(String districtKey) {
    return _collection
        .where('district_key', isEqualTo: districtKey)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DistrictReview.fromDocument(d))
            .toList(growable: false));
  }

  Future<List<DistrictReview>> fetchReviews(String districtKey) async {
    final snap = await _collection
        .where('district_key', isEqualTo: districtKey)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => DistrictReview.fromDocument(d)).toList();
  }

  Stream<Map<String, dynamic>> watchStats(String districtKey) {
    return _collection.where('district_key', isEqualTo: districtKey).snapshots().map((snap) {
      final count = snap.size;
      double average = 0.0;
      if (count > 0) {
        final total = snap.docs
            .map((d) => (d.data() as Map<String, dynamic>)['rating'] as num)
            .map((n) => n.toDouble())
            .reduce((a, b) => a + b);
        average = total / count;
      }
      return {'average': average, 'count': count};
    });
  }

  Future<Map<String, dynamic>> fetchStats(String districtKey) async {
    final snap = await _collection.where('district_key', isEqualTo: districtKey).get();
    final count = snap.size;
    double average = 0.0;
    if (count > 0) {
      final total = snap.docs
          .map((d) => (d.data() as Map<String, dynamic>)['rating'] as num)
          .map((n) => n.toDouble())
          .reduce((a, b) => a + b);
      average = total / count;
    }
    return {'average': average, 'count': count};
  }

  Future<DistrictReview?> fetchUserReview(String districtKey, String userId) async {
    final snap = await _collection
        .where('district_key', isEqualTo: districtKey)
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DistrictReview.fromDocument(snap.docs.first);
  }

  Future<DistrictReview> createReview(DistrictReview review) async {
    final payload = {
      ...review.toMap(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    final docRef = await _collection.add(payload);
    final doc = await docRef.get();
    return DistrictReview.fromDocument(doc);
  }

  Future<void> updateReview(DistrictReview review) async {
    final payload = {
      'rating': review.rating,
      'text': review.text,
      'latitude': review.latitude,
      'longitude': review.longitude,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _collection.doc(review.id).update(payload);
  }

  Future<void> deleteReview(String id) async {
    await _collection.doc(id).delete();
  }
}

final reviewService = ReviewService();
