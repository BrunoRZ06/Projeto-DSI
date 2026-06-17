import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/budget_entry.dart';
import '../models/city_budget.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/city_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BudgetPage — lista de orçamentos por viagem
// ─────────────────────────────────────────────────────────────────────────────

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final city = ref.watch(cityProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.wallet,
                                  size: 16, color: AppColors.coral),
                              const SizedBox(width: 6),
                              const Text(
                                'GASTOS',
                                style: TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Controle de Viagem',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.foreground,
                                    ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: user == null
                            ? null
                            : () => _showNewBudgetSheet(
                                  context,
                                  ref,
                                  userId: user.uid,
                                  defaultCity: city.name,
                                  defaultDistrict: city.district ?? '',
                                ),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Nova'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Lista de orçamentos ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: budgetsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: LucideIcons.cloudOff,
                      title: 'Erro ao carregar',
                      subtitle: 'Verifique sua conexão e tente novamente.',
                    ),
                  ),
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: LucideIcons.wallet,
                          title: 'Nenhuma viagem ainda',
                          subtitle:
                              'Crie um orçamento para controlar seus gastos por cidade.',
                        ),
                      );
                    }
                    return SliverList.separated(
                      itemCount: budgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _BudgetCard(
                        budget: budgets[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BudgetDetailPage(budget: budgets[i]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewBudgetSheet(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String defaultCity,
    required String defaultDistrict,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewBudgetSheet(
        userId: userId,
      defaultCity: defaultCity,
      defaultDistrict: defaultDistrict,
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de orçamento na listagem
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetCard extends ConsumerWidget {
  final CityBudget budget;
  final VoidCallback onTap;

  const _BudgetCard({required this.budget, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = ref.watch(totalSpentProvider(budget.id));
    final percent = budget.totalBudget > 0
        ? (spent / budget.totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = spent > budget.totalBudget && budget.totalBudget > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: overBudget
                ? AppColors.destructive.withValues(alpha: 0.5)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.mapPin,
                      size: 20, color: AppColors.coral),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.cityName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      if (budget.districtName.isNotEmpty)
                        Text(
                          budget.districtName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt(spent),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: overBudget
                            ? AppColors.destructive
                            : AppColors.foreground,
                      ),
                    ),
                    Text(
                      'de ${_fmt(budget.totalBudget)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: AppColors.secondary,
                color: overBudget ? AppColors.destructive : AppColors.coral,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.durationDays} dia${budget.durationDays != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground),
                ),
                Text(
                  overBudget
                      ? '⚠️ Acima do orçamento'
                      : '${(percent * 100).toStringAsFixed(0)}% utilizado',
                  style: TextStyle(
                    fontSize: 11,
                    color: overBudget
                        ? AppColors.destructive
                        : AppColors.mutedForeground,
                    fontWeight:
                        overBudget ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela de detalhe de um orçamento
// ─────────────────────────────────────────────────────────────────────────────

class BudgetDetailPage extends ConsumerStatefulWidget {
  final CityBudget budget;
  const BudgetDetailPage({super.key, required this.budget});

  @override
  ConsumerState<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends ConsumerState<BudgetDetailPage> {
  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider(widget.budget.id));
    final spent = ref.watch(totalSpentProvider(widget.budget.id));
    final byCategory = ref.watch(spentByCategoryProvider(widget.budget.id));
    final remaining = widget.budget.totalBudget - spent;
    final overBudget = remaining < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              size: 20, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.budget.cityName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            if (widget.budget.districtName.isNotEmpty)
              Text(
                widget.budget.districtName,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsisVertical,
                size: 20, color: AppColors.foreground),
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await _confirmDelete(context);
                if (confirm == true && mounted) {
                  await ref
                      .read(budgetServiceProvider)
                      .deleteBudget(widget.budget.id);
                  if (mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2,
                        size: 16, color: AppColors.destructive),
                    SizedBox(width: 8),
                    Text('Excluir viagem',
                        style: TextStyle(color: AppColors.destructive)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Adicionar gasto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Resumo financeiro ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  // Barra de progresso grande
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: overBudget
                          ? AppColors.destructive.withValues(alpha: 0.06)
                          : AppColors.coralLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SummaryItem(
                              label: 'Orçamento',
                              value: _fmt(widget.budget.totalBudget),
                              color: AppColors.foreground,
                            ),
                            _SummaryItem(
                              label: 'Gasto',
                              value: _fmt(spent),
                              color: overBudget
                                  ? AppColors.destructive
                                  : AppColors.coral,
                            ),
                            _SummaryItem(
                              label: overBudget ? 'Excesso' : 'Disponível',
                              value: _fmt(remaining.abs()),
                              color: overBudget
                                  ? AppColors.destructive
                                  : AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: widget.budget.totalBudget > 0
                                ? (spent / widget.budget.totalBudget)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                            color: overBudget
                                ? AppColors.destructive
                                : AppColors.coral,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          overBudget
                              ? '⚠️ Você ultrapassou o orçamento!'
                              : '${widget.budget.durationDays} dias · ${((spent / (widget.budget.totalBudget > 0 ? widget.budget.totalBudget : 1)) * 100).toStringAsFixed(0)}% utilizado',
                          style: TextStyle(
                            fontSize: 12,
                            color: overBudget
                                ? AppColors.destructive
                                : AppColors.mutedForeground,
                            fontWeight: overBudget
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sugestões do dataset
                  _DatasetSuggestions(budget: widget.budget),
                  const SizedBox(height: 16),
                  // Gráfico por categoria
                  if (byCategory.isNotEmpty) ...[
                    _CategoryBreakdown(byCategory: byCategory, total: spent),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          // ── Lista de lançamentos ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Lançamentos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const Spacer(),
                  entriesAsync.when(
                    data: (entries) => Text(
                      '${entries.where((e) => !e.isSuggestion).length} itens',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          entriesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child:
                    CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
              )),
            ),
            error: (_, __) => const SliverToBoxAdapter(
                child: Center(
                    child: Text('Erro ao carregar lançamentos.',
                        style: TextStyle(color: AppColors.mutedForeground)))),
            data: (entries) {
              final real = entries.where((e) => !e.isSuggestion).toList();
              if (real.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(LucideIcons.receipt,
                              size: 32, color: AppColors.mutedForeground),
                          SizedBox(height: 8),
                          Text(
                            'Nenhum gasto registrado ainda.\nToque em "+ Adicionar gasto" para começar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: real.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _EntryTile(entry: real[i], budgetId: widget.budget.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>  _EntryFormSheet(budgetId: widget.budget.id),
      )
    ;
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir viagem'),
          content: const Text(
              'Todos os gastos desta viagem serão removidos. Continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.destructive),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );

  String _fmt(double v) =>
      'R\$ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Sugestões baseadas no dataset
// ─────────────────────────────────────────────────────────────────────────────

class _DatasetSuggestions extends StatelessWidget {
  final CityBudget budget;
  const _DatasetSuggestions({required this.budget});

  @override
  Widget build(BuildContext context) {
    if (budget.avgAccommodation <= 0 && budget.avgRestaurant <= 0) {
      return const SizedBox.shrink();
    }

    final accommodation = budget.avgAccommodation * budget.durationDays;
    final meals = budget.avgRestaurant * 3 * budget.durationDays; // 3 refeições/dia

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles,
                  size: 14, color: AppColors.coral),
              const SizedBox(width: 6),
              const Text(
                'Estimativas do Bairro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Baseado nos dados reais de ${budget.cityName}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          if (budget.avgAccommodation > 0)
            _SuggestionRow(
              emoji: '🏨',
              label: 'Hospedagem (${budget.durationDays}n)',
              value: accommodation,
              perUnit: '${_fmt(budget.avgAccommodation)}/noite',
            ),
          if (budget.avgRestaurant > 0) ...[
            const SizedBox(height: 8),
            _SuggestionRow(
              emoji: '🍽️',
              label: 'Alimentação (${budget.durationDays}d)',
              value: meals,
              perUnit: '${_fmt(budget.avgRestaurant)}/refeição',
            ),
          ],
          if (budget.avgAccommodation > 0 || budget.avgRestaurant > 0) ...[
            const Divider(height: 20, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimativa total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
                Text(
                  _fmt(accommodation + meals),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(0)}';
}

class _SuggestionRow extends StatelessWidget {
  final String emoji;
  final String label;
  final double value;
  final String perUnit;

  const _SuggestionRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.perUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.foreground)),
              Text(perUnit,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.mutedForeground)),
            ],
          ),
        ),
        Text(
          'R\$ ${value.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breakdown por categoria
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final Map<ExpenseCategory, double> byCategory;
  final double total;

  const _CategoryBreakdown(
      {required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Por Categoria',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground)),
          const SizedBox(height: 12),
          for (final entry in sorted) ...[
            _CategoryRow(
                category: entry.key,
                amount: entry.value,
                total: total),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double total;

  const _CategoryRow(
      {required this.category, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(category.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.foreground)),
            ),
            Text(
              'R\$ ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              child: Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.mutedForeground),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.border,
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de lançamento individual
// ─────────────────────────────────────────────────────────────────────────────

class _EntryTile extends ConsumerWidget {
  final BudgetEntry entry;
  final String budgetId;

  const _EntryTile({required this.entry, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(LucideIcons.trash2,
            color: AppColors.destructive, size: 20),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remover lançamento'),
            content: Text('Remover "${entry.description}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remover'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(budgetServiceProvider).deleteEntry(entry.id),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _EntryFormSheet(
            budgetId: budgetId,
            existing: entry,
          )
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(entry.category.emoji,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.description,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${entry.category.label} · ${_dateLabel(entry.date)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              Text(
                'R\$ ${entry.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: novo orçamento
// ─────────────────────────────────────────────────────────────────────────────

class _NewBudgetSheet extends ConsumerStatefulWidget {
  final String userId;
  final String defaultCity;
  final String defaultDistrict;

  const _NewBudgetSheet({
    required this.userId,
    required this.defaultCity,
    required this.defaultDistrict,
  });

  @override
  ConsumerState<_NewBudgetSheet> createState() => _NewBudgetSheetState();
}

class _NewBudgetSheetState extends ConsumerState<_NewBudgetSheet> {
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '7');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cityCtrl.text = widget.defaultCity;
    _districtCtrl.text = widget.defaultDistrict;
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _budgetCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final city = _cityCtrl.text.trim();
    final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', '.'));
    final days = int.tryParse(_daysCtrl.text);

    if (city.isEmpty || budget == null || budget <= 0 || days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha cidade, orçamento e dias corretamente.'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Estima médias do dataset baseando no priceTotal da cidade
      // (simplificado: usa 40% do price_total como hospedagem, 10% como refeição)
      // O dev pode refinar isso consultando o dataset real
      const avgAccommodation = 0.0; // placeholder — ver nota no INSTRUCOES.md
      const avgRestaurant = 0.0;

      final newBudget = CityBudget(
        id: '',
        userId: widget.userId,
        cityName: city,
        districtName: _districtCtrl.text.trim(),
        totalBudget: budget,
        durationDays: days,
        avgAccommodation: avgAccommodation,
        avgRestaurant: avgRestaurant,
        createdAt: DateTime.now(),
      );

      await ref.read(budgetServiceProvider).createBudget(newBudget);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: 'Nova Viagem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(label: 'Cidade', controller: _cityCtrl, hint: 'Ex: Lisboa'),
          const SizedBox(height: 12),
          _SheetField(
              label: 'Bairro (opcional)',
              controller: _districtCtrl,
              hint: 'Ex: Alfama'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _SheetField(
                  label: 'Orçamento total (R\$)',
                  controller: _budgetCtrl,
                  hint: '5000',
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: 'Dias',
                  controller: _daysCtrl,
                  hint: '7',
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Criar orçamento'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: adicionar / editar lançamento
// ─────────────────────────────────────────────────────────────────────────────

class _EntryFormSheet extends ConsumerStatefulWidget {
  final String budgetId;
  final BudgetEntry? existing;

  const _EntryFormSheet({required this.budgetId, this.existing});

  @override
  ConsumerState<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<_EntryFormSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _category = e.category;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.'));

    if (desc.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha descrição e valor corretamente.'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(budgetServiceProvider);
      if (widget.existing != null) {
        await service.updateEntry(
          widget.existing!.id,
          widget.existing!.copyWith(
            description: desc,
            amount: amount,
            category: _category,
            date: _date,
          ),
        );
      } else {
        await service.addEntry(
          BudgetEntry(
            id: '',
            cityBudgetId: widget.budgetId,
            description: desc,
            amount: amount,
            category: _category,
            date: _date,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: widget.existing == null ? 'Novo Gasto' : 'Editar Gasto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(
            label: 'Descrição',
            controller: _descCtrl,
            hint: 'Ex: Jantar no centro',
          ),
          const SizedBox(height: 12),
          _SheetField(
            label: 'Valor (R\$)',
            controller: _amountCtrl,
            hint: '0,00',
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text(
            'Categoria',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((cat) {
              final selected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.coral
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? AppColors.coral
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '${cat.emoji} ${cat.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : AppColors.foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Seletor de data simples
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.coral,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _date = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar,
                      size: 16, color: AppColors.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.foreground),
                  ),
                  const Spacer(),
                  const Text('Alterar',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.existing == null ? 'Salvar gasto' : 'Atualizar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares reutilizáveis
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.mutedForeground),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.mutedForeground),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
