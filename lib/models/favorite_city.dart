class FavoriteCity {
<<<<<<< HEAD
  final String id;
  final String cityName;
  final String district;
  final DateTime createdAt;
 
  const FavoriteCity({
    required this.id,
    required this.cityName,
    required this.district,
    required this.createdAt,
  });
 
  factory FavoriteCity.fromMap(String id, Map<String, dynamic> map) =>
      FavoriteCity(
        id: id,
        cityName: map['city_name'] as String,
        district: map['district'] as String? ?? '',
        createdAt: map['created_at'] != null
            ? (map['created_at'] as dynamic).toDate()
            : DateTime.now(),
      );
 
  Map<String, dynamic> toMap() => {
        'city_name': cityName,
        'district': district,
        'created_at': createdAt.toIso8601String(),
      };
 
  /// Busca por nome — sem ir ao banco.
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return cityName.toLowerCase().contains(q) ||
        district.toLowerCase().contains(q);
  }
}
 
=======
  final String cityName;
  final DateTime createdAt;

  FavoriteCity({required this.cityName, required this.createdAt});

  factory FavoriteCity.fromMap(Map<String, dynamic> map) => FavoriteCity(
        cityName: map['city_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
