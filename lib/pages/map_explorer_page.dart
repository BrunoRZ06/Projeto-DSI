import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../providers/city_provider.dart';
import '../providers/review_provider.dart';
import '../services/district_key.dart';
import '../services/nominatim_service.dart';
import 'district_reviews_page.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_gallery.dart';

const _photos = [
  'assets/images/neighborhood-1.jpg',
  'assets/images/neighborhood-2.jpg',
  'assets/images/neighborhood-3.jpg',
  'assets/images/neighborhood-4.jpg',
];

class MapExplorerPage extends ConsumerStatefulWidget {
  const MapExplorerPage({super.key});

  @override
  ConsumerState<MapExplorerPage> createState() => _MapExplorerPageState();
}

class _MapExplorerPageState extends ConsumerState<MapExplorerPage> {
  final MapController _mapController = MapController();
  final NominatimService _nominatimService = NominatimService();
  final Map<String, Future<String>> _neighborhoodNameFutures =
      <String, Future<String>>{};
  DistrictScore? _selectedDistrict;
  String? _lastCityCenterKey;

  String _districtCoordKey(DistrictScore district) {
    return '${district.latitude.toStringAsFixed(5)},${district.longitude.toStringAsFixed(5)}';
  }

  Future<String> _resolveDistrictName(DistrictScore district) {
    final key = _districtCoordKey(district);
    return _neighborhoodNameFutures.putIfAbsent(key, () async {
      final name = await _nominatimService.reverseNeighborhoodName(
        district.latitude,
        district.longitude,
      );
      if (name != null && name.trim().isNotEmpty) return name;
      return district.district;
    });
  }

  String _positionSuffix(DistrictScore district, LatLng center) {
    const centerThreshold = 0.004;
    final latDelta = district.latitude - center.latitude;
    final lngDelta = district.longitude - center.longitude;

    final ns = latDelta.abs() < centerThreshold
        ? 'Centro'
        : (latDelta > 0 ? 'Norte' : 'Sul');
    final ew = lngDelta.abs() < centerThreshold
        ? 'Centro'
        : (lngDelta > 0 ? 'Leste' : 'Oeste');

    if (ns == 'Centro' && ew == 'Centro') return 'Centro';
    if (ns == 'Centro') return ew;
    if (ew == 'Centro') return ns;
    return '$ns-$ew';
  }

  Future<Map<String, String>> _resolveDistinctNames(
    List<DistrictScore> districts,
    LatLng center,
  ) async {
    if (districts.isEmpty) return <String, String>{};

    final resolved = <String, String>{};
    for (final district in districts) {
      final key = _districtCoordKey(district);
      resolved[key] = await _resolveDistrictName(district);
    }

    final grouped = <String, List<DistrictScore>>{};
    for (final district in districts) {
      final key = _districtCoordKey(district);
      final base = resolved[key] ?? district.district;
      grouped.putIfAbsent(base, () => <DistrictScore>[]).add(district);
    }

    final result = <String, String>{};
    for (final entry in grouped.entries) {
      final baseName = entry.key;
      final group = entry.value;

      if (group.length == 1) {
        result[_districtCoordKey(group.first)] = baseName;
        continue;
      }

      final usedLabels = <String>{};
      for (var i = 0; i < group.length; i++) {
        final district = group[i];
        final key = _districtCoordKey(district);

        var label = '$baseName (${_positionSuffix(district, center)})';
        if (usedLabels.contains(label)) {
          label = '$label ${i + 1}';
        }
        usedLabels.add(label);
        result[key] = label;
      }
    }

    return result;
  }

