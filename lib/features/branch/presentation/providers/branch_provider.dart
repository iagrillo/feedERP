import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/branch/data/models/branch_model.dart';
import 'package:erp_app/features/branch/domain/entities/branch.dart';

// All branches (admin) or own branch (staff)
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.tableBranches)
      .select()
      .eq('is_active', true)
      .order('name');
  return (data as List).map((e) => BranchModel.fromJson(e)).toList();
});

// Selected branch for admin switching context
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);

class BranchNotifier extends AsyncNotifier<List<Branch>> {
  @override
  Future<List<Branch>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final data   = await client
        .from(AppConstants.tableBranches)
        .select()
        .order('name');
    return (data as List).map((e) => BranchModel.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final client = ref.read(supabaseClientProvider);
    await client.from(AppConstants.tableBranches).insert(payload);
    ref.invalidateSelf();
  }

  Future<void> updateBranch(String id, Map<String, dynamic> payload) async {
    final client = ref.read(supabaseClientProvider);
    await client.from(AppConstants.tableBranches).update(payload).eq('id', id);
    ref.invalidateSelf();
  }
}

final branchNotifierProvider =
    AsyncNotifierProvider<BranchNotifier, List<Branch>>(BranchNotifier.new);
