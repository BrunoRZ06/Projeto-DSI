import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_city.dart';
import '../services/favorite_city_service.dart';
import 'auth_provider.dart';

/// Stream das cidades favoritas do usuário logado.
final favoriteCitiesProvider = StreamProvider<List<FavoriteCity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <FavoriteCity>[]);
  return favoriteCityService.watchForUser(user.uid);
});

/// Conjunto (normalizado) dos nomes favoritados, para checagem rápida na UI.
final favoriteCityNamesProvider = Provider<Set<String>>((ref) {
  final favs = ref.watch(favoriteCitiesProvider).asData?.value ?? const [];
  return favs.map((f) => f.cityName.trim().toLowerCase()).toSet();
});
