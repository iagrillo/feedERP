import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';

final _purchasesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user   = ref.watch(authNotifierProvider).valueOrNull;
  final client = ref.watch(supabaseClientProvider);
  var q = client.from(AppConstants.tablePurchases).select();
  final query = (user?.isAdmin == false && user?.branchId != null)
      ? q.eq('branch_id', user!.branchId!).order('created_at', ascending: false)
      : q.order('created_at', ascending: false);
  return (await query).cast<Map<String, dynamic>>();
});

class PurchasesListPage extends ConsumerWidget {
  const PurchasesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(_purchasesProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Purchases'),
          actions: [
            if (user?.isAdmin == false)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Purchase'),
                  style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => context.go('/branch/purchases/create'),
                ),
              ),
          ],
        ),
        Expanded(child: purchasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (purchases) => purchases.isEmpty
              ? const Center(child: Text('No purchases recorded'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p   = purchases[i];
                    final st  = p['status'] as String;
                    final clr = st == 'confirmed' ? Colors.green
                        : st == 'cancelled' ? Colors.red : Colors.orange;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: clr.withOpacity(0.1),
                          child: Icon(Icons.shopping_cart_outlined, color: clr),
                        ),
                        title: Text(p['supplier_name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (p['invoice_ref'] != null) Text('Ref: ${p['invoice_ref']}'),
                          Text(Fmt.date(DateTime.tryParse(p['created_at'] as String ?? '')),
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Fmt.currency(p['total_amount']),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: clr.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(st, style: TextStyle(color: clr, fontSize: 10)),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        )),
      ]),
    );
  }
}


