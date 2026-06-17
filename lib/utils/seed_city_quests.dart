import 'package:flutter/material.dart';
import '../data/city_quests_data.dart';
import '../services/city_quest_service.dart';

/// Utilit\u00e1rio para popular o Firestore com quests padr\u00e3o das cidades
/// 
/// Use isso apenas uma vez para criar as quests iniciais no Firestore.
/// 
/// Exemplo de uso:
/// ```dart
/// // No seu app, adicione um bot\u00e3o de admin:
/// ElevatedButton(
///   onPressed: () async {
///     await seedAllCityQuests(context);
///   },
///   child: Text('Popular Quests das Cidades'),
/// )
/// ```
Future<void> seedAllCityQuests(BuildContext context) async {
  try {
    // Mostra di\u00e1logo de confirma\u00e7\u00e3o
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Popular Quests das Cidades?'),
        content: const Text(
          'Isso ir\u00e1 criar quests padr\u00e3o para todas as cidades no Firestore. '
          'Execute apenas uma vez. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostra loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Cria quests para cada cidade
    for (final entry in allCityQuests.entries) {
      final cityName = entry.key;
      final quests = entry.value;
      
      await cityQuestService.seedQuestsForCity(cityName, quests);
      debugPrint('✅ Quests criadas para $cityName');
    }

    // Fecha loading
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Mostra sucesso
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${allCityQuests.length} cidades populadas com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Erro ao popular quests: $e');
    
    if (context.mounted) {
      Navigator.pop(context); // Fecha loading se aberto
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao popular quests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Popula quests de uma cidade espec\u00edfica
Future<void> seedCityQuests(BuildContext context, String cityName) async {
  final quests = allCityQuests[cityName];
  
  if (quests == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cidade "$cityName" n\u00e3o encontrada'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    await cityQuestService.seedQuestsForCity(cityName, quests);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Quests criadas para $cityName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
