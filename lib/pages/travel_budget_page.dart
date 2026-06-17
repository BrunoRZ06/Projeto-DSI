import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../theme/app_theme.dart';

class TravelBudgetPage extends StatelessWidget {
  final DistrictScore district;

  const TravelBudgetPage({super.key, required this.district});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planejar Gastos - ${district.district}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orçamento Estimado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${district.district}, ${district.city}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _BudgetCard(
                icon: LucideIcons.bed,
                label: 'Hospedagem (noite)',
                value: 'R\$ ${district.averagePrice.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.utensils,
                label: 'Alimentação (dia)',
                value: 'R\$ ${(_calculateFoodCost(district) * 5).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.train,
                label: 'Transporte (dia)',
                value: 'R\$ ${(_calculateTransportCost(district) * 5).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.ticket,
                label: 'Lazer/Atividades (dia)',
                value: 'R\$ ${(_calculateLeisureCost(district) * 5).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Estimado (Dia)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_calculateTotal(district).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Dicas de Economia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _TipCard(
                icon: LucideIcons.piggyBank,
                tip: 'Reserve hospedagem com antecedência para economizar até 30%.',
              ),
              const SizedBox(height: 8),
              _TipCard(
                icon: LucideIcons.utensilsCrossed,
                tip: 'Prefira restaurantes locais para refeições mais baratas e autênticas.',
              ),
              const SizedBox(height: 8),
              _TipCard(
                icon: LucideIcons.footprints,
                tip: 'O bairro tem alta caminhabilidade - aproveite para se deslocar a pé.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateFoodCost(DistrictScore d) => 30 + (d.restaurantIndex * 10);
  double _calculateTransportCost(DistrictScore d) => 15 + (d.distanceCityCenter * 2);
  double _calculateLeisureCost(DistrictScore d) => 20 + (d.leisureScore * 8);
  double _calculateTotal(DistrictScore d) {
    return d.averagePrice +
        (_calculateFoodCost(d) * 5) +
        (_calculateTransportCost(d) * 5) +
        (_calculateLeisureCost(d) * 5);
  }
}

class _BudgetCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BudgetCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.coral),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _TipCard({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.coralDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.coralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}