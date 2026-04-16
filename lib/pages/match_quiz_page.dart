import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/city_location.dart';
import '../services/nominatim_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class MatchQuizPage extends StatefulWidget {
  final ValueChanged<CityLocation> onCityFound;

  const MatchQuizPage({super.key, required this.onCityFound});

  @override
  State<MatchQuizPage> createState() => _MatchQuizPageState();
}

class _MatchQuizPageState extends State<MatchQuizPage> {
  final _destination = TextEditingController();
  final _nominatim = NominatimService();
  final _values = <double>[50, 50, 75];
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

  Future<void> _find() async {
    final city = _destination.text.trim();
    if (city.isEmpty) {
      _toast('Por favor, insira uma cidade de destino', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _nominatim.searchCity(city);
      if (result == null) {
        _toast('Cidade "$city" não encontrada. Tente outro nome.', error: true);
        return;
      }
      _toast('Explorando ${result.name}!');
      widget.onCityFound(result);
    } catch (_) {
      _toast('Erro ao buscar a cidade. Verifique sua conexão.', error: true);
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
            Text('${_values[i].round()}%',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _values[i],
          min: 0,
          max: 100,
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
