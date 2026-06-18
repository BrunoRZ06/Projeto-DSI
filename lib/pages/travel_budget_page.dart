import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/district_score.dart';
import '../models/travel_plan.dart';
import '../services/travel_plan_service.dart';
import '../theme/app_theme.dart';

class TravelBudgetPage extends StatefulWidget {
  final DistrictScore district;
  final TravelPlan? existingPlan;

  const TravelBudgetPage({
    super.key,
    required this.district,
    this.existingPlan,
  });

  @override
  State<TravelBudgetPage> createState() => _TravelBudgetPageState();
}

class _TravelBudgetPageState extends State<TravelBudgetPage> {
  final _travelPlanService = TravelPlanService();

  late final TextEditingController _daysCtrl;
  late final TextEditingController _peopleCtrl;
  late final TextEditingController _mealsPerDayCtrl;
  late final TextEditingController _taxiKmCtrl;
  late final TextEditingController _activitiesBudgetCtrl;

  bool _saving = false;

  bool get _isEdit => widget.existingPlan != null;

  DistrictScore get district => widget.district;

  String _formatInputNumber(num value) {
    if (value is int) return value.toString();
    final asDouble = value.toDouble();
    return asDouble == asDouble.roundToDouble()
        ? asDouble.toInt().toString()
        : asDouble.toString();
  }

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;

    _daysCtrl = TextEditingController(
      text: plan != null ? plan.days.toString() : '3',
    );
    _peopleCtrl = TextEditingController(
      text: plan != null ? plan.people.toString() : '2',
    );
    _mealsPerDayCtrl = TextEditingController(
      text: plan != null ? plan.mealsPerDay.toString() : '5',
    );
    _taxiKmCtrl = TextEditingController(
      text: plan != null ? _formatInputNumber(plan.taxiKmPerDay) : '5',
    );
    _activitiesBudgetCtrl = TextEditingController(
      text: plan != null
          ? _formatInputNumber(plan.activitiesBudget)
          : (_calculateLeisureCost(district) * 5).toStringAsFixed(0),
    );

