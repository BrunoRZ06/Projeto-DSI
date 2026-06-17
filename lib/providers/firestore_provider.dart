import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((_) => FirestoreService());

final userProfileProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).watchProfile();
});

final completedQuestsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCompletedQuests();
});

final completeQuestProvider = FutureProvider.family<void, String>((ref, questId) async {
  await ref.read(firestoreServiceProvider).completeQuest(questId);
});
