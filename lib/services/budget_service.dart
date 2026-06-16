import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_entry.dart';
import '../models/city_budget.dart';

/// Serviço de CRUD para controle de gastos de viagem.
/// Colection layout no Firestore:
///   city_budgets/{budgetId}          → CityBudget
///   budget_entries/{entryId}         → BudgetEntry (filtrado por city_budget_id)
class BudgetService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── CityBudget ─────────────────────────────────────────────────────────────

  Stream<List<CityBudget>> watchBudgets() {
    return _db
        .collection('city_budgets')
        .where('user_id', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CityBudget.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> createBudget(CityBudget budget) async {
    final ref = await _db.collection('city_budgets').add(budget.toMap());
    return ref.id;
  }

  Future<void> updateBudget(String id, {double? totalBudget, int? durationDays}) {
    final data = <String, dynamic>{};
    if (totalBudget != null) data['total_budget'] = totalBudget;
    if (durationDays != null) data['duration_days'] = durationDays;
    return _db.collection('city_budgets').doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    // Remove entradas filhas primeiro
    final entries = await _db
        .collection('budget_entries')
        .where('city_budget_id', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in entries.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('city_budgets').doc(id));
    await batch.commit();
  }

  // ── BudgetEntry ────────────────────────────────────────────────────────────

  Stream<List<BudgetEntry>> watchEntries(String budgetId) {
    return _db
        .collection('budget_entries')
        .where('city_budget_id', isEqualTo: budgetId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BudgetEntry.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addEntry(BudgetEntry entry) =>
      _db.collection('budget_entries').add(entry.toMap());

  Future<void> updateEntry(String id, BudgetEntry entry) =>
      _db.collection('budget_entries').doc(id).update(entry.toMap());

  Future<void> deleteEntry(String id) =>
      _db.collection('budget_entries').doc(id).delete();
}
