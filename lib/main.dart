import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega .env. Se não existir, mostra tela de erro em vez de crashar.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Falha ao carregar .env: $e');
    runApp(const _StartupErrorApp(
      message:
          'Arquivo .env não encontrado.\nCopie .env.example para .env e preencha as chaves do Supabase.',
    ));
    return;
  }

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    runApp(const _StartupErrorApp(
      message:
          'SUPABASE_URL ou SUPABASE_ANON_KEY ausentes no .env.\nPreencha as duas variáveis e rode o app novamente.',
    ));
    return;
  }

  try {
    await Supabase.initialize(url: url, anonKey: anonKey);
  } catch (e, s) {
    debugPrint('Falha ao inicializar Supabase: $e\n$s');
    runApp(_StartupErrorApp(
      message: 'Erro ao conectar ao Supabase.\nVerifique a URL/chave no .env.\n\nDetalhe: $e',
    ));
    return;
  }

  runApp(const ProviderScope(child: VibeCoralQuestApp()));
}

/// Tela mínima exibida quando falta configuração — evita crash silencioso
/// e deixa claro pra quem está rodando o app o que precisa ajustar.
class _StartupErrorApp extends StatelessWidget {
  final String message;
  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Configuração necessária',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
