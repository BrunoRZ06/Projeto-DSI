import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/city_location.dart';
import '../models/district_score.dart';
import '../services/city_dataset_service.dart';

// City
class CityNotifier extends Notifier<CityLocation> {
  @override
  CityLocation build() => const CityLocation(
        name: 'São Paulo',
        lat: -23.5505,
        lng: -46.6333,
      );

  void setCity(CityLocation city) => state = city;
}

final cityProvider = NotifierProvider<CityNotifier, CityLocation>(
  CityNotifier.new,
);

// Tab
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int tab) => state = tab;
}

final _cityDatasetService = CityDatasetService();

class RankingPreferencesNotifier extends Notifier<RankingPreferences> {
  @override
  RankingPreferences build() => RankingPreferences.balanced;

  void setPreferences(RankingPreferences prefs) => state = prefs;
}

final rankingPreferencesProvider = NotifierProvider<RankingPreferencesNotifier, RankingPreferences>(
  RankingPreferencesNotifier.new,
);

/// Provider que busca distritos por lat/lng da cidade selecionada
final districtRankingProvider =
    FutureProvider<List<DistrictScore>>((ref) async {
  final city = ref.watch(cityProvider);
  final preferences = ref.watch(rankingPreferencesProvider);
  if (city.lat == 0 && city.lng == 0) {
    return const <DistrictScore>[];
  }
  return _cityDatasetService.rankDistrictsByLocation(
    city.lat,
    city.lng,
    radiusKm: 25.0,
    preferences: preferences,
  );
});

final bestDistrictProvider = Provider<DistrictScore?>((ref) {
  final ranking = ref.watch(districtRankingProvider);
  return ranking.when(
    data: (ranked) => ranked.isEmpty ? null : ranked.first,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Aba ativa na navegação inferior (0..3).
final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(
  ActiveTabNotifier.new,
);
