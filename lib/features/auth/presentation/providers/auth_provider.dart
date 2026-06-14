import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/auth/data/models/app_user_model.dart';
import 'package:erp_app/features/auth/domain/entities/app_user.dart';

// Raw Supabase auth state stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// Current logged-in AppUser (null = not logged in)
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final client  = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;

  final data = await client
      .from(AppConstants.tableUsers)
      .select()
      .eq('id', session.user.id)
      .single();

  return AppUserModel.fromJson(data);
});

// Auth notifier for login/logout
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final client  = ref.watch(supabaseClientProvider);
    final session = client.auth.currentSession;
    if (session == null) return null;
    final data = await client
        .from(AppConstants.tableUsers)
        .select()
        .eq('id', session.user.id)
        .single();
    return AppUserModel.fromJson(data);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      final session = client.auth.currentSession!;
      final data = await client
          .from(AppConstants.tableUsers)
          .select()
          .eq('id', session.user.id)
          .single();
      state = AsyncData(AppUserModel.fromJson(data));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await ref.read(supabaseClientProvider).auth.signOut();
    state = const AsyncData(null);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);
