import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_repository_provider.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((_) => FirestoreService());


final completeQuestProvider =
    FutureProvider.family<void, String>((ref, questId) async {
  await ref.read(appRepositoryProvider).completeQuest(questId);
});