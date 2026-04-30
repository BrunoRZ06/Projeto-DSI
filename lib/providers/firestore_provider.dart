import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

// Instância do serviço
final firestoreServiceProvider = Provider((_) => FirestoreService());

// Stream do perfil do usuário logado
final userProfileProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).watchProfile();
});

// Stream das quests concluídas
final completedQuestsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(firestoreServiceProvider).watchCompletedQuests();
});
