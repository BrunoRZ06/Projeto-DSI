import '../models/city_quest.dart';

/// Catálogo de missões de exemplo por cidade, usado para popular o Firestore
/// quando uma cidade ainda não tem nenhuma missão curada.
///
/// As chaves são normalizadas (minúsculas, sem acento) para casar com o nome
/// da cidade vindo do fluxo global, independente de capitalização/acentos.
const Map<String, List<Map<String, dynamic>>> _citySeed = {
  'londres': [
    {
      'title': 'Fotografe o Big Ben',
      'subtitle': 'O cartão-postal de Londres',
      'details':
          'Vá até Westminster e capture o relógio mais famoso do mundo. Dica: a vista da ponte de Westminster fica linda ao entardecer.',
      'xp': 500,
      'icon_name': 'landmark',
      'location_hint': 'Big Ben, Westminster',
    },
    {
      'title': 'Passeie pelo Hyde Park',
      'subtitle': 'O pulmão verde da cidade',
      'details':
          'Caminhe pelo parque, visite o Speakers\' Corner e tire uma foto no Serpentine Lake.',
      'xp': 300,
      'icon_name': 'map',
      'location_hint': 'Hyde Park',
    },
    {
      'title': 'Tome um chá da tarde',
      'subtitle': 'Tradição britânica',
      'details':
          'Encontre um salão de chá e experimente o afternoon tea completo, com scones e clotted cream.',
      'xp': 250,
      'icon_name': 'coffee',
      'location_hint': null,
    },
  ],
  'paris': [
    {
      'title': 'Fotografe a Torre Eiffel',
      'subtitle': 'A Dame de Fer',
      'details':
          'Capture a torre do Trocadéro para o melhor ângulo. À noite ela brilha a cada hora cheia.',
      'xp': 500,
      'icon_name': 'landmark',
      'location_hint': 'Champ de Mars',
    },
    {
      'title': 'Visite o Louvre',
      'subtitle': 'A maior galeria de arte do mundo',
      'details':
          'Veja a Mona Lisa e a pirâmide de vidro. Reserve algumas horas para explorar.',
      'xp': 400,
      'icon_name': 'book',
      'location_hint': 'Musée du Louvre',
    },
    {
      'title': 'Prove um croissant local',
      'subtitle': 'Café da manhã parisiense',
      'details': 'Encontre uma boulangerie de bairro e prove um croissant fresquinho.',
      'xp': 200,
      'icon_name': 'utensils',
      'location_hint': null,
    },
  ],
  'rio de janeiro': [
    {
      'title': 'Suba ao Cristo Redentor',
      'subtitle': 'Uma das 7 maravilhas',
      'details':
          'Pegue o trem do Corcovado e fotografe a vista de 360° da cidade maravilhosa.',
      'xp': 500,
      'icon_name': 'landmark',
      'location_hint': 'Corcovado',
    },
    {
      'title': 'Curta a praia de Copacabana',
      'subtitle': 'O calçadão mais famoso',
      'details': 'Caminhe pelo calçadão de pedras portuguesas e prove um açaí.',
      'xp': 300,
      'icon_name': 'map',
      'location_hint': 'Copacabana',
    },
  ],
  'recife': [
    {
      'title': 'Explore o Marco Zero',
      'subtitle': 'O coração do Recife Antigo',
      'details':
          'Visite a praça do Marco Zero e veja as esculturas de Francisco Brennand no Parque das Esculturas.',
      'xp': 400,
      'icon_name': 'landmark',
      'location_hint': 'Marco Zero, Recife Antigo',
    },
    {
      'title': 'Prove um bolo de rolo',
      'subtitle': 'Doce típico pernambucano',
      'details': 'Encontre uma confeitaria local e experimente o famoso bolo de rolo.',
      'xp': 200,
      'icon_name': 'utensils',
      'location_hint': null,
    },
  ],
};

/// Missões genéricas usadas quando a cidade não tem um conjunto específico.
const List<Map<String, dynamic>> _genericSeed = [
  {
    'title': 'Fotografe um ponto turístico',
    'subtitle': 'Registre o cartão-postal local',
    'details':
        'Encontre o principal ponto turístico da cidade e capture uma foto bonita para compartilhar.',
    'xp': 400,
    'icon_name': 'camera',
    'location_hint': null,
  },
  {
    'title': 'Visite um mercado local',
    'subtitle': 'Comida de rua & achados',
    'details':
        'Explore um mercado da cidade por pelo menos 30 minutos. Prove algo novo e converse com um vendedor.',
    'xp': 300,
    'icon_name': 'landmark',
    'location_hint': null,
  },
  {
    'title': 'Tome um café num lugar escondido',
    'subtitle': 'Descubra a cena local',
    'details':
        'Fuja das ruas principais e encontre um café autêntico. Peça a bebida mais popular e avalie.',
    'xp': 200,
    'icon_name': 'coffee',
    'location_hint': null,
  },
];

String _normalize(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  var r = s.toLowerCase().trim();
  for (var i = 0; i < from.length; i++) {
    r = r.replaceAll(from[i], to[i]);
  }
  return r;
}

/// Constrói as missões de exemplo (já como [CityQuest]) para semear a [cityName].
List<CityQuest> buildSeedQuestsForCity(String cityName) {
  if (cityName.trim().isEmpty) return const [];
  final maps = _citySeed[_normalize(cityName)] ?? _genericSeed;
  return [
    for (final m in maps)
      CityQuest(
        id: '',
        cityName: cityName,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String? ?? '',
        details: m['details'] as String? ?? '',
        xp: m['xp'] as int? ?? 100,
        iconName: m['icon_name'] as String? ?? 'star',
        locationHint: m['location_hint'] as String?,
      ),
  ];
}
