class DistrictScore {
  final String city;
  final String district;
  final double latitude;
  final double longitude;
  final double leisureScore;
  final double safetyScore;
  final double centerDistanceScore;
  final double premiumPriceScore;
  final double overallScore;
  final double distanceCityCenter;
  final double attractionIndex;
  final double restaurantIndex;
  final double crimeIndex;
  final double safetyIndex;
  final double averagePrice;
  final int sampleSize;

  const DistrictScore({
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.leisureScore,
    required this.safetyScore,
    required this.centerDistanceScore,
    required this.premiumPriceScore,
    required this.overallScore,
    required this.distanceCityCenter,
    required this.attractionIndex,
    required this.restaurantIndex,
    required this.crimeIndex,
    required this.safetyIndex,
    required this.averagePrice,
    required this.sampleSize,
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'leisure_score': leisureScore,
        'safety_score': safetyScore,
        'center_distance_score': centerDistanceScore,
        'premium_price_score': premiumPriceScore,
        'overall_score': overallScore,
        'distance_city_center': distanceCityCenter,
        'attraction_index': attractionIndex,
        'restaurant_index': restaurantIndex,
        'crime_index': crimeIndex,
        'safety_index': safetyIndex,
        'average_price': averagePrice,
        'sample_size': sampleSize,
      };

  factory DistrictScore.fromJson(Map<String, dynamic> json) => DistrictScore(
        city: json['city'] as String,
        district: json['district'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        leisureScore: (json['leisure_score'] as num).toDouble(),
        safetyScore: (json['safety_score'] as num).toDouble(),
        centerDistanceScore: (json['center_distance_score'] as num).toDouble(),
        premiumPriceScore: (json['premium_price_score'] as num).toDouble(),
        overallScore: (json['overall_score'] as num).toDouble(),
        distanceCityCenter: (json['distance_city_center'] as num).toDouble(),
        attractionIndex: (json['attraction_index'] as num).toDouble(),
        restaurantIndex: (json['restaurant_index'] as num).toDouble(),
        crimeIndex: (json['crime_index'] as num).toDouble(),
        safetyIndex: (json['safety_index'] as num).toDouble(),
        averagePrice: (json['average_price'] as num).toDouble(),
        sampleSize: json['sample_size'] as int,
      );
}
