import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    debugPrint('Falha ao inicializar Firebase: $e\n$s');
    runApp(_StartupErrorApp(message: 'Erro ao conectar ao Firebase.\n$e'));
    return;
  }


  try {
    await FirebaseFirestore.instance
        .collection('_health')
        .doc('ping')
        .get()
        .timeout(const Duration(seconds: 6));
    debugPrint('✅ Firebase ok (Firestore acessível)');
  } on TimeoutException {
    debugPrint('⚠️ Firestore ping timeout — rede lenta ou regras bloqueando');
  } on FirebaseException catch (e) {
  
    if (e.code == 'permission-denied') {
      debugPrint('✅ Firebase ok (Firestore respondendo, regras restritivas)');
    } else {
      debugPrint('⚠️ Firestore inacessível [${e.code}]: ${e.message}');
    }
  } catch (e) {
    debugPrint('⚠️ Firestore inacessível: $e');
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Configuração necessária',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}