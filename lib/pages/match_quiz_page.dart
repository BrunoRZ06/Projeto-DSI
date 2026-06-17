import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/city_location.dart';
import '../providers/city_provider.dart';
import '../services/city_dataset_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class MatchQuizPage extends ConsumerStatefulWidget {
  final ValueChanged<CityLocation> onCityFound;

  const MatchQuizPage({super.key, required this.onCityFound});

  @override
  ConsumerState<MatchQuizPage> createState() => _MatchQuizPageState();
}

class _MatchQuizPageState extends ConsumerState<MatchQuizPage> {
  final _destination = TextEditingController();
  final _values = <double>[3, 3, 4];
  bool _loading = false;

  static const _sliders = <(String, String, String)>[
    ('Orçamento', 'Mochileiro', 'Luxo'),
    ('Pontos Turísticos', 'Perto', 'Longe'),
    ('Prioridade de Segurança', 'Tranquilo', 'Máxima'),
  ];

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.destructive : AppColors.foreground,
      behavior: SnackBarBehavior.floating,
    ));
  }

  double _toPercent(double value) {
    return ((value - 1) / 4) * 100;
  }

  Future<void> _find() async {
    final city = _destination.text.trim();
    if (city.isEmpty) {
      _toast('Por favor, insira uma cidade de destino', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final preferences = RankingPreferences(
        budget: _toPercent(_values[0]),
        tourismDistance: _toPercent(_values[1]),
        safetyPriority: _toPercent(_values[2]),
      );

      ref.read(rankingPreferencesProvider.notifier).setPreferences(preferences);

      final rankedDistricts = await cityDatasetService.rankDistrictsForCity(
        city,
        preferences: preferences,
      );
      if (rankedDistricts.isEmpty) {
        _toast('Erro ao carregar', error: true);
        return;
      }

      final bestDistrict = rankedDistricts.first;

      final location = CityLocation(
        name: bestDistrict.city,
        lat: bestDistrict.latitude,
        lng: bestDistrict.longitude,
        district: bestDistrict.district,
      );

      _toast(
          'Melhor distrito encontrado: ${bestDistrict.district} (${bestDistrict.city})');
      widget.onCityFound(location);
    } catch (_) {
      _toast('Erro ao carregar', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 16, color: AppColors.coral),
                    SizedBox(width: 6),
                    Text('BAIRROMATCH',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Encontre Sua\nVibe',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: AppColors.foreground,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nos conte o que importa e vamos encontrar o bairro perfeito pra você.',
                  style: TextStyle(fontSize: 15, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 32),
                const Text('Cidade de Destino',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _destination,
                  hint: 'Londres, Paris, Tóquio, São Paulo...',
                  icon: LucideIcons.mapPin,
                  onSubmitted: _find,
                ),
                const SizedBox(height: 32),
                for (var i = 0; i < _sliders.length; i++) ...[
                  _buildSlider(i),
                  if (i < _sliders.length - 1) const SizedBox(height: 28),
                ],
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _loading ? null : _find,
                  child: Text(_loading
                      ? 'Buscando...'
                      : 'Encontrar Meu Bairro Perfeito'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(int i) {
    final (label, left, right) = _sliders[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground)),
            Text(_values[i].toStringAsFixed(0),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _values[i],
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (v) => setState(() => _values[i] = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mutedForeground)),
            Text(right,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mutedForeground)),
          ],
        ),
      ],
    );
  }
}
