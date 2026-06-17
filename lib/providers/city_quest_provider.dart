import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city_quest.dart';
import '../services/city_quest_service.dart';
import '../services/city_quest_seed.dart';
import 'city_provider.dart';

/// Nome da cidade atualmente selecionada no app (vem do fluxo global —
/// quiz/mapa). As missões de cidade se adaptam a este valor.
final currentCityNameProvider = Provider<String>((ref) {
  return ref.watch(cityProvider).name;
});

/// Quests de uma cidade específica (consulta avulsa).
final cityQuestsProvider =
    FutureProvider.family<List<CityQuest>, String>((ref, cityName) async {
  if (cityName.trim().isEmpty) return [];
  return cityQuestService.fetchByCity(cityName);
});

/// Controlador das missões da cidade ATUAL, com CRUD e estado vivo.
///
/// Reage à cidade global: ao trocar de cidade, recarrega as missões daquela
/// cidade. Qualquer usuário logado pode criar/editar/excluir (catálogo
/// compartilhado da cidade).
final cityQuestsControllerProvider =
    NotifierProvider<CityQuestController, AsyncValue<List<CityQuest>>>(
  CityQuestController.new,
);

class CityQuestController extends Notifier<AsyncValue<List<CityQuest>>> {
  String _city = '';

  @override
  AsyncValue<List<CityQuest>> build() {
    _city = ref.watch(currentCityNameProvider);
    _load(_city);
    return const AsyncValue.loading();
  }

  Future<void> _load(String city) async {
    try {
      final list = await cityQuestService.fetchByCity(city);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Recarrega as missões da cidade atual.
  Future<void> reload() => _load(_city);

  Future<bool> add(CityQuest quest) async {
    final created = await cityQuestService.create(quest.copyWith(cityName: _city));
    if (created == null) return false;
    state.whenData((list) {
      state = AsyncValue.data([...list, created]);
    });
    return true;
  }

  Future<bool> edit(CityQuest quest) async {
    final ok = await cityQuestService.update(quest);
    if (!ok) return false;
    state.whenData((list) {
      state = AsyncValue.data([
        for (final q in list) q.id == quest.id ? quest : q,
      ]);
    });
    return true;
  }

  Future<bool> remove(String questId) async {
    final ok = await cityQuestService.delete(questId);
    if (!ok) return false;
    state.whenData((list) {
      state = AsyncValue.data(list.where((q) => q.id != questId).toList());
    });
    return true;
  }

  /// Popula a cidade atual com missões de exemplo (seed). Idempotente do ponto
  /// de vista da UI: só é oferecido quando a cidade não tem nenhuma missão.
  Future<void> seedExamples() async {
    final quests = buildSeedQuestsForCity(_city);
    if (quests.isEmpty) return;
    await cityQuestService.seedQuestsForCity(_city, quests);
    await _load(_city);
  }
}
