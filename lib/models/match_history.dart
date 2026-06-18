import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/city_dataset_service.dart';

class MatchHistory {
  final String? id;
  final String userId;
  final String city;
  final String bestDistrict;
  final double latitude;
  final double longitude;
  final double score;
  final double budgetPreference;
  final double tourismPreference;
  final double safetyPreference;
  final DateTime createdAt;

  const MatchHistory({
    this.id,
    required this.userId,
    required this.city,
    required this.bestDistrict,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.budgetPreference,
    required this.tourismPreference,
    required this.safetyPreference,
    required this.createdAt,
  });

  MatchHistory copyWith({
    String? id,
    String? userId,
    String? city,
    String? bestDistrict,
    double? latitude,
    double? longitude,
    double? score,
    double? budgetPreference,
    double? tourismPreference,
    double? safetyPreference,
    DateTime? createdAt,
  }) {
    return MatchHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      bestDistrict: bestDistrict ?? this.bestDistrict,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      score: score ?? this.score,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      tourismPreference: tourismPreference ?? this.tourismPreference,
      safetyPreference: safetyPreference ?? this.safetyPreference,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MatchHistory.create({
    required String userId,
    required String city,
    required String bestDistrict,
    required double latitude,
    required double longitude,
    required double score,
    required RankingPreferences preferences,
  }) {
    return MatchHistory(
      userId: userId,
      city: city,
      bestDistrict: bestDistrict,
      latitude: latitude,
      longitude: longitude,
      score: score,
      budgetPreference: preferences.budget,
      tourismPreference: preferences.tourismDistance,
      safetyPreference: preferences.safetyPriority,
      createdAt: DateTime.now(),
    );
  }

  factory MatchHistory.fromMap(Map<String, dynamic> data, String documentId) {
    return MatchHistory(
      id: documentId,
      userId: data['user_id'] as String? ?? '',
      city: data['city'] as String? ?? '',
      bestDistrict: data['best_district'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      budgetPreference:
          (data['budget_preference'] as num?)?.toDouble() ?? 50,
      tourismPreference:
          (data['tourism_preference'] as num?)?.toDouble() ?? 50,
      safetyPreference:
          (data['safety_preference'] as num?)?.toDouble() ?? 50,
      createdAt: _dateFrom(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'city': city,
      'best_district': bestDistrict,
      'latitude': latitude,
      'longitude': longitude,
      'score': score,
      'budget_preference': budgetPreference,
      'tourism_preference': tourismPreference,
      'safety_preference': safetyPreference,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
