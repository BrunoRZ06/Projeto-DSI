import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um planejamento de gastos de viagem.
///
/// Este modelo armazena todas as informações necessárias para
/// planejar e acompanhar os gastos de uma viagem por bairro.
class TravelPlan {
  /// Identificador único do planejamento.
  final String? id;

  /// ID do usuário proprietário do planejamento.
  final String userId;

  /// Nome da cidade do planejamento.
  final String city;

  /// Nome do bairro do planejamento.
  final String district;

  /// Número de dias da viagem.
  final int days;

  /// Número de pessoas na viagem.
  final int people;

  /// Número de refeições por dia.
  final int mealsPerDay;

  /// Quilômetros de táxi/transporte por dia.
  final double taxiKmPerDay;

  /// Orçamento para atividades/lazer.
  final double activitiesBudget;

  /// Total estimado do planejamento.
  final double estimatedTotal;

  /// Data de criação do planejamento.
  final DateTime createdAt;

  /// Data da última atualização do planejamento.
  final DateTime updatedAt;

  /// Construtor do TravelPlan.
  const TravelPlan({
    this.id,
    required this.userId,
    required this.city,
    required this.district,
    required this.days,
    required this.people,
    required this.mealsPerDay,
    required this.taxiKmPerDay,
    required this.activitiesBudget,
    required this.estimatedTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma cópia do TravelPlan com campos atualizados.
  TravelPlan copyWith({
    String? id,
    String? userId,
    String? city,
    String? district,
    int? days,
    int? people,
    int? mealsPerDay,
    double? taxiKmPerDay,
    double? activitiesBudget,
    double? estimatedTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TravelPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      district: district ?? this.district,
      days: days ?? this.days,
      people: people ?? this.people,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      taxiKmPerDay: taxiKmPerDay ?? this.taxiKmPerDay,
      activitiesBudget: activitiesBudget ?? this.activitiesBudget,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte um mapa do Firestore em um TravelPlan.
  factory TravelPlan.fromMap(Map<String, dynamic> data, String? documentId) {
    return TravelPlan(
      id: documentId,
      userId: data['user_id'] as String,
      city: data['city'] as String,
      district: data['district'] as String,
      days: (data['days'] as num).toInt(),
      people: (data['people'] as num).toInt(),
      mealsPerDay: (data['meals_per_day'] as num).toInt(),
      taxiKmPerDay: (data['taxi_km_per_day'] as num).toDouble(),
      activitiesBudget: (data['activities_budget'] as num).toDouble(),
      estimatedTotal: (data['estimated_total'] as num).toDouble(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Converte o TravelPlan em um mapa para o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'city': city,
      'district': district,
      'days': days,
      'people': people,
      'meals_per_day': mealsPerDay,
      'taxi_km_per_day': taxiKmPerDay,
      'activities_budget': activitiesBudget,
      'estimated_total': estimatedTotal,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Converte o TravelPlan em um mapa para o Firestore (sem ID).
  /// Útil para operações de update que não devem modificar o ID.
  Map<String, dynamic> toMapForUpdate() {
    return {
      'city': city,
      'district': district,
      'days': days,
      'people': people,
      'meals_per_day': mealsPerDay,
      'taxi_km_per_day': taxiKmPerDay,
      'activities_budget': activitiesBudget,
      'estimated_total': estimatedTotal,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'TravelPlan(id: $id, city: $city, district: $district, '
        'days: $days, people: $people, estimatedTotal: $estimatedTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TravelPlan &&
        other.id == id &&
        other.userId == userId &&
        other.city == city &&
        other.district == district;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, city, district);
  }
}