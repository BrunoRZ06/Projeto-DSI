import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_quest.dart';
<<<<<<< HEAD
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
=======
import '../providers/auth_provider.dart';
import '../services/quest_service.dart';

final userQuestsProvider = NotifierProvider<UserQuestNotifier, AsyncValue<List<UserQuest>>>(
  UserQuestNotifier.new,
);

class UserQuestNotifier extends Notifier<AsyncValue<List<UserQuest>>> {
  @override
  AsyncValue<List<UserQuest>> build() {
    // Initial empty state and start listening to auth changes
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    _init();
    return const AsyncValue.data(<UserQuest>[]);
  }

  void _init() {
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (next == null) {
        state = const AsyncValue.data(<UserQuest>[]);
        return;
      }
<<<<<<< HEAD
      if (previous?.uid != next.uid) {
        load(next.uid);
=======

      final prevUid = previous?.uid;
      final nextUid = next.uid;
      if (prevUid != nextUid) {
        load(nextUid);
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
      }
    }, fireImmediately: true);
  }

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    try {
      final quests = await questService.fetchByUser(userId);
      state = AsyncValue.data(quests);
<<<<<<< HEAD
      _syncRepo(quests);
=======
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(UserQuest quest) async {
    final created = await questService.create(quest);
    state.whenData((list) {
<<<<<<< HEAD
      final updated = [created, ...list];
      state = AsyncValue.data(updated);
      _syncRepo(updated);
=======
      state = AsyncValue.data([created, ...list]);
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    });
  }

  Future<void> edit(UserQuest quest) async {
    await questService.update(quest);
    state.whenData((list) {
<<<<<<< HEAD
      final updated = [for (final q in list) q.id == quest.id ? quest : q];
      state = AsyncValue.data(updated);
      _syncRepo(updated);
=======
      state = AsyncValue.data([
        for (final q in list) q.id == quest.id ? quest : q,
      ]);
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
    });
  }

  Future<void> remove(String questId) async {
    await questService.delete(questId);
    state.whenData((list) {
<<<<<<< HEAD
      final updated = list.where((q) => q.id != questId).toList();
      state = AsyncValue.data(updated);
      _syncRepo(updated);
    });
  }

  void _syncRepo(List<UserQuest> quests) {
    ref.read(appRepositoryProvider).syncUserQuests(quests);
  }
}
=======
      state = AsyncValue.data(list.where((q) => q.id != questId).toList());
    });
  }
}
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