    for (final ctrl in [
      _daysCtrl,
      _peopleCtrl,
      _mealsPerDayCtrl,
      _taxiKmCtrl,
      _activitiesBudgetCtrl,
    ]) {
      ctrl.addListener(_onFieldsChanged);
    }
  }

  @override
  void dispose() {
    for (final ctrl in [
      _daysCtrl,
      _peopleCtrl,
      _mealsPerDayCtrl,
      _taxiKmCtrl,
      _activitiesBudgetCtrl,
    ]) {
      ctrl
        ..removeListener(_onFieldsChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onFieldsChanged() => setState(() {});

  int get _days => int.tryParse(_daysCtrl.text) ?? 0;
  int get _people => int.tryParse(_peopleCtrl.text) ?? 0;
  int get _mealsPerDay => int.tryParse(_mealsPerDayCtrl.text) ?? 0;
  double get _taxiKmPerDay => double.tryParse(_taxiKmCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _activitiesBudget =>
      double.tryParse(_activitiesBudgetCtrl.text.replaceAll(',', '.')) ?? 0;

  double _calculateFoodCost(DistrictScore d) => 30 + (d.restaurantIndex * 10);

  double _calculateTransportCost(DistrictScore d) => 15 + (d.distanceCityCenter * 2);

  double _calculateLeisureCost(DistrictScore d) => 20 + (d.leisureScore * 8);

  double _foodDaily(DistrictScore d) =>
      _calculateFoodCost(d) * _mealsPerDay * _people;

  double _transportDaily(DistrictScore d) =>
      _calculateTransportCost(d) * (_taxiKmPerDay / 5.0);

  double _dailyTotal(DistrictScore d) =>
      district.averagePrice +
      _foodDaily(d) +
      _transportDaily(d) +
      _activitiesBudget;

  double _tripTotal(DistrictScore d) =>
      (district.averagePrice * _days) +
      (_foodDaily(d) * _days) +
      (_transportDaily(d) * _days) +
      (_activitiesBudget * _days);

  Future<void> _savePlan() async {
    if (_saving) return;

    if (_days <= 0 || _people <= 0 || _mealsPerDay <= 0) {
      _toast('Preencha dias, pessoas e refeições com valores válidos.', error: true);
      return;
    }
    if (_taxiKmPerDay < 0 || _activitiesBudget < 0) {
      _toast('Km de táxi e orçamento de atividades não podem ser negativos.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final planId = widget.existingPlan!.id;
        if (planId == null || planId.isEmpty) {
          throw Exception('Planejamento inválido');
        }

        await _travelPlanService.updatePlan(
          planId: planId,
          city: district.city,
          district: district.district,
          days: _days,
          people: _people,
          mealsPerDay: _mealsPerDay,
          taxiKmPerDay: _taxiKmPerDay,
          activitiesBudget: _activitiesBudget,
          estimatedTotal: _tripTotal(district),
        );
        _toast('Planejamento atualizado com sucesso!');
        if (mounted) Navigator.of(context).pop(true);
      } else {
        await _travelPlanService.createPlan(
          city: district.city,
          district: district.district,
          days: _days,
          people: _people,
          mealsPerDay: _mealsPerDay,
          taxiKmPerDay: _taxiKmPerDay,
          activitiesBudget: _activitiesBudget,
          estimatedTotal: _tripTotal(district),
        );
        _toast('Planejamento salvo com sucesso!');
      }
    } catch (e) {
      _toast(
        _isEdit
            ? 'Erro ao atualizar planejamento: $e'
            : 'Erro ao salvar planejamento: $e',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final d = district;

    return Scaffold(
      appBar: AppBar(
        title: Text('Planejar Gastos - ${d.district}'),
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
                '${d.district}, ${d.city}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Dados da Viagem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _TravelDataField(
                label: 'Quantidade de dias',
                controller: _daysCtrl,
                icon: LucideIcons.calendarDays,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _TravelDataField(
                label: 'Quantidade de pessoas',
                controller: _peopleCtrl,
                icon: LucideIcons.users,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _TravelDataField(
                label: 'Refeições por dia',
                controller: _mealsPerDayCtrl,
                icon: LucideIcons.utensils,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _TravelDataField(
                label: 'Km de táxi por dia',
                controller: _taxiKmCtrl,
                icon: LucideIcons.car,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                ],
              ),
              const SizedBox(height: 12),
              _TravelDataField(
                label: 'Orçamento para atividades',
                controller: _activitiesBudgetCtrl,
                icon: LucideIcons.ticket,
                prefixText: 'R\$ ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                ],
              ),
              const SizedBox(height: 32),
              _BudgetCard(
                icon: LucideIcons.bed,
                label: 'Hospedagem (noite)',
                value: 'R\$ ${d.averagePrice.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.utensils,
                label: 'Alimentação (dia)',
                value: 'R\$ ${_foodDaily(d).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.train,
                label: 'Transporte (dia)',
                value: 'R\$ ${_transportDaily(d).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              _BudgetCard(
                icon: LucideIcons.ticket,
                label: 'Lazer/Atividades (dia)',
                value: 'R\$ ${_activitiesBudget.toStringAsFixed(0)}',
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
                      'R\$ ${_dailyTotal(d).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _savePlan,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.save),
                  label: Text(
                    _saving
                        ? (_isEdit ? 'Atualizando...' : 'Salvando...')
                        : (_isEdit ? 'Atualizar Planejamento' : 'Salvar Planejamento'),
                  ),
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
}

class _TravelDataField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? prefixText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _TravelDataField({
    required this.label,
    required this.controller,
    required this.icon,
    this.prefixText,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixIcon: Icon(icon, size: 18, color: AppColors.coral),
          ),
        ),
      ],
    );
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
              style: const TextStyle(
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
