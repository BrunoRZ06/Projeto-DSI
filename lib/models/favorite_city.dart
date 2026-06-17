class FavoriteCity {
  final String cityName;
  final DateTime createdAt;

  FavoriteCity({required this.cityName, required this.createdAt});

  factory FavoriteCity.fromMap(Map<String, dynamic> map) => FavoriteCity(
        cityName: map['city_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
