import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteCity {
  final String cityName;
  final DateTime createdAt;

  FavoriteCity({required this.cityName, required this.createdAt});

  factory FavoriteCity.fromMap(Map<String, dynamic> map) => FavoriteCity(
        cityName: map['city_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  factory FavoriteCity.fromJson(Map<String, dynamic> json) => FavoriteCity(
        cityName: json['city_name'] as String,
        createdAt: json['created_at'] is Timestamp
            ? (json['created_at'] as Timestamp).toDate()
            : json['created_at'] is String
                ? DateTime.parse(json['created_at'] as String)
                : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'city_name': cityName,
        'created_at': Timestamp.fromDate(createdAt),
      };

  Map<String, dynamic> toMap() => toJson();
}
