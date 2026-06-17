import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
 
import '../repositories/app_repository.dart';
 
/// Instância singleton do repositório em memória.
final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});
 

class RepositoryVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final repositoryVersionProvider =
    NotifierProvider<RepositoryVersionNotifier, int>(
  RepositoryVersionNotifier.new,
);

final appDataLoaderProvider = StreamProvider<User?>((ref) async* {
  final repo = ref.read(appRepositoryProvider);
 
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    if (user != null) {
      await repo.loadAll();
    } else {
      repo.clear();
    }
 
    // Notifica todos os widgets que observam o repositório.
ref.read(repositoryVersionProvider.notifier).increment();
 
    yield user;
  }
});
