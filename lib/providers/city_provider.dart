import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city_location.dart';

/// Cidade atualmente selecionada no app. Começa com Londres, igual ao React.
final cityProvider = StateProvider<CityLocation>((ref) => CityLocation.london);

/// Aba ativa na navegação inferior (0..3).
final activeTabProvider = StateProvider<int>((ref) => 0);
