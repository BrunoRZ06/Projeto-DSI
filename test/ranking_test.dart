import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coral_quest/services/city_dataset_service.dart';

void main() {
  final service = CityDatasetService();

  // Preferências em 0..100 (slider 1..5 → 0,25,50,75,100).
  RankingPreferences prefs(double budget, double tourism, double safety) =>
      RankingPreferences(
        budget: budget,
        tourismDistance: tourism,
        safetyPriority: safety,
      );

  Future<String> top(RankingPreferences p) async {
    final ranked = await service.rankDistrictsForCity('Londres', preferences: p);
    return ranked.first.district;
  }

  test('orçamento muda o bairro campeão', () async {
    // tourism/safety neutros, só varia orçamento.
    final mochileiro = await top(prefs(0, 50, 50)); // barato
    final luxo = await top(prefs(100, 50, 50)); // luxo
    // ignore: avoid_print
    print('Orçamento → mochileiro: $mochileiro | luxo: $luxo');
    expect(mochileiro, isNot(equals(luxo)));
  });

  test('proximidade turística muda o bairro campeão', () async {
    final perto = await top(prefs(50, 0, 50)); // perto dos pontos turísticos
    final longe = await top(prefs(50, 100, 50)); // longe
    // ignore: avoid_print
    print('Turismo → perto: $perto | longe: $longe');
    expect(perto, isNot(equals(longe)));
  });

  test('prioridade de segurança eleva bairros seguros', () async {
    final indiferente = await top(prefs(50, 50, 0));
    final maxima = await top(prefs(50, 50, 100));
    // ignore: avoid_print
    print('Segurança → indiferente: $indiferente | máxima: $maxima');
    expect(indiferente, isNot(equals(maxima)));
  });

  test('combinações distintas geram campeões distintos', () async {
    final mochileiroPerto = await top(prefs(0, 0, 25));
    final luxoLongeSeguro = await top(prefs(100, 100, 100));
    // ignore: avoid_print
    print('Combo A: $mochileiroPerto | Combo B: $luxoLongeSeguro');
    expect(mochileiroPerto, isNot(equals(luxoLongeSeguro)));
  });
}
