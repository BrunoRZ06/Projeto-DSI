import 'package:cloud_firestore/cloud_firestore.dart';

/// Quest padrão de uma cidade armazenada no Firestore
class CityQuest {
  final String id;
  final String cityName;
  final String title;
  final String subtitle;
  final String details;
  final int xp;
  final String iconName;
  final String? locationHint; // Dica de localização (ex: "Big Ben")
  final double? latitude;
  final double? longitude;
  final String? photoUrl; // Foto da missão (armazenada no Supabase)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CityQuest({
    required this.id,
    required this.cityName,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.xp,
    required this.iconName,
    this.locationHint,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'city_name': cityName,
        'title': title,
        'subtitle': subtitle,
        'details': details,
        'xp': xp,
        'icon_name': iconName,
        'location_hint': locationHint,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
      };

  Map<String, dynamic> toMap() => toJson();

  factory CityQuest.fromJson(Map<String, dynamic> json) => CityQuest(
        id: json['id'] as String,
        cityName: json['city_name'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        details: json['details'] as String? ?? '',
        xp: json['xp'] as int? ?? 100,
        iconName: json['icon_name'] as String? ?? 'star',
        locationHint: json['location_hint'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photoUrl: json['photo_url'] as String?,
        createdAt: json['created_at'] is Timestamp
            ? (json['created_at'] as Timestamp).toDate()
            : json['created_at'] is String
                ? DateTime.tryParse(json['created_at'] as String)
                : null,
        updatedAt: json['updated_at'] is Timestamp
            ? (json['updated_at'] as Timestamp).toDate()
            : json['updated_at'] is String
                ? DateTime.tryParse(json['updated_at'] as String)
                : null,
      );

  factory CityQuest.fromMap(Map<String, dynamic> map) => CityQuest.fromJson(map);

  CityQuest copyWith({
    String? cityName,
    String? title,
    String? subtitle,
    String? details,
    int? xp,
    String? iconName,
    String? locationHint,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) {
    return CityQuest(
      id: id,
      cityName: cityName ?? this.cityName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      details: details ?? this.details,
      xp: xp ?? this.xp,
      iconName: iconName ?? this.iconName,
      locationHint: locationHint ?? this.locationHint,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
