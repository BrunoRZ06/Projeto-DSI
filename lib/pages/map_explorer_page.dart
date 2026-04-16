import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/city_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_gallery.dart';

const _photos = [
  'assets/images/neighborhood-1.jpg',
  'assets/images/neighborhood-2.jpg',
  'assets/images/neighborhood-3.jpg',
  'assets/images/neighborhood-4.jpg',
];

class MapExplorerPage extends ConsumerWidget {
  const MapExplorerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(cityProvider);
    final center = LatLng(city.lat, city.lng);

    final neighborhoods = [
      _Neighborhood('Bairro A', LatLng(city.lat + 0.012, city.lng - 0.015)),
      _Neighborhood('Bairro B', LatLng(city.lat - 0.008, city.lng + 0.018)),
      _Neighborhood('Bairro C', LatLng(city.lat + 0.015, city.lng + 0.010)),
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.bairromatch.app',
                          ),
                          MarkerLayer(
                            markers: [
                              _marker(center),
                              for (final n in neighborhoods) _marker(n.pos),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Chip(text: city.name, background: Colors.white),
                            const _Chip(
                              text: '4 locais',
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
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(top: BorderSide(color: AppColors.border)),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                city.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.coralLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '85% Match',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.coralDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(LucideIcons.star,
                                size: 14, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text('4.7 · Vibrante & Criativo · Seguro',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedForeground)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _Stat('Média/Noite', r'$50')),
                            const SizedBox(width: 12),
                            Expanded(child: _Stat('Caminhabilidade', '88')),
                            const SizedBox(width: 12),
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
                              onPressed: () => PhotoGalleryDialog.show(context,
                                  photos: _photos),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.coral,
                                  padding: EdgeInsets.zero),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Ver todas',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Marker _marker(LatLng pos) {
    return Marker(
      point: pos,
      width: 32,
      height: 32,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.coral,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(LucideIcons.mapPin, size: 16, color: Colors.white),
      ),
    );
  }
}

class _Neighborhood {
  final String name;
  final LatLng pos;
  _Neighborhood(this.name, this.pos);
}

class _Chip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.text,
    required this.background,
    this.foreground = AppColors.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.95),
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
