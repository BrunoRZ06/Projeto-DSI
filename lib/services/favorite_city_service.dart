import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorite_city.dart';

/// CRUD das cidades favoritas do usuário no Firestore (coleção `favorite_cities`).
/// Cada doc tem id determinístico `${uid}_${cityNorm}` para evitar duplicatas.
class FavoriteCityService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('favorite_cities');

  String _docId(String userId, String cityName) =>
      '${userId}_${cityName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';

  Stream<List<FavoriteCity>> watchForUser(String userId) {
    return _collection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        return FavoriteCity.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> add(String userId, String cityName) {
    return _collection.doc(_docId(userId, cityName)).set({
      'user_id': userId,
      'city_name': cityName,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String userId, String cityName) {
    return _collection.doc(_docId(userId, cityName)).delete();
  }

  Future<void> toggle(String userId, String cityName, bool isFavorite) {
    return isFavorite ? remove(userId, cityName) : add(userId, cityName);
  }
}

final favoriteCityService = FavoriteCityService();
