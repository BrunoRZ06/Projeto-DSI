import '../models/city_quest.dart';

/// Quests padrão para diferentes cidades
/// Use cityQuestService.seedQuestsForCity() para popular o Firestore

// ─── LONDRES ─────────────────────────────────────────────────────────────────

const londonQuests = [
  CityQuest(
    id: '',
    cityName: 'Londres',
    title: 'Fotografe o Big Ben',
    subtitle: 'Capture o ícone mais famoso de Londres',
    details: 'Tire uma foto criativa do Big Ben. Dica: o melhor ângulo é da Westminster Bridge!',
    xp: 300,
    iconName: 'camera',
    locationHint: 'Big Ben, Westminster',
    latitude: 51.5007,
    longitude: -0.1246,
  ),
  CityQuest(
    id: '',
    cityName: 'Londres',
    title: 'Prove um Fish & Chips autêntico',
    subtitle: 'Experimente o prato tradicional britânico',
    details: 'Encontre um pub tradicional e peça Fish & Chips. Não esqueça do molho tártaro!',
    xp: 200,
    iconName: 'utensils',
    locationHint: 'Qualquer pub tradicional',
  ),
  CityQuest(
    id: '',
    cityName: 'Londres',
    title: 'Visite a Tower Bridge',
    subtitle: 'Explore a ponte mais icônica',
    details: 'Atravesse a Tower Bridge e tire uma foto de cima. A vista é incrível!',
    xp: 250,
    iconName: 'landmark',
    locationHint: 'Tower Bridge',
    latitude: 51.5055,
    longitude: -0.0754,
  ),
  CityQuest(
    id: '',
    cityName: 'Londres',
    title: 'Explore o Borough Market',
    subtitle: 'Descubra o mercado de comida mais famoso',
    details: 'Visite o Borough Market e prove pelo menos 3 comidas diferentes. Converse com os vendedores!',
    xp: 400,
    iconName: 'map',
    locationHint: 'Borough Market, Southwark',
    latitude: 51.5055,
    longitude: -0.0909,
  ),
];

// ─── PARIS ───────────────────────────────────────────────────────────────────

const parisQuests = [
  CityQuest(
    id: '',
    cityName: 'Paris',
    title: 'Fotografe a Torre Eiffel',
    subtitle: 'Capture o símbolo de Paris',
    details: 'Tire uma foto única da Torre Eiffel. Dica: vá ao Trocadéro para a melhor vista!',
    xp: 300,
    iconName: 'camera',
    locationHint: 'Torre Eiffel, Champ de Mars',
    latitude: 48.8584,
    longitude: 2.2945,
  ),
  CityQuest(
    id: '',
    cityName: 'Paris',
    title: 'Prove um croissant em uma padaria local',
    subtitle: 'Experimente a autêntica pâtisserie francesa',
    details: 'Encontre uma boulangerie tradicional e peça um croissant au beurre. Melhor pela manhã!',
    xp: 200,
    iconName: 'coffee',
    locationHint: 'Qualquer boulangerie artesanal',
  ),
  CityQuest(
    id: '',
    cityName: 'Paris',
    title: 'Passeie por Montmartre',
    subtitle: 'Explore o bairro dos artistas',
    details: 'Caminhe pelas ruas de Montmartre, visite a Sacré-Cœur e veja artistas pintando nas ruas.',
    xp: 350,
    iconName: 'map',
    locationHint: 'Montmartre',
    latitude: 48.8867,
    longitude: 2.3431,
  ),
  CityQuest(
    id: '',
    cityName: 'Paris',
    title: 'Tome um café em um bistrot',
    subtitle: 'Viva como um parisiense',
    details: 'Sente-se em um café de rua e peça um café au lait. Observe as pessoas passando.',
    xp: 150,
    iconName: 'coffee',
    locationHint: 'Qualquer bistrot com mesas na calçada',
  ),
];

// ─── NOVA YORK ───────────────────────────────────────────────────────────────

const newYorkQuests = [
  CityQuest(
    id: '',
    cityName: 'Nova York',
    title: 'Visite a Times Square à noite',
    subtitle: 'Experimente as luzes de NYC',
    details: 'Vá à Times Square quando escurecer e tire uma foto com todos os painéis luminosos.',
    xp: 250,
    iconName: 'camera',
    locationHint: 'Times Square, Manhattan',
    latitude: 40.7580,
    longitude: -73.9855,
  ),
  CityQuest(
    id: '',
    cityName: 'Nova York',
    title: 'Coma uma pizza em uma pizzaria local',
    subtitle: 'Prove a famosa pizza de NY',
    details: 'Encontre uma pizzaria tradicional e peça uma slice. Dobre ao meio para comer como um nova-iorquino!',
    xp: 200,
    iconName: 'utensils',
    locationHint: 'Qualquer pizzaria de bairro',
  ),
  CityQuest(
    id: '',
    cityName: 'Nova York',
    title: 'Atravesse a Brooklyn Bridge',
    subtitle: 'Caminhe pela ponte icônica',
    details: 'Atravesse a Brooklyn Bridge a pé e tire fotos do skyline de Manhattan.',
    xp: 300,
    iconName: 'landmark',
    locationHint: 'Brooklyn Bridge',
    latitude: 40.7061,
    longitude: -73.9969,
  ),
  CityQuest(
    id: '',
    cityName: 'Nova York',
    title: 'Relaxe no Central Park',
    subtitle: 'Descubra o pulmão verde de NYC',
    details: 'Passe pelo menos 30 minutos explorando o Central Park. Encontre Bethesda Fountain!',
    xp: 250,
    iconName: 'map',
    locationHint: 'Central Park',
    latitude: 40.7829,
    longitude: -73.9654,
  ),
];

