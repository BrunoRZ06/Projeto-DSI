import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../models/travel_plan.dart';
import '../services/city_dataset_service.dart';
import '../services/travel_plan_service.dart';
import '../theme/app_theme.dart';
import 'travel_budget_page.dart';

class MyTravelPlansPage extends StatefulWidget {
  const MyTravelPlansPage({super.key});

  @override
  State<MyTravelPlansPage> createState() => _MyTravelPlansPageState();
}

class _MyTravelPlansPageState extends State<MyTravelPlansPage> {
  final _travelPlanService = TravelPlanService();

  List<TravelPlan>? _plans;
  bool _loading = true;
  bool _openingPlan = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plans = await _travelPlanService.getUserPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<DistrictScore> _resolveDistrict(TravelPlan plan) async {
    final districts = await cityDatasetService.rankDistrictsForCity(plan.city);

    for (final district in districts) {
      if (district.district.toLowerCase() == plan.district.toLowerCase()) {
        return district;
      }
    }

    for (final district in districts) {
      final saved = plan.district.toLowerCase();
      final candidate = district.district.toLowerCase();
      if (candidate.contains(saved) || saved.contains(candidate)) {
        return district;
      }
    }

    if (districts.isNotEmpty) return districts.first;

    return DistrictScore(
      city: plan.city,
      district: plan.district,
      latitude: 0,
      longitude: 0,
      leisureScore: 50,
      safetyScore: 50,
      centerDistanceScore: 50,
      premiumPriceScore: 50,
      overallScore: 50,
      distanceCityCenter: 5,
      attractionIndex: 3,
      restaurantIndex: 3,
      crimeIndex: 50,
      safetyIndex: 50,
      averagePrice: plan.estimatedTotal / (plan.days <= 0 ? 1 : plan.days),
      sampleSize: 0,
    );
  }

  Future<void> _openPlan(TravelPlan plan) async {
    if (_openingPlan) return;

    setState(() => _openingPlan = true);
    try {
      final district = await _resolveDistrict(plan);
      if (!mounted) return;

      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TravelBudgetPage(
            district: district,
            existingPlan: plan,
          ),
        ),
      );

      if (updated == true && mounted) {
        await _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        _toast('Erro ao abrir planejamento: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _openingPlan = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? AppColors.destructive : Theme.of(context).colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatCurrency(double value) => 'R\$ ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Meus Planejamentos'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildBody(),
              ),
            ),
          ),
          if (_openingPlan)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleAlert,
                size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar planejamentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadPlans,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
            ),
          ],
        ),
      );
    }

    final plans = _plans ?? const <TravelPlan>[];

    if (plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wallet,
                size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Nenhum planejamento salvo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um planejamento de gastos pelo mapa, selecionando um bairro e clicando em "Planejar Gastos".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final plan = plans[index];
        return _TravelPlanListTile(
          city: plan.city,
          district: plan.district,
          estimatedTotal: _formatCurrency(plan.estimatedTotal),
          createdAt: _formatDate(plan.createdAt),
          onTap: _openingPlan ? null : () => _openPlan(plan),
        );
      },
    );
  }
}

class _TravelPlanListTile extends StatelessWidget {
  final String city;
  final String district;
  final String estimatedTotal;
  final String createdAt;
  final VoidCallback? onTap;

  const _TravelPlanListTile({
    required this.city,
    required this.district,
    required this.estimatedTotal,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.wallet, size: 18, color: AppColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    district,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Criado em $createdAt',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              estimatedTotal,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
