import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final adminSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    'https://yhhnawlhcjbgliramtyc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InloaG5hd2xoY2piZ2xpcmFtdHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTM2ODc1OCwiZXhwIjoyMDk2OTQ0NzU4fQ.umrnm4VptEwM94vkg7R-7QT-HDuSDHKZsZXzj5yZL1c',
  );
});