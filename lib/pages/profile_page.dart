import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../models/favorite_city.dart';
import '../providers/app_repository_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Popula o nome a partir do cache do AppRepository.
  /// Chamado sempre que repositoryVersionProvider muda (dados chegaram).
  void _syncFromRepo() {
    final profile = ref.read(appRepositoryProvider).profile;
    if (profile != null && _nameController.text.isEmpty) {
      _nameController.text = profile.displayName;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(appRepositoryProvider).updateDisplayName(
            _nameController.text.trim(),
          );
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
      backgroundColor: error ? AppColors.destructive : AppColors.foreground,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói quando o repositório termina de carregar ou atualizar dados.
    ref.watch(repositoryVersionProvider);
    _syncFromRepo();

    final user = ref.watch(currentUserProvider);
    final repo = ref.watch(appRepositoryProvider);
    final questCount = repo.questProgress?.totalCompleted ?? 0;
    final List<FavoriteCity> favCities = repo.favoriteCities.toList();

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
                        color: AppColors.foreground)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.user,
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
                                  onPressed: _saving ? null : _save,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.coral,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(LucideIcons.save, size: 16),
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
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.foreground),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _editing = true),
                                  child: const Icon(LucideIcons.pencil,
                                      size: 14,
                                      color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          Text(user?.email ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground)),
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
                      value: questCount.toString(),
                      label: 'Missões Completas',
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
                const Text('Cidades Favoritas',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground)),
                const SizedBox(height: 12),
                if (favCities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Nenhuma cidade salva ainda. Busque uma cidade no quiz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.mutedForeground),
                    ),
                  )
                else
                  Column(
                    children: favCities
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.mapPin,
                                        size: 16, color: AppColors.coral),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.district.isEmpty
                                                ? c.cityName
                                                : c.district,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.foreground),
                                          ),
                                          if (c.district.isNotEmpty)
                                            Text(c.cityName,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .mutedForeground)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 32),
                const Text('Progresso das Missões',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$questCount missões completadas',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground)),
                      const SizedBox(height: 4),
                      const Text(
                        'Continue explorando para ganhar mais XP!',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider).signOut(),
                  icon: const Icon(LucideIcons.logOut, size: 16),
                  label: const Text('Sair da Conta'),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.coral),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mutedForeground),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}