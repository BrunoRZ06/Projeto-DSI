import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> saveProfile(Map<String, dynamic> data) =>
      _db.collection('user_profiles').doc(_uid).set(data, SetOptions(merge: true));

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final doc = await _db.collection('user_profiles').doc(userId).get();
    return doc.data();
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) =>
      _db.collection('user_profiles').doc(userId).set(data, SetOptions(merge: true));

  Stream<DocumentSnapshot> watchProfile() =>
      _db.collection('user_profiles').doc(_uid).snapshots();

  Future<void> completeQuest(String questId) =>
      _db.collection('quest_progress').doc(_uid).set({
        'completed': FieldValue.arrayUnion([questId]),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Stream<List<String>> watchCompletedQuests() =>
      _db.collection('quest_progress').doc(_uid).snapshots().map(
            (doc) => List<String>.from(doc.data()?['completed'] ?? []),
          );

  Future<List<Map<String, dynamic>>> getCompletedQuests(String userId) async {
    final doc = await _db.collection('quest_progress').doc(userId).get();
    final completed = List<String>.from(doc.data()?['completed'] ?? []);
    return completed.map((id) => {'quest_id': id, 'xp_earned': 0}).toList();
  }

  // ── Roteiros ──────────────────────────────────────────────────────────────

  CollectionReference get _itineraries => _db.collection('itineraries');

  Future<List<Map<String, dynamic>>> getItineraries(String userId) async {
    final snapshot = await _itineraries
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<String> createItinerary(Map<String, dynamic> data) async {
    final docRef = await _itineraries.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateItinerary(String id, Map<String, dynamic> data) =>
      _itineraries.doc(id).update(data);

  Future<void> deleteItinerary(String id) => _itineraries.doc(id).delete();
}
