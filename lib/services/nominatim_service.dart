import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/city_location.dart';

/// Geocodificação via OpenStreetMap Nominatim.
/// Nominatim pede um User-Agent identificável — use algo como nome do app + contato.
class NominatimService {
  static const String _userAgent = 'BairroMatch/0.1 (contato@exemplo.com)';

  Future<CityLocation?> searchCity(String city) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json&q=${Uri.encodeComponent(city)}&limit=1',
    );

    final res = await http.get(uri, headers: {'User-Agent': _userAgent});
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as List<dynamic>;
    if (data.isEmpty) return null;

    final first = data.first as Map<String, dynamic>;
    final displayName = first['display_name'] as String? ?? city;
    final shortName = displayName.split(',').first.trim();

    return CityLocation(
      name: shortName,
      lat: double.parse(first['lat'].toString()),
      lng: double.parse(first['lon'].toString()),
    );
  }
}
