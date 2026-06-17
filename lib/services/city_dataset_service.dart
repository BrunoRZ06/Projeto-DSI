import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/district_score.dart';

class RankingPreferences {
  final double budget;
  final double tourismDistance;
  final double safetyPriority;

  const RankingPreferences({
    required this.budget,
    required this.tourismDistance,
    required this.safetyPriority,
  });

  static const balanced = RankingPreferences(
    budget: 50,
    tourismDistance: 50,
    safetyPriority: 75,
  );
}

class CityDatasetService {
  Future<List<_CityRecord>>? _recordsFuture;

  Future<List<DistrictScore>> rankDistrictsByLocation(
    double latitude,
    double longitude, {
    double radiusKm = 25.0,
    RankingPreferences preferences = RankingPreferences.balanced,
  }) async {
    final records = await _loadRecords();

    const earthRadiusKm = 6371.0;

    double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
      final dLat = (lat2 - lat1) * pi / 180;
      final dLon = (lon2 - lon1) * pi / 180;
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1 * pi / 180) *
              cos(lat2 * pi / 180) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * asin(sqrt(a));
      return earthRadiusKm * c;
    }

    final filtered = records.where((record) {
      final distance = haversineDistance(
        latitude,
        longitude,
        record.latitude,
        record.longitude,
      );
      return distance <= radiusKm;
    }).toList();
    return _rankFromRecords(filtered, preferences: preferences);
  }

  Future<List<DistrictScore>> rankDistrictsForCity(
    String cityName, {
    RankingPreferences preferences = RankingPreferences.balanced,
  }) async {
    final records = await _loadRecords();
    final normalizedCity = _canonicalCityName(cityName);

    final filtered = records.where((record) {
      final city = _canonicalCityName(record.city);
      return city == normalizedCity ||
          city.contains(normalizedCity) ||
          normalizedCity.contains(city);
    }).toList();

    return _rankFromRecords(filtered, preferences: preferences);
  }

  List<DistrictScore> _rankFromRecords(
    List<_CityRecord> filtered, {
    required RankingPreferences preferences,
  }) {
    if (filtered.isEmpty) return const <DistrictScore>[];

    if (filtered.isEmpty) return const <DistrictScore>[];

    final byDistrict = <String, List<_CityRecord>>{};
    for (final record in filtered) {
      final key = '${record.city}|${record.district}';
      byDistrict.putIfAbsent(key, () => <_CityRecord>[]).add(record);
    }

    var usedGeoFallback = false;
    if (byDistrict.length < 3 && filtered.length >= 3) {
      usedGeoFallback = true;
      byDistrict.clear();
      for (final record in filtered) {
        final latBucket = record.latitude.toStringAsFixed(2);
        final lngBucket = record.longitude.toStringAsFixed(2);
        final key = '${record.city}|${record.district}|$latBucket|$lngBucket';
        byDistrict.putIfAbsent(key, () => <_CityRecord>[]).add(record);
      }
    }

    final aggregates = byDistrict.values.map(_aggregateDistrict).toList();

    final leisureValues = aggregates
        .map((a) => (a.attractionIndex + a.restaurantIndex) / 2)
        .toList();
    final safetyValues = aggregates
        .map((a) => (a.safetyIndex + (100 - a.crimeIndex)) / 2)
        .toList();
    final centerDistanceValues =
        aggregates.map((a) => a.distanceCityCenter).toList();
    final priceValues = aggregates.map((a) => a.averagePrice).toList();

    final ranked = <DistrictScore>[];
    for (final district in aggregates) {
      final leisureRaw = (district.attractionIndex + district.restaurantIndex) / 2;
      final safetyRaw = (district.safetyIndex + (100 - district.crimeIndex)) / 2;

      final leisureScore = _normalizeValue(
        leisureRaw,
        min: leisureValues.reduce(_min),
        max: leisureValues.reduce(_max),
      );

      final safetyScore = _normalizeValue(
        safetyRaw,
        min: safetyValues.reduce(_min),
        max: safetyValues.reduce(_max),
      );

      final centerDistanceScore = 100 -
          _normalizeValue(
            district.distanceCityCenter,
            min: centerDistanceValues.reduce(_min),
            max: centerDistanceValues.reduce(_max),
          );

      final premiumPriceScore = _normalizeValue(
        district.averagePrice,
        min: priceValues.reduce(_min),
        max: priceValues.reduce(_max),
      );

        final luxuryPreference = (preferences.budget / 100).clamp(0.0, 1.0);
        final distancePreference =
          (preferences.tourismDistance / 100).clamp(0.0, 1.0);
        final safetyPriority = (preferences.safetyPriority / 100).clamp(0.0, 1.0);

        final budgetMatch =
          (premiumPriceScore * luxuryPreference) +
            ((100 - premiumPriceScore) * (1 - luxuryPreference));

        final tourismMatch =
          ((100 - centerDistanceScore) * distancePreference) +
            (centerDistanceScore * (1 - distancePreference));

        const leisureWeight = 0.8;
        const budgetWeight = 1.0;
        const tourismWeight = 1.0;
        final safetyWeight = 0.4 + (2.6 * safetyPriority);

        final overallScore =
          (leisureScore * leisureWeight +
            budgetMatch * budgetWeight +
            tourismMatch * tourismWeight +
            safetyScore * safetyWeight) /
          (leisureWeight + budgetWeight + tourismWeight + safetyWeight);

      ranked.add(DistrictScore(
        city: district.city,
        district: district.district,
        latitude: district.latitude,
        longitude: district.longitude,
        leisureScore: leisureScore,
        safetyScore: safetyScore,
        centerDistanceScore: centerDistanceScore,
        premiumPriceScore: premiumPriceScore,
        overallScore: overallScore,
        distanceCityCenter: district.distanceCityCenter,
        attractionIndex: district.attractionIndex,
        restaurantIndex: district.restaurantIndex,
        crimeIndex: district.crimeIndex,
        safetyIndex: district.safetyIndex,
        averagePrice: district.averagePrice,
        sampleSize: district.sampleSize,
      ));
    }

    ranked.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    if (usedGeoFallback) {
      final relabeled = <DistrictScore>[];
      for (var i = 0; i < ranked.length; i++) {
        final item = ranked[i];
        relabeled.add(DistrictScore(
          city: item.city,
          district: item.district,
          latitude: item.latitude,
          longitude: item.longitude,
          leisureScore: item.leisureScore,
          safetyScore: item.safetyScore,
          centerDistanceScore: item.centerDistanceScore,
          premiumPriceScore: item.premiumPriceScore,
          overallScore: item.overallScore,
          distanceCityCenter: item.distanceCityCenter,
          attractionIndex: item.attractionIndex,
          restaurantIndex: item.restaurantIndex,
          crimeIndex: item.crimeIndex,
          safetyIndex: item.safetyIndex,
          averagePrice: item.averagePrice,
          sampleSize: item.sampleSize,
        ));
      }
      return relabeled;
    }

    return ranked;
  }

  Future<List<_CityRecord>> _loadRecords() {
    _recordsFuture ??= _readRecords();
    return _recordsFuture!;
  }

  Future<List<_CityRecord>> _readRecords() async {
    final content = await rootBundle.loadString('cities.csv');
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return const <_CityRecord>[];

    final headers = _splitCsvLine(lines.first);
    final index = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      index[headers[i].trim()] = i;
    }

    String field(List<String> values, String name) {
      final idx = index[name];
      if (idx == null || idx >= values.length) return '';
      return values[idx].trim();
    }

    double number(List<String> values, String name) {
      return double.tryParse(field(values, name)) ?? 0;
    }

    final records = <_CityRecord>[];
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final values = _splitCsvLine(line);
      records.add(_CityRecord(
        city: field(values, 'city'),
        district: field(values, 'district').isEmpty
            ? 'Sem distrito'
            : field(values, 'district'),
        latitude: number(values, 'latitude'),
        longitude: number(values, 'longitude'),
        distanceCityCenter: number(values, 'distance_city_center'),
        attractionIndex: number(values, 'attraction_index'),
        restaurantIndex: number(values, 'restaurant_index'),
        crimeIndex: number(values, 'crime_index'),
        safetyIndex: number(values, 'safety_index'),
        priceTotal: number(values, 'price_total'),
      ));
    }

    return records;
  }

  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        values.add(current.toString());
        current.clear();
        continue;
      }

      current.write(char);
    }

    values.add(current.toString());
    return values;
  }

  String _normalize(String value) {
    var text = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text;
  }

  String _canonicalCityName(String value) {
    final normalized = _normalize(value);
    const aliases = <String, String>{
      'londres': 'london',
      'nova iorque': 'new york',
      'nova york': 'new york',
      'toquio': 'tokyo',
      'pequim': 'beijing',
      'xangai': 'shanghai',
      'roma': 'rome',
      'milao': 'milan',
      'munique': 'munich',
      'copenhaga': 'copenhagen',
      'bruxelas': 'brussels',
      'moscovo': 'moscow',
      'praga': 'prague',
      'atenas': 'athens',
      'budapeste': 'budapest',
      'varsovia': 'warsaw',
      'estocolmo': 'stockholm',
      'florenca': 'florence',
      'colonia': 'cologne',
      'sevilha': 'seville',
      'genebra': 'geneva',
      'zurique': 'zurich',
      'lisboa': 'lisbon',
    };
    return aliases[normalized] ?? normalized;
  }

  double _normalizeValue(double value, {required double min, required double max}) {
    if ((max - min).abs() < 0.0001) return 50;
    return ((value - min) / (max - min)) * 100;
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  _DistrictAggregate _aggregateDistrict(List<_CityRecord> records) {
    double avg(double Function(_CityRecord r) get) {
      final sum = records.fold<double>(0, (acc, item) => acc + get(item));
      return sum / records.length;
    }

    final first = records.first;
    return _DistrictAggregate(
      city: first.city,
      district: first.district,
      latitude: avg((r) => r.latitude),
      longitude: avg((r) => r.longitude),
      distanceCityCenter: avg((r) => r.distanceCityCenter),
      attractionIndex: avg((r) => r.attractionIndex),
      restaurantIndex: avg((r) => r.restaurantIndex),
      crimeIndex: avg((r) => r.crimeIndex),
      safetyIndex: avg((r) => r.safetyIndex),
      averagePrice: avg((r) => r.priceTotal),
      sampleSize: records.length,
    );
  }
}

class _CityRecord {
  final String city;
  final String district;
  final double latitude;
  final double longitude;
  final double distanceCityCenter;
  final double attractionIndex;
  final double restaurantIndex;
  final double crimeIndex;
  final double safetyIndex;
  final double priceTotal;

  const _CityRecord({
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.distanceCityCenter,
    required this.attractionIndex,
    required this.restaurantIndex,
    required this.crimeIndex,
    required this.safetyIndex,
    required this.priceTotal,
  });
}

class _DistrictAggregate {
  final String city;
  final String district;
  final double latitude;
  final double longitude;
  final double distanceCityCenter;
  final double attractionIndex;
  final double restaurantIndex;
  final double crimeIndex;
  final double safetyIndex;
  final double averagePrice;
  final int sampleSize;

  const _DistrictAggregate({
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.distanceCityCenter,
    required this.attractionIndex,
    required this.restaurantIndex,
    required this.crimeIndex,
    required this.safetyIndex,
    required this.averagePrice,
    required this.sampleSize,
  });
}

final cityDatasetService = CityDatasetService();
