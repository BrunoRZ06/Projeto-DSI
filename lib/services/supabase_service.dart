import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para gerenciar uploads de imagens no Supabase Storage
class SupabaseService {
  static SupabaseClient? _client;
  static const String _bucketName = 'quest-photos';

  /// Inicializa o cliente Supabase
  /// 
  /// Configure as credenciais no arquivo .env (veja .env.example)
  static Future<void> initialize() async {
    try {
      // Verifica se já foi inicializado
      if (_client != null) {
        print('Supabase já inicializado');
        return;
      }

      await Supabase.initialize(
        url: const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://cxzwnafmfgpugwuunsyg.supabase.co',
        ),
        anonKey: const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4enduYWZtZmdwdWd3dXVuc3lnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5OTg4MzIsImV4cCI6MjA5MDU3NDgzMn0.OWk0hObVHCj8bdbU7lnEGY9Xtey183I3pE1cG6yElmI',
        ),
      );
      _client = Supabase.instance.client;
      print('Supabase inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar Supabase: $e');
      // Não relança o erro para evitar quebrar a aplicação
      // O upload de fotos simplesmente não funcionará
    }
  }

  /// Retorna a instância do cliente Supabase
  static SupabaseClient? get client {
    if (_client == null) {
      print('Aviso: Supabase não foi inicializado corretamente.');
    }
    return _client;
  }

  /// Faz upload de uma imagem para o bucket do Supabase
  /// 
  /// [filePath] - Caminho local do arquivo
  /// [userId] - ID do usuário para organizar as fotos
  /// 
  /// Retorna a URL pública da imagem ou null se falhar
  static Future<String?> uploadQuestPhoto({
    required String filePath,
    required String userId,
  }) async {
    try {
      if (client == null) {
        print('Supabase não disponível. Upload de foto não realizado.');
        return null;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        print('Arquivo não encontrado: $filePath');
        return null;
      }

      // Gera um nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(filePath);
      final fileName = 'quest_${userId}_$timestamp$extension';
      final storagePath = 'users/$userId/$fileName';

      // Faz o upload
      final bytes = await file.readAsBytes();
      await client!.storage.from(_bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      // Retorna a URL pública
      final publicUrl = client!.storage.from(_bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Deleta uma foto do Supabase Storage
  /// 
  /// [photoUrl] - URL completa da foto retornada pelo upload
  static Future<bool> deleteQuestPhoto(String photoUrl) async {
    try {
      if (client == null) {
        print('Supabase não disponível. Exclusão de foto não realizada.');
        return false;
      }

      // Extrai o caminho do arquivo da URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // Remove os segmentos do bucket para obter o caminho do arquivo
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) return false;
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      await client!.storage.from(_bucketName).remove([filePath]);
      return true;
    } catch (e) {
      print('Erro ao deletar foto: $e');
      return false;
    }
  }

  /// Retorna o Content-Type baseado na extensão do arquivo
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
