import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictReview {
  final String id;
  final String districtKey;
  final String city;
  final String district;
  final String userId;
  final double rating;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;

  DistrictReview({
    required this.id,
    required this.districtKey,
    required this.city,
    required this.district,
    required this.userId,
    required this.rating,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
  });

  factory DistrictReview.fromMap(Map<String, dynamic> map) {
    return DistrictReview(
      id: map['id'] ?? '',
      districtKey: map['district_key'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      userId: map['user_id'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      text: map['text'] ?? '',
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  factory DistrictReview.fromDocument(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>? ?? {});
    data['id'] = doc.id;
    return DistrictReview.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'district_key': districtKey,
      'city': city,
      'district': district,
      'user_id': userId,
      'rating': rating,
      'text': text,
      'latitude': latitude,
      'longitude': longitude,
      // Note: timestamps are managed by the service (serverTimestamp)
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
