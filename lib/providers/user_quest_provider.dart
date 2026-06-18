import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_quest.dart';
import '../providers/auth_provider.dart';
import '../services/quest_service.dart';

final userQuestsProvider = NotifierProvider<UserQuestNotifier, AsyncValue<List<UserQuest>>>(
  UserQuestNotifier.new,
);

class UserQuestNotifier extends Notifier<AsyncValue<List<UserQuest>>> {
  String? _loadedUid;

  @override
  AsyncValue<List<UserQuest>> build() {
    // Initial empty state and start listening to auth changes
    _init();
    return const AsyncValue.data(<UserQuest>[]);
  }

  void _init() {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        _loadedUid = null;
        state = const AsyncValue.data(<UserQuest>[]);
        return;
      }
      // Carrega sempre que o usuário logado for diferente do já carregado —
      // robusto ao `fireImmediately` (que pode disparar com previous == next).
      if (_loadedUid != next.uid) {
        _loadedUid = next.uid;
        load(next.uid);
      }
    }, fireImmediately: true);
  }

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    try {
      final quests = await questService.fetchByUser(userId);
      state = AsyncValue.data(quests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(UserQuest quest) async {
    final created = await questService.create(quest);
    final list = state.asData?.value ?? const <UserQuest>[];
    state = AsyncValue.data([created, ...list]);
  }

  Future<void> edit(UserQuest quest) async {
    await questService.update(quest);
    final list = state.asData?.value ?? const <UserQuest>[];
    state = AsyncValue.data([
      for (final q in list) q.id == quest.id ? quest : q,
    ]);
  }

  Future<void> remove(String questId) async {
    await questService.delete(questId);
    final list = state.asData?.value ?? const <UserQuest>[];
    state = AsyncValue.data(list.where((q) => q.id != questId).toList());
  }

  /// Remove a referência de foto ([url]) de qualquer missão que a use, para não
  /// deixar links quebrados quando a foto é apagada na galeria.
  Future<void> clearPhotoByUrl(String url) async {
    final list = state.asData?.value ?? const <UserQuest>[];
    final affected = list.where((q) => q.photoUrl == url).toList();
    if (affected.isEmpty) return;

    UserQuest cleared(UserQuest q) => UserQuest(
          id: q.id,
          userId: q.userId,
          title: q.title,
          subtitle: q.subtitle,
          details: q.details,
          xp: q.xp,
          iconName: q.iconName,
          photoUrl: null,
          cityName: q.cityName,
          createdAt: q.createdAt,
        );

    for (final q in affected) {
      await questService.update(cleared(q));
    }
    state = AsyncValue.data([
      for (final q in list) q.photoUrl == url ? cleared(q) : q,
    ]);
  }
}
