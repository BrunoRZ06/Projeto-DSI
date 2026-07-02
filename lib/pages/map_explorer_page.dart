import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../providers/favorite_provider.dart';
import '../services/district_key.dart';
import '../services/city_dataset_service.dart';
import '../services/favorite_city_service.dart';
import '../services/supabase_service.dart';
import 'travel_budget_page.dart';
import '../theme/app_theme.dart';
import '../widgets/district_reviews_section.dart';
import '../widgets/photo_gallery.dart';

/// Fotos de exemplo (assets) usadas como fallback quando o bairro ainda não
/// tem fotos enviadas pela comunidade.
const _fallbackPhotos = [
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
  DistrictScore? _selectedDistrict;
  String? _lastCityCenterKey;

  String _districtCoordKey(DistrictScore district) {
    return '${district.latitude.toStringAsFixed(5)},${district.longitude.toStringAsFixed(5)}';
  }

  // Os bairros do dataset curado já têm nomes próprios, então usamos o nome
  // direto (sem geocodificação reversa).
  Future<String> _resolveDistrictName(DistrictScore district) {
    return Future.value(district.district);
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Chip(text: city.name),
                                    const SizedBox(width: 8),
                                    _FavoriteCityButton(cityName: city.name),
                                  ],
                                ),
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
                  SliverToBoxAdapter(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: const _PreferencesPanel(),
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
                                    return DistrictReviewsSection(
                                      districtKey: districtKey,
                                      city: displayedDistrict.city,
                                      district: displayedDistrict.district,
                                      latitude: displayedDistrict.latitude,
                                      longitude: displayedDistrict.longitude,
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
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: Icon(LucideIcons.wallet, size: 18),
                                    label: Text('Planejar Gastos'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.coral,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => TravelBudgetPage(district: displayedDistrict),
                                      ));
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _CommunityGallery(district: displayedDistrict),
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

/// Painel de ajuste das preferências (1–5) na própria aba Explorar. Ao mover
/// um slider, atualiza [rankingPreferencesProvider] e o ranking de bairros
/// re-ordena na hora — mostrando os que mais deram match.
class _PreferencesPanel extends ConsumerStatefulWidget {
  const _PreferencesPanel();

  @override
  ConsumerState<_PreferencesPanel> createState() => _PreferencesPanelState();
}

class _PreferencesPanelState extends ConsumerState<_PreferencesPanel> {
  bool _expanded = true;

  static const _sliders = <(String, String, String)>[
    ('Orçamento', 'Mochileiro', 'Luxo'),
    ('Pontos Turísticos', 'Perto', 'Longe'),
    ('Segurança', 'Indiferente', 'Máxima'),
  ];

  double _toSlider(double pref) => (1 + pref / 25).clamp(1.0, 5.0);
  double _toPref(double slider) => (slider - 1) * 25;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(rankingPreferencesProvider);
    final values = <double>[
      _toSlider(prefs.budget),
      _toSlider(prefs.tourismDistance),
      _toSlider(prefs.safetyPriority),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(LucideIcons.slidersHorizontal, size: 16, color: AppColors.coral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suas preferências',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < _sliders.length; i++)
              _buildSlider(i, values[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(int i, double value) {
    final (label, left, right) = _sliders[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
            Text(value.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (v) {
            final current = ref.read(rankingPreferencesProvider);
            final next = RankingPreferences(
              budget: i == 0 ? _toPref(v) : current.budget,
              tourismDistance: i == 1 ? _toPref(v) : current.tourismDistance,
              safetyPriority: i == 2 ? _toPref(v) : current.safetyPriority,
            );
            ref.read(rankingPreferencesProvider.notifier).setPreferences(next);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(right,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

/// Galeria da comunidade de um bairro: mostra as fotos enviadas pelos usuários
/// (com fallback para imagens de exemplo) e permite adicionar uma nova foto.
class _CommunityGallery extends ConsumerStatefulWidget {
  final DistrictScore district;
  const _CommunityGallery({required this.district});

  @override
  ConsumerState<_CommunityGallery> createState() => _CommunityGalleryState();
}

class _CommunityGalleryState extends ConsumerState<_CommunityGallery> {
  final _picker = ImagePicker();
  bool _uploading = false;
  bool _loading = true;
  List<String> _urls = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_CommunityGallery old) {
    super.didUpdateWidget(old);
    if (old.district.district != widget.district.district ||
        old.district.city != widget.district.city) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final urls = await SupabaseService.listCommunityPhotos(
        widget.district.city, widget.district.district);
    if (!mounted) return;
    setState(() {
      _urls = urls;
      _loading = false;
    });
  }

  Future<void> _addPhoto() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _toast('Faça login para enviar fotos.', error: true);
      return;
    }
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() => _uploading = true);

      final bytes = await image.readAsBytes();
      final url = await SupabaseService.uploadCommunityPhoto(
        bytes: bytes,
        fileName: image.name,
        city: widget.district.city,
        district: widget.district.district,
        userId: user.uid,
      );
      if (url == null) {
        _toast('Erro ao enviar a foto.', error: true);
        return;
      }
      // Mostra na hora (a listagem do Supabase pode levar um instante).
      setState(() => _urls = [url, ..._urls]);
      _toast('Foto adicionada à galeria! 📸');
    } catch (_) {
      _toast('Erro ao enviar a foto.', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir foto?'),
        content: const Text('Esta foto será removida da galeria.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await SupabaseService.deleteQuestPhoto(url);
    if (ok) {
      setState(() => _urls = _urls.where((u) => u != url).toList());
      _toast('Foto excluída.');
    } else {
      _toast('Não foi possível excluir a foto.', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.destructive : Theme.of(context).colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasReal = _urls.isNotEmpty;
    final display = hasReal ? _urls : _fallbackPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fotos da Comunidade',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            TextButton.icon(
              onPressed: _uploading ? null : _addPhoto,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(LucideIcons.plus, size: 14),
              label: Text(_uploading ? 'Enviando...' : 'Adicionar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.coral,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (!hasReal && !_loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Seja o primeiro a compartilhar uma foto de ${widget.district.district}.',
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final src = display[i];
              final isNetwork = src.startsWith('http');
              final canDelete = hasReal &&
                  isNetwork &&
                  ref.read(currentUserProvider) != null;
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => PhotoGalleryDialog.show(context,
                        photos: display, initialIndex: i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: isNetwork
                          ? Image.network(src,
                              width: 112, height: 112, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _brokenThumb())
                          : Image.asset(src,
                              width: 112, height: 112, fit: BoxFit.cover),
                    ),
                  ),
                  if (canDelete)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deletePhoto(src),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.trash2,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _brokenThumb() => Container(
        width: 112,
        height: 112,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(LucideIcons.imageOff,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// Botão de favoritar/desfavoritar a cidade atual. Grava no Firestore.
class _FavoriteCityButton extends ConsumerWidget {
  final String cityName;
  const _FavoriteCityButton({required this.cityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final favNames = ref.watch(favoriteCityNamesProvider);
    final isFav = favNames.contains(cityName.trim().toLowerCase());
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: user == null
            ? null
            : () async {
                await favoriteCityService.toggle(user.uid, cityName, isFav);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isFav
                        ? '$cityName removida dos favoritos'
                        : '$cityName adicionada aos favoritos ❤️'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            LucideIcons.heart,
            size: 18,
            color: isFav ? AppColors.coral : cs.onSurfaceVariant,
          ),
        ),
      ),
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
