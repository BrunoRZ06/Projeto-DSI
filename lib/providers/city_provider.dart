import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/city_location.dart';
import '../models/district_score.dart';
import '../services/city_dataset_service.dart';

// City
class CityNotifier extends Notifier<CityLocation> {
  @override
  CityLocation build() => const CityLocation(
        name: 'Londres',
        lat: 51.5074,
        lng: -0.1278,
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

/// Ranking de bairros da cidade atual segundo as preferências escolhidas.
/// Usa o dataset curado (bairros famosos com notas 1–5) e cai no Firestore
/// para cidades fora do dataset. Reage à cidade global e às preferências, então
/// a aba Explorar mostra os bairros que mais deram match conforme os parâmetros.
final districtRankingProvider =
    FutureProvider<List<DistrictScore>>((ref) async {
  final city = ref.watch(cityProvider);
  final preferences = ref.watch(rankingPreferencesProvider);
  if (city.lat == 0 && city.lng == 0 && city.name.trim().isEmpty) {
    return const <DistrictScore>[];
  }
  return _cityDatasetService.rankDistricts(
    cityName: city.name,
    latitude: city.lat,
    longitude: city.lng,
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
