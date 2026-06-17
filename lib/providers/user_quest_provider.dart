import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_quest.dart';
import '../providers/app_repository_provider.dart';
import '../providers/auth_provider.dart';
import '../services/quest_service.dart';

final userQuestsProvider =
    NotifierProvider<UserQuestNotifier, AsyncValue<List<UserQuest>>>(
  UserQuestNotifier.new,
);


class UserQuestNotifier extends Notifier<AsyncValue<List<UserQuest>>> {
  @override
  AsyncValue<List<UserQuest>> build() {
    _init();
    return const AsyncValue.data(<UserQuest>[]);
  }

  void _init() {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        state = const AsyncValue.data(<UserQuest>[]);
        return;
      }
      if (previous?.uid != next.uid) {
        load(next.uid);
      }
    }, fireImmediately: true);
  }

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    try {
      final quests = await questService.fetchByUser(userId);
      state = AsyncValue.data(quests);
      _syncRepo(quests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(UserQuest quest) async {
    final created = await questService.create(quest);
    state.whenData((list) {
      final updated = [created, ...list];
      state = AsyncValue.data(updated);
      _syncRepo(updated);
    });
  }

  Future<void> edit(UserQuest quest) async {
    await questService.update(quest);
    state.whenData((list) {
      final updated = [for (final q in list) q.id == quest.id ? quest : q];
      state = AsyncValue.data(updated);
      _syncRepo(updated);
    });
  }

  Future<void> remove(String questId) async {
    await questService.delete(questId);
    state.whenData((list) {
      final updated = list.where((q) => q.id != questId).toList();
      state = AsyncValue.data(updated);
      _syncRepo(updated);
    });
  }

  void _syncRepo(List<UserQuest> quests) {
    ref.read(appRepositoryProvider).syncUserQuests(quests);
  }
}