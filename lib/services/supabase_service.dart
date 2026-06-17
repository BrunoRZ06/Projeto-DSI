import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Serviço de upload de imagens no Supabase Storage.
///
/// Implementação única cross-platform (web + mobile) usando a REST API do
/// Storage com a anon key. Não usa `dart:io` (que quebra no web com
/// "Unsupported operation: _Namespace") nem o SDK supabase_flutter para o
/// upload — apenas HTTP, então funciona em qualquer plataforma.
///
/// Requisitos no Supabase para o upload funcionar:
/// - Bucket [_bucket] existente e público (leitura).
/// - Policy de INSERT (e DELETE) liberando o role `anon`, já que o app
///   autentica no Firebase e acessa o Supabase apenas como anônimo:
///     CREATE POLICY "anon insert" ON storage.objects
///       FOR INSERT TO anon WITH CHECK (bucket_id = 'Img_BairroMatch');
class SupabaseService {
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cxzwnafmfgpugwuunsyg.supabase.co',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4enduYWZtZmdwdWd3dXVuc3lnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5OTg4MzIsImV4cCI6MjA5MDU3NDgzMn0.OWk0hObVHCj8bdbU7lnEGY9Xtey183I3pE1cG6yElmI',
  );
  static const String _bucket = 'Img_BairroMatch';

  /// Mantido por compatibilidade com o startup; não há mais SDK para iniciar.
  static Future<void> initialize() async {}

  /// Faz upload dos [bytes] da imagem e retorna a URL pública, ou null se falhar.
  ///
  /// [fileName] é usado só para deduzir a extensão/content-type.
  /// [userId] organiza os arquivos por usuário no bucket.
  static Future<String?> uploadQuestPhoto({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      final ext = _extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final objectPath = 'users/$userId/quest_${userId}_$timestamp$ext';

      final uri = Uri.parse('$_url/storage/v1/object/$_bucket/$objectPath');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'apikey': _anonKey,
          'Content-Type': _contentType(ext),
          'x-upsert': 'false',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_url/storage/v1/object/public/$_bucket/$objectPath';
      }
      // ignore: avoid_print
      print('Erro no upload (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Deleta uma foto pelo seu URL público. Retorna true se removida.
  static Future<bool> deleteQuestPhoto(String photoUrl) async {
    try {
      const marker = '/object/public/$_bucket/';
      final idx = photoUrl.indexOf(marker);
      if (idx == -1) return false;
      final objectPath = photoUrl.substring(idx + marker.length);

      final uri = Uri.parse('$_url/storage/v1/object/$_bucket/$objectPath');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'apikey': _anonKey,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao deletar foto: $e');
      return false;
    }
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '.jpg';
    return name.substring(dot).toLowerCase();
  }

  static String _contentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
