import 'package:supabase_flutter/supabase_flutter.dart';

/// Atalho global para o cliente Supabase já inicializado em main.dart.
/// Equivale ao `import { supabase } from "@/integrations/supabase/client"` do React.
SupabaseClient get supabase => Supabase.instance.client;
