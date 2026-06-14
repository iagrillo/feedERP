import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/accounting/domain/entities/transaction.dart';

// Ledger transactions stream
final transactionsStreamProvider =
    StreamProvider.family<List<LedgerTransaction>, String?>((ref, branchId) {
  final client = ref.watch(supabaseClientProvider);

  return client
      .from(AppConstants.tableTransactions)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => (data).map((e) => LedgerTransaction(
            id:            e['id'] as String,
            branchId:      e['branch_id'] as String,
            type:          TransactionType.values
                .firstWhere((t) => t.name == e['type']),
            amount:        (e['amount'] as num).toDouble(),
            description:   e['description'] as String,
            referenceId:   e['reference_id'] as String?,
            referenceType: e['reference_type'] as String?,
            paymentMethod: e['payment_method'] as String?,
            createdAt:     DateTime.parse(e['created_at'] as String),
          )).toList());
});

// Branch revenue summary
final branchRevenueSummaryProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, branchId) async {
  final client = ref.watch(supabaseClientProvider);
  var query    = client.from(AppConstants.viewBranchRevenueSummary).select();
  if (branchId != null) query = query.eq('branch_id', branchId);
  final data   = await query;
  if (data.isEmpty) return {'total_income': 0.0, 'total_expense': 0.0, 'profit': 0.0};
  final row    = data.first;
  return {
    'total_income':   (row['total_income'] as num?)?.toDouble() ?? 0,
    'total_expense':  (row['total_expense'] as num?)?.toDouble() ?? 0,
    'profit':         (row['profit'] as num?)?.toDouble() ?? 0,
  };
});