  void _syncMapCenter(LatLng center) {
    final cityKey =
        '${center.latitude.toStringAsFixed(5)},${center.longitude.toStringAsFixed(5)}';
    if (_lastCityCenterKey == cityKey) return;
    _lastCityCenterKey = cityKey;

    // Recenter after build when user searches a new city.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(center, 13);
      if (_selectedDistrict != null) {
        setState(() {
          _selectedDistrict = null;
        });
      }
    });
  }

  List<Marker> _buildMarkers({
    required LatLng center,
    required List<DistrictScore> districts,
    required Map<String, String> namesByDistrict,
  }) {
    return [
      Marker(
        point: center,
        width: 34,
        height: 34,
        child: const _MapDot(),
      ),
      for (final district in districts)
        Marker(
          point: LatLng(district.latitude, district.longitude),
          width: 44,
          height: 44,
          child: Tooltip(
            message: namesByDistrict[_districtCoordKey(district)] ??
                district.district,
            waitDuration: const Duration(milliseconds: 150),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedDistrict = district;
                });
                _mapController.move(
                  LatLng(district.latitude, district.longitude),
                  14.6,
                );
              },
              child: _MapDot(
                selected: _selectedDistrict?.district == district.district,
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(cityProvider);
    final rankedAsync = ref.watch(districtRankingProvider);
    final bestDistrict = ref.watch(bestDistrictProvider);

    final topThreeDistricts = rankedAsync.when(
      data: (districts) => districts.take(3).toList(),
      loading: () => const <DistrictScore>[],
      error: (_, __) => const <DistrictScore>[],
    );

    final allDistricts = rankedAsync.when(
      data: (districts) => districts.take(6).toList(),
      loading: () => const <DistrictScore>[],
      error: (_, __) => const <DistrictScore>[],
    );

    final displayedDistrict = _selectedDistrict ?? bestDistrict;
    final center = LatLng(city.lat, city.lng);
    _syncMapCenter(center);

    return FutureBuilder<Map<String, String>>(
      future: _resolveDistinctNames(allDistricts, center),
      builder: (context, namesSnapshot) {
        final namesByDistrict = namesSnapshot.data ?? const <String, String>{};
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: ValueKey(
                              '${city.name}-${city.lat}-${city.lng}-${allDistricts.length}',
                            ),
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
                              onTap: (_, __) {
                                setState(() {
                                  _selectedDistrict = null;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'vibe_coral_quest',
                              ),
                              MarkerLayer(
                                markers: _buildMarkers(
                                  center: center,
                                  districts: allDistricts,
                                  namesByDistrict: namesByDistrict,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Column(
                              children: [
                                _ZoomButton(
                                  icon: LucideIcons.plus,
                                  onTap: () {
                                    final currentZoom =
                                        _mapController.camera.zoom;
                                    _mapController.move(
                                      _mapController.camera.center,
                                      currentZoom + 0.7,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                _ZoomButton(
                                  icon: LucideIcons.minus,
                                  onTap: () {
                                    final currentZoom =
                                        _mapController.camera.zoom;
                                    _mapController.move(
                                      _mapController.camera.center,
                                      currentZoom - 0.7,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _Chip(text: city.name),
                                _Chip(
                                  text: '${topThreeDistricts.length} bairros',
                                  background: AppColors.coral,
                                  foreground: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (topThreeDistricts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Melhores Opções',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topThreeDistricts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final district = topThreeDistricts[i];
                                final isFirst = i == 0;
                                final districtName = namesByDistrict[
                                        _districtCoordKey(district)] ??
                                    district.district;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDistrict = district;
                                    });
                                    _mapController.move(
                                      LatLng(
                                        district.latitude,
                                        district.longitude,
                                      ),
                                      14.6,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isFirst
                                          ? AppColors.coralLight
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _selectedDistrict?.district ==
                                                district.district
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
                                                    Icon(
                                                      LucideIcons.crown,
                                                      size: 16,
                                                      color: AppColors.warning,
                                                    ),
                                                  if (isFirst)
                                                    const SizedBox(width: 6),
                                                  Text(
                                                    districtName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isFirst
                                                          ? AppColors.coralDark
                                                          : Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Lazer ${district.leisureScore.toStringAsFixed(0)} · Segurança ${district.safetyScore.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isFirst
                                                ? AppColors.coral
                                                : AppColors.coralLight,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${district.overallScore.toStringAsFixed(0)}%',
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
                  SliverToBoxAdapter(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                      child: displayedDistrict == null
                          ? Center(
                              child: Text(
                                'Selecione um bairro para ver detalhes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Builder(builder: (context) {
                                    final districtKey = generateDistrictKey(displayedDistrict);
                                    final stats = ref.watch(reviewStatsProvider(districtKey));
                                    return Row(
                                      children: [
                                        Icon(LucideIcons.star, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 6),
                                        stats.when(
                                          data: (s) {
                                            final avg = (s['average'] as double?) ?? 0.0;
                                            final count = (s['count'] as int?) ?? 0;
                                            return Text('${avg.toStringAsFixed(1)} · $count avaliações',
                                                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant));
                                          },
                                          loading: () => Text('Carregando avaliações...', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                          error: (_, __) => Text('Sem avaliações', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(MaterialPageRoute(
                                              builder: (_) => DistrictReviewsPage(
                                                districtKey: districtKey,
                                                city: displayedDistrict.city,
                                                district: displayedDistrict.district,
                                                latitude: displayedDistrict.latitude,
                                                longitude: displayedDistrict.longitude,
                                              ),
                                            ));
                                          },
                                          style: TextButton.styleFrom(foregroundColor: AppColors.coral, padding: EdgeInsets.zero),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Avaliações', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                              Icon(LucideIcons.chevronRight, size: 14),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                const SizedBox(height: 20),
                                Row(
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
                                    Text('Fotos da Comunidade',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface)),
                                    TextButton(
                                      onPressed: () => PhotoGalleryDialog.show(
                                        context,
                                        photos: _photos,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.coral,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Ver todas',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Icon(LucideIcons.chevronRight,
                                              size: 14),
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
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (_, i) => GestureDetector(
                                      onTap: () => PhotoGalleryDialog.show(
                                        context,
                                        photos: _photos,
                                        initialIndex: i,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          _photos[i],
                                          width: 112,
                                          height: 112,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

class _Chip extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? foreground;

  const _Chip({
    required this.text,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (background ?? cs.surface).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground ?? cs.onSurface)),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

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

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}
