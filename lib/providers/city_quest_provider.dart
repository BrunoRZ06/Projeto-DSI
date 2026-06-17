import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/city_quest.dart';
import '../services/city_quest_service.dart';

/// Provider para quests de uma cidade específica
final cityQuestsProvider = FutureProvider.family<List<CityQuest>, String>((ref, cityName) async {
  if (cityName.isEmpty) return [];
  return await cityQuestService.fetchByCity(cityName);
});

/// Provider para lista de cidades com quests disponíveis
final citiesWithQuestsProvider = FutureProvider<List<String>>((ref) async {
  return await cityQuestService.fetchCitiesWithQuests();
});

/// Provider para cidade selecionada atualmente
final selectedCityProvider = NotifierProvider<SelectedCityNotifier, String?>(
  SelectedCityNotifier.new,
);

class SelectedCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCity(String? city) {
    state = city;
  }

  void clear() {
    state = null;
  }
}
