/// Dataset curado (artificial) de bairros famosos das cidades suportadas.
///
/// Cada bairro tem três notas de 1 a 5, alinhadas aos parâmetros do quiz:
/// - [budget]  1 = barato/mochileiro … 5 = caro/luxo
/// - [tourism] 1 = longe dos pontos turísticos … 5 = no coração turístico
/// - [safety]  1 = menos seguro … 5 = muito seguro
///
/// As notas são fictícias, mas escolhidas com perfis variados dentro de cada
/// cidade para que o ranking mude claramente conforme o usuário altera os
/// parâmetros (orçamento, proximidade turística e prioridade de segurança).
class Neighborhood {
  final String cityCanonical; // chave normalizada em inglês (ex: 'london')
  final String cityDisplay; // nome exibido (ex: 'Londres')
  final String name;
  final double lat;
  final double lng;
  final int budget; // 1..5
  final int tourism; // 1..5 (5 = mais central/turístico)
  final int safety; // 1..5

  const Neighborhood(
    this.cityCanonical,
    this.cityDisplay,
    this.name,
    this.lat,
    this.lng,
    this.budget,
    this.tourism,
    this.safety,
  );
}

const List<Neighborhood> kNeighborhoods = [
  // ─── Londres ───────────────────────────────────────────────────────────
  Neighborhood('london', 'Londres', 'Soho', 51.5132, -0.1310, 5, 5, 3),
  Neighborhood('london', 'Londres', 'Covent Garden', 51.5123, -0.1230, 5, 5, 4),
  Neighborhood('london', 'Londres', 'Westminster', 51.4995, -0.1357, 5, 5, 4),
  Neighborhood('london', 'Londres', 'Mayfair', 51.5101, -0.1470, 5, 4, 5),
  Neighborhood('london', 'Londres', 'Kensington', 51.4988, -0.1930, 5, 3, 5),
  Neighborhood('london', 'Londres', 'Chelsea', 51.4875, -0.1687, 5, 3, 5),
  Neighborhood('london', 'Londres', 'Notting Hill', 51.5152, -0.2055, 4, 3, 4),
  Neighborhood('london', 'Londres', 'Shoreditch', 51.5265, -0.0780, 3, 4, 3),
  Neighborhood('london', 'Londres', 'Camden Town', 51.5414, -0.1430, 3, 4, 3),
  Neighborhood('london', 'Londres', 'Brixton', 51.4620, -0.1150, 2, 2, 2),
  Neighborhood('london', 'Londres', 'Hackney', 51.5450, -0.0553, 2, 2, 3),
  Neighborhood('london', 'Londres', 'Greenwich', 51.4810, -0.0090, 3, 2, 4),
  Neighborhood('london', 'Londres', 'Islington', 51.5380, -0.1030, 4, 3, 4),
  Neighborhood('london', 'Londres', 'Stratford', 51.5410, -0.0030, 2, 2, 3),
  Neighborhood('london', 'Londres', 'Richmond', 51.4610, -0.3040, 4, 1, 5),
  Neighborhood('london', 'Londres', 'Wimbledon', 51.4210, -0.2060, 4, 1, 5),

  // ─── Roma ──────────────────────────────────────────────────────────────
  Neighborhood('rome', 'Roma', 'Centro Storico', 41.8980, 12.4760, 5, 5, 4),
  Neighborhood('rome', 'Roma', 'Trastevere', 41.8890, 12.4690, 4, 5, 4),
  Neighborhood('rome', 'Roma', 'Monti', 41.8940, 12.4910, 4, 5, 4),
  Neighborhood('rome', 'Roma', 'Prati', 41.9070, 12.4560, 4, 4, 4),
  Neighborhood('rome', 'Roma', 'Piazza di Spagna', 41.9060, 12.4820, 5, 5, 4),
  Neighborhood('rome', 'Roma', 'Colosseo', 41.8900, 12.4920, 4, 5, 3),
  Neighborhood('rome', 'Roma', 'Testaccio', 41.8760, 12.4750, 3, 3, 3),
  Neighborhood('rome', 'Roma', 'Trieste', 41.9230, 12.5080, 4, 2, 5),
  Neighborhood('rome', 'Roma', 'Parioli', 41.9230, 12.4900, 5, 2, 5),
  Neighborhood('rome', 'Roma', 'San Lorenzo', 41.8960, 12.5150, 2, 3, 2),
  Neighborhood('rome', 'Roma', 'Pigneto', 41.8880, 12.5350, 2, 2, 2),
  Neighborhood('rome', 'Roma', 'EUR', 41.8310, 12.4700, 4, 1, 4),
  Neighborhood('rome', 'Roma', 'Garbatella', 41.8610, 12.4870, 2, 2, 3),
  Neighborhood('rome', 'Roma', 'Ostiense', 41.8700, 12.4800, 3, 3, 3),
  Neighborhood('rome', 'Roma', 'Aventino', 41.8830, 12.4800, 5, 4, 5),
  Neighborhood('rome', 'Roma', 'Flaminio', 41.9280, 12.4700, 3, 3, 4),

  // ─── Paris ─────────────────────────────────────────────────────────────
  Neighborhood('paris', 'Paris', 'Le Marais', 48.8570, 2.3590, 4, 5, 4),
  Neighborhood('paris', 'Paris', 'Champs-Élysées', 48.8700, 2.3070, 5, 5, 4),
  Neighborhood('paris', 'Paris', 'Saint-Germain-des-Prés', 48.8540, 2.3330, 5, 5, 5),
  Neighborhood('paris', 'Paris', 'Quartier Latin', 48.8480, 2.3450, 3, 5, 4),
  Neighborhood('paris', 'Paris', 'Montmartre', 48.8860, 2.3400, 3, 4, 3),
  Neighborhood('paris', 'Paris', 'Louvre', 48.8610, 2.3360, 5, 5, 4),
  Neighborhood('paris', 'Paris', 'Bastille', 48.8530, 2.3690, 3, 4, 3),
  Neighborhood('paris', 'Paris', 'Belleville', 48.8720, 2.3770, 2, 3, 2),
  Neighborhood('paris', 'Paris', 'Pigalle', 48.8820, 2.3370, 3, 4, 2),
  Neighborhood('paris', 'Paris', 'Canal Saint-Martin', 48.8720, 2.3660, 3, 3, 3),
  Neighborhood('paris', 'Paris', 'Tour Eiffel', 48.8560, 2.2980, 5, 5, 4),
  Neighborhood('paris', 'Paris', 'Bercy', 48.8350, 2.3820, 3, 2, 4),
  Neighborhood('paris', 'Paris', 'La Défense', 48.8920, 2.2360, 4, 1, 4),
  Neighborhood('paris', 'Paris', 'Passy', 48.8570, 2.2790, 5, 3, 5),
  Neighborhood('paris', 'Paris', 'Ménilmontant', 48.8660, 2.3900, 2, 2, 2),
  Neighborhood('paris', 'Paris', 'Batignolles', 48.8870, 2.3190, 4, 2, 4),

  // ─── Lisboa ────────────────────────────────────────────────────────────
  Neighborhood('lisbon', 'Lisboa', 'Baixa', 38.7100, -9.1390, 4, 5, 4),
  Neighborhood('lisbon', 'Lisboa', 'Alfama', 38.7120, -9.1300, 3, 5, 3),
  Neighborhood('lisbon', 'Lisboa', 'Bairro Alto', 38.7120, -9.1440, 3, 5, 3),
  Neighborhood('lisbon', 'Lisboa', 'Chiado', 38.7100, -9.1420, 5, 5, 4),
  Neighborhood('lisbon', 'Lisboa', 'Belém', 38.6970, -9.2060, 4, 4, 4),
  Neighborhood('lisbon', 'Lisboa', 'Príncipe Real', 38.7170, -9.1500, 5, 4, 5),
  Neighborhood('lisbon', 'Lisboa', 'Mouraria', 38.7150, -9.1350, 2, 4, 3),
  Neighborhood('lisbon', 'Lisboa', 'Graça', 38.7170, -9.1300, 3, 3, 3),
  Neighborhood('lisbon', 'Lisboa', 'Avenidas Novas', 38.7300, -9.1460, 5, 3, 5),
  Neighborhood('lisbon', 'Lisboa', 'Parque das Nações', 38.7680, -9.0940, 4, 2, 5),
  Neighborhood('lisbon', 'Lisboa', 'Alcântara', 38.7060, -9.1770, 3, 2, 3),
  Neighborhood('lisbon', 'Lisboa', 'Estrela', 38.7130, -9.1600, 4, 3, 4),
  Neighborhood('lisbon', 'Lisboa', 'Campo de Ourique', 38.7170, -9.1660, 4, 2, 5),
  Neighborhood('lisbon', 'Lisboa', 'Marvila', 38.7410, -9.1030, 2, 1, 3),
  Neighborhood('lisbon', 'Lisboa', 'Areeiro', 38.7420, -9.1340, 3, 2, 4),
  Neighborhood('lisbon', 'Lisboa', 'Cais do Sodré', 38.7060, -9.1450, 4, 5, 3),

  // ─── Atenas ────────────────────────────────────────────────────────────
  Neighborhood('athens', 'Atenas', 'Plaka', 37.9720, 23.7280, 4, 5, 4),
  Neighborhood('athens', 'Atenas', 'Monastiraki', 37.9760, 23.7260, 3, 5, 3),
  Neighborhood('athens', 'Atenas', 'Syntagma', 37.9750, 23.7350, 5, 5, 4),
  Neighborhood('athens', 'Atenas', 'Kolonaki', 37.9790, 23.7430, 5, 4, 5),
  Neighborhood('athens', 'Atenas', 'Psiri', 37.9780, 23.7230, 3, 4, 3),
  Neighborhood('athens', 'Atenas', 'Exarchia', 37.9860, 23.7330, 2, 3, 2),
  Neighborhood('athens', 'Atenas', 'Koukaki', 37.9650, 23.7260, 3, 4, 4),
  Neighborhood('athens', 'Atenas', 'Thiseio', 37.9760, 23.7190, 4, 4, 4),
  Neighborhood('athens', 'Atenas', 'Omonia', 37.9840, 23.7280, 2, 3, 2),
  Neighborhood('athens', 'Atenas', 'Pangrati', 37.9680, 23.7510, 3, 2, 4),
  Neighborhood('athens', 'Atenas', 'Glyfada', 37.8650, 23.7540, 5, 1, 5),
  Neighborhood('athens', 'Atenas', 'Piraeus', 37.9420, 23.6460, 3, 1, 3),
  Neighborhood('athens', 'Atenas', 'Marousi', 38.0560, 23.8080, 4, 1, 5),
  Neighborhood('athens', 'Atenas', 'Nea Smyrni', 37.9450, 23.7130, 3, 2, 4),
  Neighborhood('athens', 'Atenas', 'Kifisia', 38.0730, 23.8110, 5, 1, 5),
  Neighborhood('athens', 'Atenas', 'Petralona', 37.9690, 23.7150, 2, 3, 3),

  // ─── Budapeste ─────────────────────────────────────────────────────────
  Neighborhood('budapest', 'Budapeste', 'Belváros (V)', 47.4970, 19.0510, 5, 5, 4),
  Neighborhood('budapest', 'Budapeste', 'Erzsébetváros (VII)', 47.5010, 19.0640, 3, 5, 3),
  Neighborhood('budapest', 'Budapeste', 'Terézváros (VI)', 47.5080, 19.0620, 4, 4, 4),
  Neighborhood('budapest', 'Budapeste', 'Várnegyed (I)', 47.4960, 19.0390, 5, 5, 5),
  Neighborhood('budapest', 'Budapeste', 'Józsefváros (VIII)', 47.4890, 19.0700, 2, 3, 2),
  Neighborhood('budapest', 'Budapeste', 'Ferencváros (IX)', 47.4780, 19.0660, 3, 3, 3),
  Neighborhood('budapest', 'Budapeste', 'Újlipótváros (XIII)', 47.5200, 19.0560, 4, 3, 4),
  Neighborhood('budapest', 'Budapeste', 'Rózsadomb (II)', 47.5200, 19.0200, 5, 2, 5),
  Neighborhood('budapest', 'Budapeste', 'Újbuda (XI)', 47.4730, 19.0400, 3, 2, 4),
  Neighborhood('budapest', 'Budapeste', 'Zugló (XIV)', 47.5150, 19.0940, 3, 2, 4),
  Neighborhood('budapest', 'Budapeste', 'Marg-sziget', 47.5270, 19.0500, 4, 3, 5),
  Neighborhood('budapest', 'Budapeste', 'Óbuda (III)', 47.5530, 19.0430, 3, 1, 4),
  Neighborhood('budapest', 'Budapeste', 'Gellérthegy', 47.4860, 19.0460, 5, 4, 5),
  Neighborhood('budapest', 'Budapeste', 'Hegyvidék (XII)', 47.4950, 19.0050, 5, 1, 5),
  Neighborhood('budapest', 'Budapeste', 'Andrássy út', 47.5050, 19.0670, 5, 5, 4),
  Neighborhood('budapest', 'Budapeste', 'Kőbánya (X)', 47.4770, 19.1480, 2, 1, 3),

  // ─── Viena ─────────────────────────────────────────────────────────────
  Neighborhood('vienna', 'Viena', 'Innere Stadt', 48.2080, 16.3730, 5, 5, 5),
  Neighborhood('vienna', 'Viena', 'Leopoldstadt', 48.2180, 16.4000, 3, 4, 4),
  Neighborhood('vienna', 'Viena', 'Landstraße', 48.1970, 16.3940, 4, 4, 4),
  Neighborhood('vienna', 'Viena', 'Wieden', 48.1930, 16.3680, 4, 4, 5),
  Neighborhood('vienna', 'Viena', 'Mariahilf', 48.1970, 16.3480, 4, 4, 4),
  Neighborhood('vienna', 'Viena', 'Neubau', 48.2030, 16.3470, 4, 4, 4),
  Neighborhood('vienna', 'Viena', 'Josefstadt', 48.2110, 16.3470, 4, 3, 5),
  Neighborhood('vienna', 'Viena', 'Alsergrund', 48.2250, 16.3570, 4, 3, 5),
  Neighborhood('vienna', 'Viena', 'Favoriten', 48.1760, 16.3780, 2, 2, 3),
  Neighborhood('vienna', 'Viena', 'Ottakring', 48.2110, 16.3100, 2, 2, 3),
  Neighborhood('vienna', 'Viena', 'Döbling', 48.2470, 16.3390, 5, 1, 5),
  Neighborhood('vienna', 'Viena', 'Hietzing', 48.1870, 16.3000, 5, 2, 5),
  Neighborhood('vienna', 'Viena', 'Schönbrunn', 48.1850, 16.3120, 5, 4, 5),
  Neighborhood('vienna', 'Viena', 'Floridsdorf', 48.2580, 16.4000, 2, 1, 4),
  Neighborhood('vienna', 'Viena', 'Simmering', 48.1710, 16.4200, 2, 1, 3),
  Neighborhood('vienna', 'Viena', 'Prater', 48.2160, 16.3960, 3, 3, 4),

  // ─── Barcelona ─────────────────────────────────────────────────────────
  Neighborhood('barcelona', 'Barcelona', 'Barri Gòtic', 41.3830, 2.1770, 4, 5, 3),
  Neighborhood('barcelona', 'Barcelona', 'El Born', 41.3850, 2.1820, 4, 5, 4),
  Neighborhood('barcelona', 'Barcelona', 'El Raval', 41.3800, 2.1690, 2, 5, 2),
  Neighborhood('barcelona', 'Barcelona', 'Eixample', 41.3920, 2.1650, 5, 4, 4),
  Neighborhood('barcelona', 'Barcelona', 'Gràcia', 41.4030, 2.1560, 3, 3, 4),
  Neighborhood('barcelona', 'Barcelona', 'Barceloneta', 41.3800, 2.1900, 3, 4, 3),
  Neighborhood('barcelona', 'Barcelona', 'Sant Antoni', 41.3790, 2.1600, 3, 3, 4),
  Neighborhood('barcelona', 'Barcelona', 'Poble Sec', 41.3730, 2.1620, 3, 3, 3),
  Neighborhood('barcelona', 'Barcelona', 'Sarrià', 41.4010, 2.1230, 5, 1, 5),
  Neighborhood('barcelona', 'Barcelona', 'Pedralbes', 41.3900, 2.1100, 5, 1, 5),
  Neighborhood('barcelona', 'Barcelona', 'Sants', 41.3750, 2.1390, 3, 2, 3),
  Neighborhood('barcelona', 'Barcelona', 'Poblenou', 41.4040, 2.2020, 3, 2, 4),
  Neighborhood('barcelona', 'Barcelona', 'El Putxet', 41.4080, 2.1390, 5, 1, 5),
  Neighborhood('barcelona', 'Barcelona', 'Sant Gervasi', 41.4010, 2.1400, 5, 2, 5),
  Neighborhood('barcelona', 'Barcelona', 'Montjuïc', 41.3630, 2.1650, 3, 3, 4),
  Neighborhood('barcelona', 'Barcelona', 'La Mercè', 41.3790, 2.1810, 4, 5, 3),

  // ─── Berlim ────────────────────────────────────────────────────────────
  Neighborhood('berlin', 'Berlim', 'Mitte', 52.5210, 13.4020, 4, 5, 4),
  Neighborhood('berlin', 'Berlim', 'Prenzlauer Berg', 52.5400, 13.4240, 4, 4, 5),
  Neighborhood('berlin', 'Berlim', 'Kreuzberg', 52.4990, 13.4030, 3, 4, 3),
  Neighborhood('berlin', 'Berlim', 'Friedrichshain', 52.5150, 13.4540, 3, 4, 3),
  Neighborhood('berlin', 'Berlim', 'Charlottenburg', 52.5050, 13.3040, 5, 3, 5),
  Neighborhood('berlin', 'Berlim', 'Neukölln', 52.4810, 13.4350, 2, 3, 3),
  Neighborhood('berlin', 'Berlim', 'Schöneberg', 52.4830, 13.3550, 4, 3, 4),
  Neighborhood('berlin', 'Berlim', 'Tiergarten', 52.5140, 13.3500, 5, 5, 4),
  Neighborhood('berlin', 'Berlim', 'Wedding', 52.5500, 13.3650, 2, 2, 3),
  Neighborhood('berlin', 'Berlim', 'Moabit', 52.5300, 13.3420, 3, 3, 3),
  Neighborhood('berlin', 'Berlim', 'Wilmersdorf', 52.4870, 13.3180, 5, 2, 5),
  Neighborhood('berlin', 'Berlim', 'Lichtenberg', 52.5150, 13.5000, 2, 1, 3),
  Neighborhood('berlin', 'Berlim', 'Steglitz', 52.4560, 13.3320, 4, 1, 5),
  Neighborhood('berlin', 'Berlim', 'Pankow', 52.5690, 13.4010, 3, 1, 4),
  Neighborhood('berlin', 'Berlim', 'Köpenick', 52.4450, 13.5740, 3, 1, 4),
  Neighborhood('berlin', 'Berlim', 'Potsdamer Platz', 52.5090, 13.3760, 5, 5, 4),

  // ─── Amsterdã ──────────────────────────────────────────────────────────
  Neighborhood('amsterdam', 'Amsterdã', 'Grachtengordel', 52.3700, 4.8900, 5, 5, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'Jordaan', 52.3740, 4.8800, 5, 5, 5),
  Neighborhood('amsterdam', 'Amsterdã', 'De Pijp', 52.3550, 4.8920, 4, 4, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'Oud-West', 52.3640, 4.8700, 4, 3, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'Museumkwartier', 52.3570, 4.8790, 5, 5, 5),
  Neighborhood('amsterdam', 'Amsterdã', 'Plantage', 52.3660, 4.9100, 4, 4, 5),
  Neighborhood('amsterdam', 'Amsterdã', 'Oostelijke Eilanden', 52.3720, 4.9250, 4, 2, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'De Wallen', 52.3740, 4.9000, 3, 5, 2),
  Neighborhood('amsterdam', 'Amsterdã', 'Westerpark', 52.3870, 4.8750, 4, 3, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'Indische Buurt', 52.3620, 4.9300, 3, 2, 3),
  Neighborhood('amsterdam', 'Amsterdã', 'Noord', 52.3940, 4.9180, 3, 2, 4),
  Neighborhood('amsterdam', 'Amsterdã', 'Bos en Lommer', 52.3820, 4.8470, 3, 2, 3),
  Neighborhood('amsterdam', 'Amsterdã', 'Nieuw-West', 52.3580, 4.8100, 2, 1, 3),
  Neighborhood('amsterdam', 'Amsterdã', 'Zuidas', 52.3390, 4.8730, 5, 1, 5),
  Neighborhood('amsterdam', 'Amsterdã', 'Watergraafsmeer', 52.3500, 4.9300, 4, 1, 5),
  Neighborhood('amsterdam', 'Amsterdã', 'Rivierenbuurt', 52.3450, 4.9010, 4, 2, 5),
];
