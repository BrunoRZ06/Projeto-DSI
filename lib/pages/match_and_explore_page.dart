import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/city_location.dart';
import '../models/district_score.dart';
import '../providers/city_provider.dart';
import '../providers/review_provider.dart';
import '../services/city_dataset_service.dart';
import '../services/district_key.dart';
import '../services/nominatim_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/photo_gallery.dart';
import '../Lib/district_reviews_page.dart';

const _photos = [
  'assets/images/neighborhood-1.jpg',
  'assets/images/neighborhood-2.jpg',
  'assets/images/neighborhood-3.jpg',
  'assets/images/neighborhood-4.jpg',
];

/// Tela unificada:
/// - Fase 1 (quiz): formulário de preferências
/// - Fase 2 (explorar): mapa + detalhes do bairro recomendado
/// A transição é feita localmente com AnimatedSwitcher, sem trocar de aba.
class MatchAndExplorePage extends ConsumerStatefulWidget {
  const MatchAndExplorePage({super.key});

  @override
  ConsumerState<MatchAndExplorePage> createState() =>
      _MatchAndExplorePageState();
}

class _MatchAndExplorePageState extends ConsumerState<MatchAndExplorePage> {
  // ── Quiz state ────────────────────────────────────────────────────────────
  final _destination = TextEditingController();
  final _values = <double>[3, 3, 4];
  bool _loading = false;
  bool _showExplorer = false; // false = quiz, true = mapa

  // ── Explorer state ────────────────────────────────────────────────────────
  final _mapController = MapController();
  final _nominatim = NominatimService();
  final Map<String, Future<String>> _nameFutures = {};
  DistrictScore? _selectedDistrict;
  String? _lastCityCenterKey;

  static const _sliders = <(String, String, String)>[
    ('Orçamento', 'Mochileiro', 'Luxo'),
    ('Pontos Turísticos', 'Perto', 'Longe'),
    ('Prioridade de Segurança', 'Tranquilo', 'Máxima'),
  ];

