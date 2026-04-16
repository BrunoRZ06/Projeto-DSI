import 'package:flutter_riverpod/flutter_riverpod.dart';

/// IDs de quests completadas na sessão atual (estado local, igual ao React).
/// Pra persistir no Supabase, chame `supabase.from('quest_progress').insert(...)`
/// sempre que adicionar um id aqui.
final completedQuestsProvider = StateNotifierProvider<_CompletedQuestsNotifier, Set<String>>(
  (ref) => _CompletedQuestsNotifier(),
);

class _CompletedQuestsNotifier extends StateNotifier<Set<String>> {
  _CompletedQuestsNotifier() : super(<String>{});

  void complete(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
  }

  void reset() => state = <String>{};
}
