import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_entry.dart';
import '../models/city_budget.dart';
import '../services/budget_service.dart';

// ── Instância do serviço ───────────────────────────────────────────────────

final budgetServiceProvider = Provider<BudgetService>((_) => BudgetService());

// ── Lista de orçamentos do usuário ────────────────────────────────────────

final budgetsProvider = StreamProvider<List<CityBudget>>((ref) {
  return ref.watch(budgetServiceProvider).watchBudgets();
});

// ── Entradas de um orçamento específico ──────────────────────────────────

final entriesProvider =
    StreamProvider.family<List<BudgetEntry>, String>((ref, budgetId) {
  return ref.watch(budgetServiceProvider).watchEntries(budgetId);
});

// ── Orçamento atualmente selecionado (para a tela de detalhe) ────────────

class SelectedBudgetNotifier extends Notifier<CityBudget?> {
  @override
  CityBudget? build() => null;

  void select(CityBudget? budget) => state = budget;
}

final selectedBudgetProvider =
    NotifierProvider<SelectedBudgetNotifier, CityBudget?>(
  SelectedBudgetNotifier.new,
);

// ── Total gasto num orçamento (calculado localmente) ─────────────────────

final totalSpentProvider = Provider.family<double, String>((ref, budgetId) {
  final entries = ref.watch(entriesProvider(budgetId));
  return entries.when(
    data: (list) => list
        .where((e) => !e.isSuggestion)
        .fold(0.0, (sum, e) => sum + e.amount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// ── Gasto por categoria ───────────────────────────────────────────────────

final spentByCategoryProvider =
    Provider.family<Map<ExpenseCategory, double>, String>((ref, budgetId) {
  final entries = ref.watch(entriesProvider(budgetId));
  return entries.when(
    data: (list) {
      final result = <ExpenseCategory, double>{};
      for (final e in list.where((e) => !e.isSuggestion)) {
        result[e.category] = (result[e.category] ?? 0) + e.amount;
      }
      return result;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
