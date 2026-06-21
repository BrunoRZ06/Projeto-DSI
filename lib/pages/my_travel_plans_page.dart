import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../models/travel_plan.dart';
import '../services/city_dataset_service.dart';
import '../services/travel_plan_service.dart';
import '../theme/app_theme.dart';
import 'travel_budget_page.dart';

enum _TravelPlanSortOption {
  newest,
  oldest,
  highestTotal,
  lowestTotal,
}

class MyTravelPlansPage extends StatefulWidget {
  const MyTravelPlansPage({super.key});

  @override
  State<MyTravelPlansPage> createState() => _MyTravelPlansPageState();
}

class _MyTravelPlansPageState extends State<MyTravelPlansPage> {
  final _travelPlanService = TravelPlanService();
  final _searchController = TextEditingController();

  List<TravelPlan>? _plans;
  bool _loading = true;
  bool _openingPlan = false;
  bool _deletingPlan = false;
  String? _error;
  String _searchQuery = '';
  _TravelPlanSortOption _sortOption = _TravelPlanSortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _deletePlan(TravelPlan plan) async {
    if (_deletingPlan) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Planejamento'),
        content:
            const Text('Tem certeza que deseja excluir este planejamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.destructive,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingPlan = true);
    try {
      await _travelPlanService.deletePlan(plan.id!);
      if (!mounted) return;
      await _loadPlans();
      _toast('Planejamento excluído com sucesso');
    } catch (e) {
      if (mounted) {
        _toast('Erro ao excluir planejamento: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _deletingPlan = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error
          ? AppColors.destructive
          : Theme.of(context).colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatCurrency(double value) => 'R\$ ${value.toStringAsFixed(0)}';

  List<TravelPlan> _applyFilters(List<TravelPlan> plans) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = plans.where((plan) {
      if (query.isEmpty) return true;
      return plan.city.toLowerCase().contains(query) ||
          plan.district.toLowerCase().contains(query);
    }).toList();

    switch (_sortOption) {
      case _TravelPlanSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _TravelPlanSortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _TravelPlanSortOption.highestTotal:
        filtered.sort((a, b) => b.estimatedTotal.compareTo(a.estimatedTotal));
      case _TravelPlanSortOption.lowestTotal:
        filtered.sort((a, b) => a.estimatedTotal.compareTo(b.estimatedTotal));
    }

    return filtered;
  }

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
          if (_openingPlan || _deletingPlan)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.coral, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleAlert,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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

    final visiblePlans = _applyFilters(plans);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: visiblePlans.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        if (index == 0) {
          return Column(
            children: [
              _TravelPlanFilters(
                controller: _searchController,
                sortOption: _sortOption,
                onSearchChanged: (value) =>
                    setState(() => _searchQuery = value),
                onSortChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortOption = value);
                },
              ),
              if (visiblePlans.isEmpty) ...[
                const SizedBox(height: 32),
                _FilteredEmptyState(
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ],
            ],
          );
        }

        final plan = visiblePlans[index - 1];
        return _TravelPlanListTile(
          plan: plan,
          estimatedTotal: _formatCurrency(plan.estimatedTotal),
          createdAt: _formatDate(plan.createdAt),
          onTap: _openingPlan || _deletingPlan ? null : () => _openPlan(plan),
          onDelete: _deletingPlan ? null : () => _deletePlan(plan),
        );
      },
    );
  }
}

class _TravelPlanFilters extends StatelessWidget {
  final TextEditingController controller;
  final _TravelPlanSortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_TravelPlanSortOption?> onSortChanged;

  const _TravelPlanFilters({
    required this.controller,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Buscar por cidade ou bairro',
            prefixIcon: Icon(LucideIcons.search, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<_TravelPlanSortOption>(
          initialValue: sortOption,
          onChanged: onSortChanged,
          decoration: const InputDecoration(
            labelText: 'Ordenar por',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: _TravelPlanSortOption.newest,
              child: Text('Mais recentes'),
            ),
            DropdownMenuItem(
              value: _TravelPlanSortOption.oldest,
              child: Text('Mais antigos'),
            ),
            DropdownMenuItem(
              value: _TravelPlanSortOption.highestTotal,
              child: Text('Maior custo'),
            ),
            DropdownMenuItem(
              value: _TravelPlanSortOption.lowestTotal,
              child: Text('Menor custo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredEmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          LucideIcons.search,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'Nenhum planejamento encontrado',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onClear,
          child: const Text('Limpar filtro'),
        ),
      ],
    );
  }
}

class _TravelPlanListTile extends StatelessWidget {
  final TravelPlan plan;
  final String estimatedTotal;
  final String createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TravelPlanListTile({
    required this.plan,
    required this.estimatedTotal,
    required this.createdAt,
    this.onTap,
    this.onDelete,
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
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
              child: const Icon(LucideIcons.wallet,
                  size: 18, color: AppColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.city,
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
                    plan.district,
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
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