// ─── TÓQUIO ──────────────────────────────────────────────────────────────────

const tokyoQuests = [
  CityQuest(
    id: '',
    cityName: 'Tóquio',
    title: 'Fotografe o cruzamento de Shibuya',
    subtitle: 'Capture o cruzamento mais movimentado do mundo',
    details: 'Vá ao Shibuya Crossing e filme ou fotografe a multidão atravessando. Melhor à tarde!',
    xp: 300,
    iconName: 'camera',
    locationHint: 'Shibuya Crossing',
    latitude: 35.6595,
    longitude: 139.7004,
  ),
  CityQuest(
    id: '',
    cityName: 'Tóquio',
    title: 'Prove ramen autêntico',
    subtitle: 'Experimente o prato icônico japonês',
    details: 'Encontre uma ramen-ya tradicional e peça um bowl de ramen. Use a máquina de tickets!',
    xp: 250,
    iconName: 'utensils',
    locationHint: 'Qualquer ramen-ya local',
  ),
  CityQuest(
    id: '',
    cityName: 'Tóquio',
    title: 'Visite um templo em Asakusa',
    subtitle: 'Explore o Sensō-ji',
    details: 'Vá ao templo Sensō-ji, o mais antigo de Tóquio. Não esqueça de pegar um omikuji (previsão)!',
    xp: 350,
    iconName: 'landmark',
    locationHint: 'Templo Sensō-ji, Asakusa',
    latitude: 35.7148,
    longitude: 139.7967,
  ),
  CityQuest(
    id: '',
    cityName: 'Tóquio',
    title: 'Explore Akihabara',
    subtitle: 'Descubra a capital da cultura otaku',
    details: 'Visite lojas de eletrônicos, anime e mangá em Akihabara. Entre em um arcade!',
    xp: 300,
    iconName: 'map',
    locationHint: 'Akihabara Electric Town',
    latitude: 35.7022,
    longitude: 139.7745,
  ),
];

// ─── LISBOA ──────────────────────────────────────────────────────────────────

const lisboaQuests = [
  CityQuest(
    id: '',
    cityName: 'Lisboa',
    title: 'Prove um Pastel de Belém',
    subtitle: 'Experimente o doce mais famoso',
    details: 'Vá à Pastéis de Belém e prove o autêntico pastel de nata. Chegue cedo para evitar filas!',
    xp: 250,
    iconName: 'coffee',
    locationHint: 'Pastéis de Belém',
    latitude: 38.6976,
    longitude: -9.2033,
  ),
  CityQuest(
    id: '',
    cityName: 'Lisboa',
    title: 'Ande de elétrico 28',
    subtitle: 'Viaje no bonde histórico',
    details: 'Pegue o elétrico 28 e faça o percurso completo pelos bairros históricos de Lisboa.',
    xp: 300,
    iconName: 'map',
    locationHint: 'Linha 28',
    latitude: 38.7139,
    longitude: -9.1334,
  ),
  CityQuest(
    id: '',
    cityName: 'Lisboa',
    title: 'Visite o Castelo de São Jorge',
    subtitle: 'Explore o castelo no topo da colina',
    details: 'Suba até o Castelo de São Jorge e admire a vista panorâmica de Lisboa.',
    xp: 350,
    iconName: 'landmark',
    locationHint: 'Castelo de São Jorge',
    latitude: 38.7139,
    longitude: -9.1334,
  ),
  CityQuest(
    id: '',
    cityName: 'Lisboa',
    title: 'Escute Fado ao vivo',
    subtitle: 'Ouça a música tradicional portuguesa',
    details: 'Encontre uma casa de fado em Alfama ou Bairro Alto e ouça este estilo único de música.',
    xp: 400,
    iconName: 'music',
    locationHint: 'Alfama ou Bairro Alto',
  ),
];

/// Mapa de todas as quests por cidade
final Map<String, List<CityQuest>> allCityQuests = {
  'Londres': londonQuests,
  'Paris': parisQuests,
  'Nova York': newYorkQuests,
  'Tóquio': tokyoQuests,
  'Lisboa': lisboaQuests,
};
