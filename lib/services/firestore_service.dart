import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  // Salva ou atualiza perfil do usuário
  Future<void> saveProfile(Map<String, dynamic> data) =>
      _db.collection('user_profiles').doc(_uid).set(
            data,
            SetOptions(merge: true),
          );

  // Escuta o perfil em tempo real
  Stream<DocumentSnapshot> watchProfile() =>
      _db.collection('user_profiles').doc(_uid).snapshots();

  // Marca quest como concluída
  Future<void> completeQuest(String questId) =>
      _db.collection('quest_progress').doc(_uid).set({
        'completed': FieldValue.arrayUnion([questId]),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // Escuta quests concluídas em tempo real
  Stream<List<String>> watchCompletedQuests() =>
      _db.collection('quest_progress').doc(_uid).snapshots().map(
            (doc) => List<String>.from(doc.data()?['completed'] ?? []),
          );

  // Adiciona review de cidade
  Future<void> addReview({
    required String citySlug,
    required double rating,
    required String text,
  }) =>
      _db.collection('city_reviews').add({
        'city_slug': citySlug,
        'uid': _uid,
        'rating': rating,
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
      });

  // Escuta reviews de uma cidade
  Stream<QuerySnapshot> watchCityReviews(String citySlug) =>
      _db
          .collection('city_reviews')
          .where('city_slug', isEqualTo: citySlug)
          .orderBy('created_at', descending: true)
          .snapshots();
}
