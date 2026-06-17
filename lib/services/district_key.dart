import '../models/district_score.dart';

/// Gera uma chave estável e reutilizável para identificar um bairro
/// baseada na cidade e no nome do bairro.
String generateDistrictKeyFromParts({required String city, required String district}) {
  final normalizedCity = _normalize(city);
  final normalizedDistrict = _normalize(district);
  return '$normalizedCity|$normalizedDistrict'.replaceAll('\u007f', '');
}

/// Conveniência: gera a chave a partir de um `DistrictScore`.
String generateDistrictKey(DistrictScore district) =>
    generateDistrictKeyFromParts(city: district.city, district: district.district);

String _normalize(String input) {
  var s = input.trim().toLowerCase();
  s = _removeDiacritics(s);
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  return s;
}

String _removeDiacritics(String s) {
  const Map<String, String> map = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'ý': 'y', 'ÿ': 'y',
    'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ç': 'c', 'Ñ': 'n', 'Ý': 'y',
  };
  final buffer = StringBuffer();
  for (var rune in s.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}
