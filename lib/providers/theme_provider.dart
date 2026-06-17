import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chave usada para persistir a preferência de tema no SharedPreferences.
const _kDarkModeKey = 'dark_mode_enabled';

/// Provider que expõe e persiste a escolha de Modo Noturno do usuário.
///
/// Uso:
///   - Leitura:   `ref.watch(darkModeProvider)` → bool
///   - Toggle:    `ref.read(darkModeProvider.notifier).toggle()`
///   - Definir:   `ref.read(darkModeProvider.notifier).set(true)`
class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDarkModeKey) ?? false;
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    await set(!current);
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, value);
    state = AsyncData(value);
  }
}

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

/// Provider conveniente que retorna o ThemeMode atual.
/// Usa ThemeMode.system enquanto carrega, depois light ou dark.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(darkModeProvider);
  return async.when(
    data: (dark) => dark ? ThemeMode.dark : ThemeMode.light,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.light,
  );
});
