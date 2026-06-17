import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço stub para web - Supabase não disponível
class SupabaseService {
  static Future<void> initialize() async {
    print('Supabase upload desabilitado na web');
  }

  static SupabaseClient? get client => null;

  static Future<String?> uploadQuestPhoto({
    required String filePath,
    required String userId,
  }) async {
    print('Upload de fotos não disponível na versão web');
    return null;
  }

  static Future<bool> deleteQuestPhoto(String photoUrl) async {
    print('Exclusão de fotos não disponível na versão web');
    return false;
  }
}
