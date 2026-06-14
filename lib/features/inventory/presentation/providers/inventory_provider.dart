import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/inventory/domain/entities/inventory_stock.dart';

// Realtime stream of current inventory for a branch
final inventoryStreamProvider =
    StreamProvider.family<List<InventoryStock>, String?>((ref, branchId) {
  final client = ref.watch(supabaseClientProvider);

  // Pull initial + realtime via Supabase Realtime on inventory_events
  return client
      .from(AppConstants.tableInventoryEvents)
      .stream(primaryKey: ['id'])
      .map((_) => null)  // trigger refetch on any change
      .asyncMap((_) async {
        var query = client
            .from(AppConstants.viewCurrentInventory)
            .select();
        if (branchId != null) query = query.eq('branch_id', branchId);
        final data = await query.order('product_name');
        return (data as List)
            .map((e) => InventoryStockModel.fromJson(e))
            .toList();
      });
});

// Low stock alerts
final lowStockProvider = FutureProvider.family<List<InventoryStock>, String?>((ref, branchId) async {
  final client = ref.watch(supabaseClientProvider);
  var query    = client.from(AppConstants.viewLowStockAlerts).select();
  if (branchId != null) query = query.eq('branch_id', branchId);
  final data   = await query;
  return (data as List).map((e) => InventoryStockModel.fromJson(e)).toList();
});