  @override
  void dispose() {
    _destination.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Helpers quiz ──────────────────────────────────────────────────────────

  double _toPercent(double v) => ((v - 1) / 4) * 100;

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? AppColors.destructive : AppColors.foreground,
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
      final preferences = RankingPreferences(
        budget: _toPercent(_values[0]),
        tourismDistance: _toPercent(_values[1]),
        safetyPriority: _toPercent(_values[2]),
      );

      ref
          .read(rankingPreferencesProvider.notifier)
          .setPreferences(preferences);

      final rankedDistricts =
          await cityDatasetService.rankDistrictsForCity(city,
              preferences: preferences);

      if (rankedDistricts.isEmpty) {
        _toast('Nenhum distrito encontrado para "$city"', error: true);
        return;
      }

      final best = rankedDistricts.first;
      final location = CityLocation(
        name: best.city,
        lat: best.latitude,
        lng: best.longitude,
        district: best.district,
      );

      ref.read(cityProvider.notifier).setCity(location);
      _toast('Match: ${best.district} (${best.city})');

      // Transição para o explorador
      setState(() {
        _showExplorer = true;
        _selectedDistrict = null;
      });
    } catch (_) {
      _toast('Erro ao buscar. Tente novamente.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers explorer ──────────────────────────────────────────────────────

  String _coordKey(DistrictScore d) =>
      '${d.latitude.toStringAsFixed(5)},${d.longitude.toStringAsFixed(5)}';

  Future<String> _resolveName(DistrictScore d) {
    final key = _coordKey(d);
    return _nameFutures.putIfAbsent(key, () async {
      final name = await _nominatim.reverseNeighborhoodName(d.latitude, d.longitude);
      return (name != null && name.trim().isNotEmpty) ? name : d.district;
    });
  }

  String _positionSuffix(DistrictScore d, LatLng center) {
    const t = 0.004;
    final latD = d.latitude - center.latitude;
    final lngD = d.longitude - center.longitude;
    final ns = latD.abs() < t ? 'Centro' : (latD > 0 ? 'Norte' : 'Sul');
    final ew = lngD.abs() < t ? 'Centro' : (lngD > 0 ? 'Leste' : 'Oeste');
    if (ns == 'Centro' && ew == 'Centro') return 'Centro';
    if (ns == 'Centro') return ew;
    if (ew == 'Centro') return ns;
    return '$ns-$ew';
  }

  Future<Map<String, String>> _resolveNames(
      List<DistrictScore> districts, LatLng center) async {
    final resolved = <String, String>{};
    for (final d in districts) {
      resolved[_coordKey(d)] = await _resolveName(d);
    }
    final grouped = <String, List<DistrictScore>>{};
    for (final d in districts) {
      grouped.putIfAbsent(resolved[_coordKey(d)]!, () => []).add(d);
    }
    final result = <String, String>{};
    for (final entry in grouped.entries) {
      if (entry.value.length == 1) {
        result[_coordKey(entry.value.first)] = entry.key;
        continue;
      }
      final used = <String>{};
      for (var i = 0; i < entry.value.length; i++) {
        final d = entry.value[i];
        var label = '${entry.key} (${_positionSuffix(d, center)})';
        if (used.contains(label)) label = '$label ${i + 1}';
        used.add(label);
        result[_coordKey(d)] = label;
      }
    }
    return result;
  }

  void _syncMap(LatLng center) {
    final key =
        '${center.latitude.toStringAsFixed(5)},${center.longitude.toStringAsFixed(5)}';
    if (_lastCityCenterKey == key) return;
    _lastCityCenterKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(center, 13);
      if (_selectedDistrict != null) {
        setState(() => _selectedDistrict = null);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showExplorer ? _buildExplorer() : _buildQuiz(),
    );
  }

  // ── Quiz ──────────────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    return SafeArea(
      key: const ValueKey('quiz'),
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
                    Icon(LucideIcons.sparkles,
                        size: 16, color: AppColors.coral),
                    SizedBox(width: 6),
                    Text('BAIRROMATCH',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Vibe',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: AppColors.foreground,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nos conte o que importa e vamos encontrar o bairro perfeito pra você.',
                  style: TextStyle(
                      fontSize: 15, color: AppColors.mutedForeground),
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
                ElevatedButton.icon(
                  onPressed: _loading ? null : _find,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.sparkles, size: 18),
                  label: Text(_loading ? 'Buscando...' : 'Match'),
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

  // ── Explorer ──────────────────────────────────────────────────────────────

  Widget _buildExplorer() {
    final city = ref.watch(cityProvider);
    final rankedAsync = ref.watch(districtRankingProvider);
    final bestDistrict = ref.watch(bestDistrictProvider);

    final allDistricts = rankedAsync.when(
      data: (d) => d.take(6).toList(),
      loading: () => const <DistrictScore>[],
      error: (_, __) => const <DistrictScore>[],
    );
    final topThree = allDistricts.take(3).toList();
    final displayedDistrict = _selectedDistrict ?? bestDistrict;
    final center = LatLng(city.lat, city.lng);
    _syncMap(center);

    return FutureBuilder<Map<String, String>>(
      future: _resolveNames(allDistricts, center),
      builder: (context, namesSnap) {
        final names = namesSnap.data ?? {};
        return SafeArea(
          key: const ValueKey('explorer'),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: CustomScrollView(
                slivers: [
                  // Botão "← Novo Match"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _showExplorer = false;
                              _selectedDistrict = null;
                            }),
                            icon: const Icon(LucideIcons.arrowLeft, size: 16),
                            label: const Text('Novo Match'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.coral,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Mapa
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.42,
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: ValueKey(
                                '${city.name}-${city.lat}-${city.lng}-${allDistricts.length}'),
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.drag |
                                    InteractiveFlag.flingAnimation |
                                    InteractiveFlag.pinchMove |
                                    InteractiveFlag.pinchZoom |
                                    InteractiveFlag.doubleTapZoom |
                                    InteractiveFlag.doubleTapDragZoom |
                                    InteractiveFlag.scrollWheelZoom,
                              ),
                              onTap: (_, __) => setState(
                                  () => _selectedDistrict = null),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'vibe_coral_quest',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: center,
                                    width: 34,
                                    height: 34,
                                    child: _MapDot(),
                                  ),
                                  for (final d in allDistricts)
                                    Marker(
                                      point: LatLng(d.latitude, d.longitude),
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        behavior:
                                            HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(
                                              () => _selectedDistrict = d);
                                          _mapController.move(
                                            LatLng(d.latitude, d.longitude),
                                            14.6,
                                          );
                                        },
                                        child: _MapDot(
                                          selected:
                                              _selectedDistrict?.district ==
                                                  d.district,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Chips de info
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _Chip(
                                    text: city.name,
                                    background: Colors.white),
                                _Chip(
                                  text:
                                      '${topThree.length} bairros',
                                  background: AppColors.coral,
                                  foreground: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          // Zoom buttons
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Column(
                              children: [
                                _ZoomBtn(
                                  icon: LucideIcons.plus,
                                  onTap: () => _mapController.move(
                                      _mapController.camera.center,
                                      _mapController.camera.zoom + 0.7),
                                ),
                                const SizedBox(height: 8),
                                _ZoomBtn(
                                  icon: LucideIcons.minus,
                                  onTap: () => _mapController.move(
                                      _mapController.camera.center,
                                      _mapController.camera.zoom - 0.7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top 3
                  if (topThree.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.background,
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Melhores Opções',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foreground)),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: topThree.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final d = topThree[i];
                                final isFirst = i == 0;
                                final name = names[_coordKey(d)] ??
                                    d.district;
                                return GestureDetector(
                                  onTap: () {
                                    setState(
                                        () => _selectedDistrict = d);
                                    _mapController.move(
                                        LatLng(d.latitude, d.longitude),
                                        14.6);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isFirst
                                          ? AppColors.coralLight
                                          : AppColors.secondary,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _selectedDistrict
                                                    ?.district ==
                                                d.district
                                            ? AppColors.coral
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (isFirst)
                                                    const Icon(
                                                      LucideIcons.crown,
                                                      size: 16,
                                                      color:
                                                          AppColors.warning,
                                                    ),
                                                  if (isFirst)
                                                    const SizedBox(
                                                        width: 6),
                                                  Text(name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isFirst
                                                            ? AppColors
                                                                .coralDark
                                                            : AppColors
                                                                .foreground,
                                                      )),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Lazer ${d.leisureScore.toStringAsFixed(0)} · Segurança ${d.safetyScore.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .mutedForeground),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isFirst
                                                ? AppColors.coral
                                                : AppColors.coralLight,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${d.overallScore.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isFirst
                                                  ? Colors.white
                                                  : AppColors.coralDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Detalhe do bairro selecionado
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                      child: displayedDistrict == null
                          ? const Center(
                              child: Text(
                                'Selecione um bairro para ver detalhes',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedForeground),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _DistrictDetail(district: displayedDistrict),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detalhe do bairro (extraído para widget para clareza)
// ─────────────────────────────────────────────────────────────────────────────

class _DistrictDetail extends ConsumerWidget {
  final DistrictScore district;
  const _DistrictDetail({required this.district});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtKey = generateDistrictKey(district);
    final stats = ref.watch(reviewStatsProvider(districtKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.star, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            stats.when(
              data: (s) {
                final avg = (s['average'] as double?) ?? 0.0;
                final count = (s['count'] as int?) ?? 0;
                return Text(
                  '${avg.toStringAsFixed(1)} · $count avaliações',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground),
                );
              },
              loading: () => const Text('Carregando...',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground)),
              error: (_, __) => const Text('Sem avaliações',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DistrictReviewsPage(
                    districtKey: districtKey,
                    city: district.city,
                    district: district.district,
                    latitude: district.latitude,
                    longitude: district.longitude,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.coral, padding: EdgeInsets.zero),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Avaliações',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Icon(LucideIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: _Stat('Média/Noite', r'$50')),
            SizedBox(width: 12),
            Expanded(child: _Stat('Caminhabilidade', '88')),
            SizedBox(width: 12),
            Expanded(child: _Stat('Cafés', '90+')),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Fotos da Comunidade',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground)),
            TextButton(
              onPressed: () =>
                  PhotoGalleryDialog.show(context, photos: _photos),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.coral, padding: EdgeInsets.zero),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver todas',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Icon(LucideIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => PhotoGalleryDialog.show(context,
                  photos: _photos, initialIndex: i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(_photos[i],
                    width: 112, height: 112, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets pequenos
// ─────────────────────────────────────────────────────────────────────────────

class _MapDot extends StatelessWidget {
  final bool selected;
  const _MapDot({this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.coralDark : AppColors.coral,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: AppColors.foreground),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const _Chip(
      {required this.text,
      required this.background,
      this.foreground = AppColors.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
        ],
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground)),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}
