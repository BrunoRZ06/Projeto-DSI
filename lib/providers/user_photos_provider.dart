import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_service.dart';
import 'auth_provider.dart';
import 'user_quest_provider.dart';

/// Todas as fotos que o usuário enviou, lidas diretamente do Supabase Storage
/// (pasta `users/{uid}/`). Combina com as URLs já referenciadas nas missões do
/// usuário (caso a listagem do Storage ainda não esteja liberada por policy).
final userPhotosProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const <String>[];

  // Fonte primária: listagem do Supabase Storage.
  final fromStorage = await SupabaseService.listUserPhotos(user.uid);

  // Fallback/união: URLs das fotos das missões do usuário (arquivos no Supabase).
  final quests = ref.watch(userQuestsProvider).asData?.value ?? const [];
  final fromQuests = quests
      .where((q) => q.photoUrl != null && q.photoUrl!.trim().isNotEmpty)
      .map((q) => q.photoUrl!)
      .toList();

  return <String>{...fromStorage, ...fromQuests}.toList();
});
