import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Regular anon client — used everywhere
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Admin client with service role key — used only for user creation
final adminSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    'https://yhhnawlhcjbgliramtyc.supabase.co',
    'YOUR_SERVICE_ROLE_KEY_HERE',
  );
});
