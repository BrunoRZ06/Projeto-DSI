/// Exporta a implementação correta do SupabaseService baseado na plataforma
/// - Web: supabase_service_stub.dart (sem upload de fotos)
/// - Mobile/Desktop: supabase_service_io.dart (com upload de fotos)
export 'supabase_service_stub.dart'
    if (dart.library.io) 'supabase_service_io.dart';
