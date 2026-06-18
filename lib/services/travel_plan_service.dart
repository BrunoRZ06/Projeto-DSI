import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/travel_plan.dart';

/// Serviço responsável pelo CRUD de planejamentos de viagem.
///
/// Utiliza Firebase Auth para identificar o usuário logado e
/// Firestore para persistência dos dados na coleção 'travel_plans'.
class TravelPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Nome da coleção no Firestore.
  static const String _collectionName = 'travel_plans';

  /// Obtém o ID do usuário autenticado atualmente.
  ///
  /// Lança uma exceção se não houver usuário autenticado.
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user.uid;
  }

  /// Obtém a referência da coleção de planejamentos.
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Cria um novo planejamento de viagem.
  ///
  /// O [userId] é preenchido automaticamente com o usuário logado.
  /// [createdAt] e [updatedAt] são definidos como a data/hora atual.
  ///
  /// Retorna o ID do documento criado.
  Future<String> createPlan({
    required String city,
    required String district,
    required int days,
    required int people,
    required int mealsPerDay,
    required double taxiKmPerDay,
    required double activitiesBudget,
    required double estimatedTotal,
  }) async {
    final userId = _currentUserId;
    final now = DateTime.now();

    final plan = TravelPlan(
      userId: userId,
      city: city,
      district: district,
      days: days,
      people: people,
      mealsPerDay: mealsPerDay,
      taxiKmPerDay: taxiKmPerDay,
      activitiesBudget: activitiesBudget,
      estimatedTotal: estimatedTotal,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _collection.add(plan.toMap());
    return docRef.id;
  }

  /// Obtém todos os planejamentos do usuário logado.
  ///
  /// Retorna uma lista de [TravelPlan] ordenada por data de criação
  /// (mais recentes primeiro).
  Future<List<TravelPlan>> getUserPlans() async {
    final userId = _currentUserId;

    final snapshot = await _collection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TravelPlan.fromMap(data, doc.id);
    }).toList();
  }

  /// Obtém um planejamento específico pelo ID.
  ///
  /// Retorna null se o planejamento não existir.
  Future<TravelPlan?> getPlanById(String planId) async {
    final doc = await _collection.doc(planId).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data() as Map<String, dynamic>;
    return TravelPlan.fromMap(data, doc.id);
  }

  /// Atualiza um planejamento existente.
  ///
  /// Apenas o proprietário do planejamento pode atualizá-lo.
  /// O [updatedAt] é atualizado automaticamente para a data/hora atual.
  Future<void> updatePlan({
    required String planId,
    required String city,
    required String district,
    required int days,
    required int people,
    required int mealsPerDay,
    required double taxiKmPerDay,
    required double activitiesBudget,
    required double estimatedTotal,
  }) async {
    final userId = _currentUserId;

    // Verifica se o documento existe e pertence ao usuário
    final doc = await _collection.doc(planId).get();
    if (!doc.exists) {
      throw Exception('Planejamento não encontrado');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['user_id'] != userId) {
      throw Exception('Usuário não tem permissão para atualizar este planejamento');
    }

    final plan = TravelPlan(
      id: planId,
      userId: userId,
      city: city,
      district: district,
      days: days,
      people: people,
      mealsPerDay: mealsPerDay,
      taxiKmPerDay: taxiKmPerDay,
      activitiesBudget: activitiesBudget,
      estimatedTotal: estimatedTotal,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: DateTime.now(),
    );

    await _collection.doc(planId).update(plan.toMapForUpdate());
  }

  /// Exclui um planejamento existente.
  ///
  /// Apenas o proprietário do planejamento pode excluí-lo.
  Future<void> deletePlan(String planId) async {
    final userId = _currentUserId;

    // Verifica se o documento existe e pertence ao usuário
    final doc = await _collection.doc(planId).get();
    if (!doc.exists) {
      throw Exception('Planejamento não encontrado');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['user_id'] != userId) {
      throw Exception('Usuário não tem permissão para excluir este planejamento');
    }

    await _collection.doc(planId).delete();
  }

  /// Stream que emite atualizações quando os planejamentos do usuário mudam.
  Stream<List<TravelPlan>> watchUserPlans() {
    final userId = _currentUserId;

    return _collection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TravelPlan.fromMap(data, doc.id);
      }).toList();
    });
  }
}