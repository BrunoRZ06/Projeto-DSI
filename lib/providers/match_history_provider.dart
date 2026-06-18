import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_history.dart';
import '../models/district_score.dart';
import '../services/city_dataset_service.dart';
import '../services/match_history_service.dart';
import 'auth_provider.dart';

final matchHistoryServiceProvider = Provider<MatchHistoryService>((ref) {
  return matchHistoryService;
});

final matchHistoryProvider =
    NotifierProvider<MatchHistoryNotifier, AsyncValue<List<MatchHistory>>>(
  MatchHistoryNotifier.new,
);

class MatchHistoryNotifier extends Notifier<AsyncValue<List<MatchHistory>>> {
  @override
  AsyncValue<List<MatchHistory>> build() {
    ref.listen(currentUserProvider, (_, user) {
      if (user == null) {
        state = const AsyncValue.data(<MatchHistory>[]);
      } else {
        load();
      }
    }, fireImmediately: true);

    if (ref.read(currentUserProvider) == null) {
      return const AsyncValue.data(<MatchHistory>[]);
    }
    return const AsyncValue.loading();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await ref.read(matchHistoryServiceProvider).getUserHistory();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveMatch({
    required DistrictScore bestDistrict,
    required RankingPreferences preferences,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final history = MatchHistory.create(
      userId: user.uid,
      city: bestDistrict.city,
      bestDistrict: bestDistrict.district,
      latitude: bestDistrict.latitude,
      longitude: bestDistrict.longitude,
      score: bestDistrict.overallScore,
      preferences: preferences,
    );

    final created = await ref.read(matchHistoryServiceProvider).create(history);
    final list = state.asData?.value ?? const <MatchHistory>[];
    state = AsyncValue.data([created, ...list]);
  }

  Future<void> remove(String historyId) async {
    await ref.read(matchHistoryServiceProvider).delete(historyId);
    final list = state.asData?.value ?? const <MatchHistory>[];
    state = AsyncValue.data(list.where((item) => item.id != historyId).toList());
  }
}
