import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_quest.dart';

/// Serviço para gerenciar quests padrão das cidades no Firestore
class CityQuestService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('city_quests');

  /// Busca todas as quests de uma cidade específica
  Future<List<CityQuest>> fetchByCity(String cityName) async {
    try {
      final snapshot = await _collection
          .where('city_name', isEqualTo: cityName)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        return CityQuest.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar quests da cidade $cityName: $e');
      return [];
    }
  }

  /// Busca todas as cidades que têm quests
  Future<List<String>> fetchCitiesWithQuests() async {
    try {
      final snapshot = await _collection.get();
      final cities = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['city_name'] as String?)
          .where((city) => city != null)
          .cast<String>()
          .toSet()
          .toList();
      cities.sort();
      return cities;
    } catch (e) {
      print('Erro ao buscar cidades com quests: $e');
      return [];
    }
  }

  /// Cria uma nova quest para uma cidade (Admin)
  Future<CityQuest?> create(CityQuest quest) async {
    try {
      final payload = {
        ...quest.toJson(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      final docRef = await _collection.add(payload);
      final doc = await docRef.get();
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      return CityQuest.fromJson(data);
    } catch (e) {
      print('Erro ao criar quest da cidade: $e');
      return null;
    }
  }

  /// Atualiza uma quest de cidade existente (Admin)
  Future<bool> update(CityQuest quest) async {
    try {
      await _collection.doc(quest.id).update({
        ...quest.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar quest da cidade: $e');
      return false;
    }
  }

  /// Deleta uma quest de cidade (Admin)
  Future<bool> delete(String questId) async {
    try {
      await _collection.doc(questId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar quest da cidade: $e');
      return false;
    }
  }

  /// Busca uma quest específica por ID
  Future<CityQuest?> fetchById(String questId) async {
    try {
      final doc = await _collection.doc(questId).get();
      if (!doc.exists) return null;
      
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      return CityQuest.fromJson(data);
    } catch (e) {
      print('Erro ao buscar quest por ID: $e');
      return null;
    }
  }

  /// Cria quests padrão para uma cidade (uso inicial/seeding)
  Future<void> seedQuestsForCity(String cityName, List<CityQuest> quests) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final quest in quests) {
        final docRef = _collection.doc();
        batch.set(docRef, {
          ...quest.toJson(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('Quests criadas para $cityName com sucesso!');
    } catch (e) {
      print('Erro ao criar quests padrão para $cityName: $e');
    }
  }
}

final cityQuestService = CityQuestService();
