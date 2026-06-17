class FavoriteCity {
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
 