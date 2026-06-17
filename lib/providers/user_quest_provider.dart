import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_quest.dart';
import '../providers/auth_provider.dart';
import '../services/quest_service.dart';

final userQuestsProvider = NotifierProvider<UserQuestNotifier, AsyncValue<List<UserQuest>>>(
  UserQuestNotifier.new,
);

class UserQuestNotifier extends Notifier<AsyncValue<List<UserQuest>>> {
  @override
  AsyncValue<List<UserQuest>> build() {
    // Initial empty state and start listening to auth changes
    _init();
    return const AsyncValue.data(<UserQuest>[]);
  }

  void _init() {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        state = const AsyncValue.data(<UserQuest>[]);
        return;
      }

      final prevUid = previous?.uid;
      final nextUid = next.uid;
      if (prevUid != nextUid) {
        load(nextUid);
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
    state.whenData((list) {
      state = AsyncValue.data([created, ...list]);
    });
  }

  Future<void> edit(UserQuest quest) async {
    await questService.update(quest);
    state.whenData((list) {
      state = AsyncValue.data([
        for (final q in list) q.id == quest.id ? quest : q,
      ]);
    });
  }

  Future<void> remove(String questId) async {
    await questService.delete(questId);
    state.whenData((list) {
      state = AsyncValue.data(list.where((q) => q.id != questId).toList());
    });
  }
}
