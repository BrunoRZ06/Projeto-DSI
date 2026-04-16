import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Stream do estado de autenticação do Supabase.
/// Equivale ao `supabase.auth.onAuthStateChange` + `getSession` do React.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Usuário atual (null se não logado). Observa o authStateProvider.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.valueOrNull?.session?.user ?? supabase.auth.currentUser;
});
