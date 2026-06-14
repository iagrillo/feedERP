import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Regular anon client — used everywhere
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Admin client with service role key — used only for user creation
final adminSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_SERVICE_KEY'),
  );
});
