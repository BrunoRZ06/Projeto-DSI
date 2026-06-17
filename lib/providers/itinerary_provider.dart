import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/itinerary.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../services/itinerary_service.dart';
import '../services/places_mock_service.dart';

// ─── Provider de lugares disponíveis ─────────────────────────────────────────

final availablePlacesProvider = Provider<List<Place>>((ref) {
  final city = ref.watch(cityProvider);
  return getMockPlacesForCity(city.name);
});

// ─── Provider de filtro de categoria ─────────────────────────────────────────

class _PlaceFilterNotifier extends Notifier<PlaceCategory?> {
  @override
  PlaceCategory? build() => null;
  void set(PlaceCategory? cat) => state = cat;
}

final placeFilterProvider =
    NotifierProvider<_PlaceFilterNotifier, PlaceCategory?>(
  _PlaceFilterNotifier.new,
);

final filteredPlacesProvider = Provider<List<Place>>((ref) {
  final places = ref.watch(availablePlacesProvider);
  final filter = ref.watch(placeFilterProvider);
  if (filter == null) return places;
  return places.where((p) => p.category == filter).toList();
});

// ─── Provider de roteiros ─────────────────────────────────────────────────────

final itineraryProvider =
    NotifierProvider<ItineraryNotifier, AsyncValue<List<Itinerary>>>(
  ItineraryNotifier.new,
);

class ItineraryNotifier extends Notifier<AsyncValue<List<Itinerary>>> {
  @override
  AsyncValue<List<Itinerary>> build() {
    _init();
    return const AsyncValue.data([]);
  }

  void _init() {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        state = const AsyncValue.data([]);
        return;
      }
      if (previous?.uid != next.uid) {
        load(next.uid);
      }
    }, fireImmediately: true);
  }

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    try {
      final list = await itineraryService.fetchByUser(userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Itinerary> add(Itinerary itinerary) async {
    final created = await itineraryService.create(itinerary);
    state.whenData((list) => state = AsyncValue.data([created, ...list]));
    return created;
  }

  Future<void> edit(Itinerary itinerary) async {
    await itineraryService.update(itinerary);
    state.whenData((list) {
      state = AsyncValue.data([
        for (final i in list) i.id == itinerary.id ? itinerary : i,
      ]);
    });
  }

  Future<void> remove(String id) async {
    await itineraryService.delete(id);
    state.whenData(
        (list) => state = AsyncValue.data(list.where((i) => i.id != id).toList()));
  }
}
