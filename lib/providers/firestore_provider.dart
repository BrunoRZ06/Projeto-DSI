import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD

import '../providers/app_repository_provider.dart';
=======
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((_) => FirestoreService());

<<<<<<< HEAD

final completeQuestProvider =
    FutureProvider.family<void, String>((ref, questId) async {
  await ref.read(appRepositoryProvider).completeQuest(questId);
});
=======
final userProfileProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).watchProfile();
});

final completedQuestsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCompletedQuests();
});

final completeQuestProvider = FutureProvider.family<void, String>((ref, questId) async {
  await ref.read(firestoreServiceProvider).completeQuest(questId);
});
>>>>>>> 78c0e23dc4f45cec5271c4751c3ad63af3c1fd5a
