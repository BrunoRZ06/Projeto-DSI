import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Inicializa Supabase para armazenamento de imagens
    // Não bloqueia o app se falhar - upload de fotos ficará indisponível
    try {
      await SupabaseService.initialize();
    } catch (e) {
      debugPrint('Supabase não disponível: $e');
    }
  } catch (e, s) {
    debugPrint('Falha ao inicializar serviços: $e\n$s');
    runApp(_StartupErrorApp(message: 'Erro ao conectar aos serviços.\n$e'));
    return;
  }

  runApp(const ProviderScope(child: VibeCoralQuestApp()));
}

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
                  Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Configuração necessária',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}