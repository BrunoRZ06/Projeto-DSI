import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/city_location.dart';
import '../models/itinerary.dart';
import '../models/travel_plan.dart';
import '../models/user_quest.dart';
import '../providers/auth_provider.dart';
import '../providers/city_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/itinerary_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_photos_provider.dart';
import '../providers/user_quest_provider.dart';
import '../services/neighborhoods_dataset.dart';
import '../services/supabase_service.dart';
import '../services/travel_plan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/photo_gallery.dart';
import 'match_history_page.dart';
import 'my_travel_plans_page.dart';
 
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
 
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}
 
class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _favoriteSearchController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _loaded = false;
  String _favoriteSearchQuery = '';

  final _travelPlanService = TravelPlanService();
  List<TravelPlan> _travelPlans = [];
  bool _travelPlansLoading = false;
  String? _travelPlansError;
 
  int _totalXp = 0;
 
  @override
  void dispose() {
    _nameController.dispose();
    _favoriteSearchController.dispose();
    super.dispose();
  }
 
  Future<void> _load(String userId) async {
    if (_loaded) return;
    _loaded = true;
 
    try {
      final service = ref.read(firestoreServiceProvider);
 
      // Perfil
      final profile = await service.getProfile(userId);
      if (profile != null && profile['display_name'] != null) {
        _nameController.text = profile['display_name'] as String;
      }
 
      // Quests completadas
      final quests = await service.getCompletedQuests(userId);
      _totalXp = quests.fold<int>(
        0,
        (sum, q) => sum + ((q['xp_earned'] as int?) ?? 0),
      );
 
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('ProfilePage _load error: $e');
    }

    await _loadTravelPlans();
  }

  Future<void> _loadTravelPlans() async {
    setState(() {
      _travelPlansLoading = true;
      _travelPlansError = null;
    });

    try {
      final plans = await _travelPlanService.getUserPlans();
      if (!mounted) return;
      setState(() {
        _travelPlans = plans;
        _travelPlansLoading = false;
      });
    } catch (e) {
      debugPrint('ProfilePage _loadTravelPlans error: $e');
      if (!mounted) return;
      setState(() {
        _travelPlansError = e.toString();
        _travelPlansLoading = false;
      });
    }
  }

  Future<void> _openAllTravelPlans() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyTravelPlansPage()),
    );
    if (mounted) _loadTravelPlans();
  }

  Future<void> _openMatchHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MatchHistoryPage()),
    );
  }

  String _formatCurrency(double value) => 'R\$ ${value.toStringAsFixed(0)}';
 
  Future<void> _save(String userId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateProfile(userId, {'display_name': _nameController.text});
      _toast('Perfil atualizado!');
      setState(() => _editing = false);
    } catch (e) {
      debugPrint('ProfilePage _save error: $e');
      _toast('Erro ao salvar perfil', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
 
  /// Abre a aba de missões já na cidade escolhida (define a cidade global).
  void _openCityQuests(String city) {
    final center = cityCenterFor(city);
    final current = ref.read(cityProvider);
    ref.read(cityProvider.notifier).setCity(CityLocation(
          name: city,
          lat: center?.lat ?? current.lat,
          lng: center?.lng ?? current.lng,
        ));
    ref.read(activeTabProvider.notifier).setTab(3); // aba Missões
  }

  /// Exclui uma foto: apaga o arquivo no Supabase, limpa a referência em
  /// missões que a usem e atualiza a galeria.
  Future<void> _deletePhoto(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir foto?'),
        content: const Text('Esta foto será removida permanentemente.'),
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
    if (!ok) {
      _toast('Não foi possível excluir a foto.', error: true);
      return;
    }
    await ref.read(userQuestsProvider.notifier).clearPhotoByUrl(url);
    ref.invalidate(userPhotosProvider);
    _toast('Foto excluída.');
  }

  /// Galeria com todas as fotos enviadas pelo usuário (missões + comunidade).
  Widget _buildPhotoGallery() {
    final photosAsync = ref.watch(userPhotosProvider);
    final urls = photosAsync.asData?.value ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minhas Fotos',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        if (urls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Você ainda não enviou fotos. Adicione fotos às suas missões ou à galeria da comunidade!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => PhotoGalleryDialog.show(context,
                        photos: urls, initialIndex: i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        urls[i],
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(LucideIcons.imageOff,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deletePhoto(urls[i]),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.trash2,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Progresso das missões dividido por cidade. Cada mini card mostra
  /// completas/total e leva para as missões daquela cidade ao ser tocado.
  Widget _buildCityProgress() {
    final completed =
        ref.watch(completedQuestsProvider).asData?.value ?? const <String>[];
    final quests =
        ref.watch(userQuestsProvider).asData?.value ?? const <UserQuest>[];

    // Agrupa as missões do usuário por cidade.
    final byCity = <String, List<UserQuest>>{};
    for (final q in quests) {
      final city = (q.cityName == null || q.cityName!.trim().isEmpty)
          ? 'Sem cidade'
          : q.cityName!;
      byCity.putIfAbsent(city, () => []).add(q);
    }
    final cities = byCity.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progresso por Cidade',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        if (cities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Crie missões em uma cidade para acompanhar seu progresso aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final city in cities)
                _CityProgressCard(
                  city: city == 'Sem cidade' ? 'Sem cidade' : city,
                  done: byCity[city]!.where((q) => completed.contains(q.id)).length,
                  total: byCity[city]!.length,
                  onTap: city == 'Sem cidade' ? null : () => _openCityQuests(city),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(user.uid));
    }

    final favCities = ref.watch(favoriteCitiesProvider).asData?.value ?? const [];
    final favoriteQuery = _favoriteSearchQuery.trim().toLowerCase();
    final visibleFavCities = favoriteQuery.isEmpty
        ? favCities
        : favCities
            .where((city) => city.cityName.toLowerCase().contains(favoriteQuery))
            .toList();
 
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meu Perfil',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.user,
                          size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_editing)
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _nameController,
                                    hint: 'Seu nome',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _saving || user == null
                                      ? null
                                      : () => _save(user.uid),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.coral,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: Icon(LucideIcons.save, size: 16),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _nameController.text.isEmpty
                                        ? 'Sem nome'
                                        : _nameController.text,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _editing = true),
                                  child: Icon(LucideIcons.pencil,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          Text(user?.email ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                      icon: LucideIcons.trophy,
                      value: _totalXp.toString(),
                      label: 'XP Total',
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                      icon: LucideIcons.mapPin,
                      value: favCities.length.toString(),
                      label: 'Cidades Exploradas',
                    )),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Cidades Favoritas',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12),
                if (favCities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Nenhuma cidade salva ainda. Busque uma cidade no quiz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _favoriteSearchController,
                        onChanged: (value) =>
                            setState(() => _favoriteSearchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Filtrar cidade favorita',
                          prefixIcon: Icon(LucideIcons.search, size: 18),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (visibleFavCities.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Nenhuma cidade encontrada para este filtro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ...visibleFavCities
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.mapPin,
                                            size: 16, color: AppColors.coral),
                                        const SizedBox(width: 12),
                                        Text(c.cityName,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                    ],
                  ),
                const SizedBox(height: 32),
                _buildPhotoGallery(),
                // ── Meus Roteiros ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meus Roteiros',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(activeTabProvider.notifier).setTab(2),
                      child: Text(
                        'Ver todos',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final itinerariesAsync = ref.watch(itineraryProvider);
                    return itinerariesAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                              color: AppColors.coral, strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Erro ao carregar roteiros.',
                          style: TextStyle(
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      data: (itineraries) {
                        if (itineraries.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Nenhum roteiro criado ainda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () => ref.read(activeTabProvider.notifier).setTab(2),
                                  icon: Icon(LucideIcons.plus, size: 14),
                                  label: Text('Criar meu primeiro roteiro'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.coral),
                                ),
                              ],
                            ),
                          );
                        }

                        // Mostra até 3 roteiros recentes
                        final recent = itineraries.take(3).toList();
                        return Column(
                          children: [
                            ...recent.map((it) => _ItineraryTile(
                                  itinerary: it,
                                  onTap: () => ref.read(activeTabProvider.notifier).setTab(2),
                                )),
                            if (itineraries.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => ref.read(activeTabProvider.notifier).setTab(2),
                                  child: Text(
                                    '+ ${itineraries.length - 3} roteiro(s) a mais',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Histórico de Matches',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                _ProfileActionTile(
                  icon: LucideIcons.sparkles,
                  title: 'Ver matches recentes',
                  subtitle: 'Reabra cidades e bairros recomendados pelo quiz',
                  onTap: _openMatchHistory,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meus Planejamentos',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    GestureDetector(
                      onTap: _openAllTravelPlans,
                      child: Text(
                        'Ver todos',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_travelPlansLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                          color: AppColors.coral, strokeWidth: 2),
                    ),
                  )
                else if (_travelPlansError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Erro ao carregar planejamentos.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else if (_travelPlans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Nenhum planejamento salvo ainda. Planeje gastos pelo mapa!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Column(
                    children: [
                      ..._travelPlans.take(3).map(
                            (plan) => _TravelPlanTile(
                              city: plan.city,
                              district: plan.district,
                              estimatedTotal: _formatCurrency(plan.estimatedTotal),
                              onTap: _openAllTravelPlans,
                            ),
                          ),
                      if (_travelPlans.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: _openAllTravelPlans,
                            child: Text(
                              '+ ${_travelPlans.length - 3} planejamento(s) a mais',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 32),
                _buildCityProgress(),
                const SizedBox(height: 32),
                // ── Acessibilidade ───────────────────────────────────────
                Text(
                  'Acessibilidade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final darkAsync = ref.watch(darkModeProvider);
                    final isDark = darkAsync.value ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                                : AppColors.coralLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDark ? LucideIcons.moon : LucideIcons.sun,
                            size: 18,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : AppColors.coral,
                          ),
                        ),
                        title: Text(
                          'Modo Noturno',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          isDark ? 'Tema escuro ativado' : 'Tema claro ativado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) =>
                              ref.read(darkModeProvider.notifier).toggle(),
                          activeColor: AppColors.coral,
                        ),
                        onTap: () =>
                            ref.read(darkModeProvider.notifier).toggle(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider).signOut(),
                  icon: Icon(LucideIcons.logOut, size: 16),
                  label: Text('Sair da Conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: BorderSide(
                        color: AppColors.destructive.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
class _TravelPlanTile extends StatelessWidget {
  final String city;
  final String district;
  final String estimatedTotal;
  final VoidCallback onTap;

  const _TravelPlanTile({
    required this.city,
    required this.district,
    required this.estimatedTotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
                child: Icon(LucideIcons.wallet, size: 18, color: AppColors.coral),
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
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      district,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                estimatedTotal,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.coral),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItineraryTile extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onTap;

  const _ItineraryTile({required this.itinerary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
                child: Icon(LucideIcons.mapPin,
                    size: 18, color: AppColors.coral),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itinerary.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${itinerary.cityName} · ${itinerary.placeCount} local${itinerary.placeCount != 1 ? 'is' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
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
              child: Icon(icon, size: 18, color: AppColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CityProgressCard extends StatelessWidget {
  final String city;
  final int done;
  final int total;
  final VoidCallback? onTap;

  const _CityProgressCard({
    required this.city,
    required this.done,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: AppColors.coral),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                ),
                if (onTap != null)
                  Icon(LucideIcons.chevronRight, size: 14, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: cs.surface,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 6),
            Text('$done/$total completas',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
 
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.coral),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
