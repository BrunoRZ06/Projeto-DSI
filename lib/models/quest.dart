import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class Quest {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final int xp;
  final String details;

  const Quest({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.details,
  });
}

const defaultQuests = <Quest>[
  Quest(
    id: 'bakery',
    icon: LucideIcons.camera,
    title: 'Fotografe uma padaria local',
    subtitle: 'Capture o charme dos pães artesanais',
    xp: 300,
    details:
        'Encontre uma padaria autêntica no bairro, tire uma foto bonita e compartilhe com a comunidade. Dica: procure vitrines coloridas!',
  ),
  Quest(
    id: 'coffee',
    icon: LucideIcons.coffee,
    title: 'Prove um flat white num café escondido',
    subtitle: 'Descubra a cultura local do café',
    xp: 200,
    details:
        'Explore as ruas secundárias e encontre um café que não aparece no Google Maps. Peça a bebida mais popular e avalie!',
  ),
  Quest(
    id: 'market',
    icon: LucideIcons.landmark,
    title: 'Visite um mercado local',
    subtitle: 'Explore comida de rua & achados vintage',
    xp: 500,
    details:
        'Passe pelo menos 30 minutos explorando o mercado. Prove algo novo e converse com um vendedor local.',
  ),
  Quest(
    id: 'music',
    icon: LucideIcons.music,
    title: 'Encontre música ao vivo num pub',
    subtitle: 'Viva a cena musical local',
    xp: 400,
    details:
        'Procure pubs com apresentações ao vivo. Fique para pelo menos uma música e compartilhe o momento!',
  ),
];
