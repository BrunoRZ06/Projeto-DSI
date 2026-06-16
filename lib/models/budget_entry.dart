import 'package:cloud_firestore/cloud_firestore.dart';

/// Categoria de gasto — usada para agrupar e exibir ícones.
enum ExpenseCategory {
  accommodation, // Hospedagem
  food,          // Alimentação
  transport,     // Transporte
  attraction,    // Passeios / atrações
  shopping,      // Compras
  other,         // Outros
}

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.accommodation: return 'Hospedagem';
      case ExpenseCategory.food:          return 'Alimentação';
      case ExpenseCategory.transport:     return 'Transporte';
      case ExpenseCategory.attraction:    return 'Passeios';
      case ExpenseCategory.shopping:      return 'Compras';
      case ExpenseCategory.other:         return 'Outros';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.accommodation: return '🏨';
      case ExpenseCategory.food:          return '🍽️';
      case ExpenseCategory.transport:     return '🚌';
      case ExpenseCategory.attraction:    return '🎡';
      case ExpenseCategory.shopping:      return '🛍️';
      case ExpenseCategory.other:         return '💸';
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Um lançamento individual de gasto.
class BudgetEntry {
  final String id;
  final String cityBudgetId; // FK para CityBudget
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final bool isSuggestion; // true = sugerido pelo dataset (somente leitura)

  const BudgetEntry({
    required this.id,
    required this.cityBudgetId,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.isSuggestion = false,
  });

  Map<String, dynamic> toMap() => {
        'city_budget_id': cityBudgetId,
        'description': description,
        'amount': amount,
        'category': category.name,
        'date': Timestamp.fromDate(date),
        'is_suggestion': isSuggestion,
      };

  factory BudgetEntry.fromMap(String id, Map<String, dynamic> map) =>
      BudgetEntry(
        id: id,
        cityBudgetId: map['city_budget_id'] as String? ?? '',
        description: map['description'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        category: ExpenseCategoryX.fromString(map['category'] as String? ?? ''),
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isSuggestion: map['is_suggestion'] as bool? ?? false,
      );

  BudgetEntry copyWith({
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
  }) =>
      BudgetEntry(
        id: id,
        cityBudgetId: cityBudgetId,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        isSuggestion: isSuggestion,
      );
}
