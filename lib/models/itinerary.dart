import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Categoria de ponto de interesse ────────────────────────────────────────

enum PlaceCategory {
  restaurant,
  tourist,
  park,
  museum,
  bar,
  shopping,
  beach,
  church,
}

extension PlaceCategoryX on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.restaurant:
        return 'Restaurante';
      case PlaceCategory.tourist:
        return 'Turismo';
      case PlaceCategory.park:
        return 'Parque';
      case PlaceCategory.museum:
        return 'Museu';
      case PlaceCategory.bar:
        return 'Bar';
      case PlaceCategory.shopping:
        return 'Compras';
      case PlaceCategory.beach:
        return 'Praia';
      case PlaceCategory.church:
        return 'Igreja';
    }
  }

  String get emoji {
    switch (this) {
      case PlaceCategory.restaurant:
        return '🍽️';
      case PlaceCategory.tourist:
        return '📸';
      case PlaceCategory.park:
        return '🌳';
      case PlaceCategory.museum:
        return '🏛️';
      case PlaceCategory.bar:
        return '🍺';
      case PlaceCategory.shopping:
        return '🛍️';
      case PlaceCategory.beach:
        return '🏖️';
      case PlaceCategory.church:
        return '⛪';
    }
  }
}

// ─── Ponto de interesse ──────────────────────────────────────────────────────

class Place {
  final String id;
  final String name;
  final String description;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String? address;
  final double? rating;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.rating,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'rating': rating,
      };

  factory Place.fromMap(Map<String, dynamic> map) => Place(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        category: PlaceCategory.values.firstWhere(
          (c) => c.name == (map['category'] as String? ?? ''),
          orElse: () => PlaceCategory.tourist,
        ),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        address: map['address'] as String?,
        rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      );
}

// ─── Roteiro ─────────────────────────────────────────────────────────────────

class Itinerary {
  final String id;
  final String userId;
  final String name;
  final String cityName;
  final String districtName;
  final DateTime? date;
  final List<Place> places;
  final String? notes;
  final DateTime? createdAt;

  const Itinerary({
    required this.id,
    required this.userId,
    required this.name,
    required this.cityName,
    required this.districtName,
    this.date,
    this.places = const [],
    this.notes,
    this.createdAt,
  });

  int get placeCount => places.length;

  Itinerary copyWith({
    String? name,
    String? cityName,
    String? districtName,
    DateTime? date,
    bool clearDate = false,
    List<Place>? places,
    String? notes,
    bool clearNotes = false,
  }) =>
      Itinerary(
        id: id,
        userId: userId,
        name: name ?? this.name,
        cityName: cityName ?? this.cityName,
        districtName: districtName ?? this.districtName,
        date: clearDate ? null : (date ?? this.date),
        places: places ?? this.places,
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'city_name': cityName,
        'district_name': districtName,
        'date': date != null ? Timestamp.fromDate(date!) : null,
        'places': places.map((p) => p.toMap()).toList(),
        'notes': notes,
      };

  factory Itinerary.fromMap(Map<String, dynamic> map) => Itinerary(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        cityName: map['city_name'] as String? ?? '',
        districtName: map['district_name'] as String? ?? '',
        date: map['date'] is Timestamp
            ? (map['date'] as Timestamp).toDate()
            : map['date'] is String
                ? DateTime.tryParse(map['date'] as String)
                : null,
        places: (map['places'] as List<dynamic>? ?? [])
            .map((p) => Place.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        notes: map['notes'] as String?,
        createdAt: map['created_at'] is Timestamp
            ? (map['created_at'] as Timestamp).toDate()
            : null,
      );
}
