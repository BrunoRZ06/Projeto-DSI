import 'package:cloud_firestore/cloud_firestore.dart';

/// Orçamento criado por viagem (cidade + bairro).
/// Cada usuário pode ter vários CityBudget (uma por viagem).
class CityBudget {
  final String id;
  final String userId;
  final String cityName;
  final String districtName;
  final double totalBudget;       // valor que o usuário quer gastar
  final int durationDays;         // duração da viagem em dias
  final double avgAccommodation;  // média de hospedagem vinda do dataset (por noite)
  final double avgRestaurant;     // média de restaurante vinda do dataset (por refeição)
  final DateTime createdAt;

  const CityBudget({
    required this.id,
    required this.userId,
    required this.cityName,
    required this.districtName,
    required this.totalBudget,
    required this.durationDays,
    required this.avgAccommodation,
    required this.avgRestaurant,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'city_name': cityName,
        'district_name': districtName,
        'total_budget': totalBudget,
        'duration_days': durationDays,
        'avg_accommodation': avgAccommodation,
        'avg_restaurant': avgRestaurant,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory CityBudget.fromMap(String id, Map<String, dynamic> map) => CityBudget(
        id: id,
        userId: map['user_id'] as String? ?? '',
        cityName: map['city_name'] as String? ?? '',
        districtName: map['district_name'] as String? ?? '',
        totalBudget: (map['total_budget'] as num?)?.toDouble() ?? 0.0,
        durationDays: (map['duration_days'] as num?)?.toInt() ?? 1,
        avgAccommodation: (map['avg_accommodation'] as num?)?.toDouble() ?? 0.0,
        avgRestaurant: (map['avg_restaurant'] as num?)?.toDouble() ?? 0.0,
        createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
