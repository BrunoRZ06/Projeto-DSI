import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/match_history.dart';

class MatchHistoryService {
  static const String _collectionName = 'match_history';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MatchHistoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _collection => _firestore.collection(_collectionName);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user.uid;
  }

  Future<List<MatchHistory>> getUserHistory() async {
    final snapshot = await _collection
        .where('user_id', isEqualTo: _currentUserId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      return MatchHistory.fromMap(data, doc.id);
    }).toList();
  }

  Future<MatchHistory> create(MatchHistory history) async {
    final item = history.copyWith(userId: _currentUserId);
    final doc = await _collection.add(item.toMap());
    return item.copyWith(id: doc.id);
  }

  Future<void> delete(String historyId) async {
    final doc = await _collection.doc(historyId).get();
    if (!doc.exists) throw Exception('Histórico não encontrado');

    final data = Map<String, dynamic>.from(doc.data() as Map);
    if (data['user_id'] != _currentUserId) {
      throw Exception('Usuário não tem permissão para excluir este histórico');
    }

    await _collection.doc(historyId).delete();
  }
}

final matchHistoryService = MatchHistoryService();
