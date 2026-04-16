class CityLocation {
  final String name;
  final double lat;
  final double lng;

  const CityLocation({required this.name, required this.lat, required this.lng});

  static const london = CityLocation(name: 'Londres', lat: 51.525, lng: -0.1);
}
