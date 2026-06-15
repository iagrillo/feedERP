import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:erp_app/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:erp_app/features/branch/presentation/providers/branch_provider.dart';

//  Providers 

final _todaySalesProvider = FutureProvider<double>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final today  = DateTime.now();
  final start  = DateTime(today.year, today.month, today.day).toIso8601String();
  final end    = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
  final data   = await client
      .from(AppConstants.tableSales)
      .select('total_amount')
      .eq('status', 'confirmed')
      .gte('created_at', start)
      .lte('created_at', end);
  return (data as List).fold<double>(
      0, (sum, e) => sum + ((e['total_amount'] as num?)?.toDouble() ?? 0));
});

final _inventoryValueProvider = FutureProvider<double>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.viewCurrentInventory)
      .select('stock_quantity, unit_cost');
  return (data as List).fold<double>(0, (sum, e) {
    final qty  = (e['stock_quantity'] as num?)?.toDouble() ?? 0;
    final cost = (e['unit_cost'] as num?)?.toDouble() ?? 0;
    return sum + (qty * cost);
  });
});

final _fastestProductProvider = FutureProvider<String>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.viewTopSellingProducts)
      .select('product_name')
      .limit(1);
  if ((data as List).isEmpty) return 'N/A';
  return data.first['product_name'] as String? ?? 'N/A';
});

final _monthlyPurchasesProvider = FutureProvider<double>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final now    = DateTime.now();
  final start  = DateTime(now.year, now.month, 1).toIso8601String();
  final end    = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(seconds: 1)).toIso8601String();
  final data   = await client
      .from(AppConstants.tablePurchases)
      .select('total_amount')
      .gte('created_at', start)
      .lte('created_at', end);
  return (data as List).fold<double>(
      0, (sum, e) => sum + ((e['total_amount'] as num?)?.toDouble() ?? 0));
});

final _pendingTransfersProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.tableTransfers)
      .select('id')
      .eq('status', 'pending');
  return (data as List).length;
});

final _outstandingCreditProvider = FutureProvider<double>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.tableSales)
      .select('total_amount, amount_paid')
      .eq('status', 'confirmed');
  return (data as List).fold<double>(0, (sum, e) {
    final total = (e['total_amount'] as num?)?.toDouble() ?? 0;
    final paid  = (e['amount_paid']  as num?)?.toDouble() ?? 0;
    return sum + (total - paid).clamp(0, double.infinity);
  });
});

final _branchPerformanceProvider = FutureProvider<Map<String, String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client
      .from(AppConstants.viewBranchRevenueSummary)
      .select('branch_name, total_income')
      .order('total_income', ascending: false);
  if ((data as List).isEmpty) return {'best': 'N/A', 'worst': 'N/A'};
  return {
    'best':  data.first['branch_name'] as String? ?? 'N/A',
    'worst': data.last['branch_name']  as String? ?? 'N/A',
  };
});

//  Page 

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final branchesAsync      = ref.watch(branchNotifierProvider);
    final revenueAsync       = ref.watch(branchRevenueSummaryProvider(null));
    final lowStockAsync      = ref.watch(lowStockProvider(null));
    final todaySalesAsync      = ref.watch(_todaySalesProvider);
    final monthlyPurchasesAsync = ref.watch(_monthlyPurchasesProvider);
    final invValueAsync      = ref.watch(_inventoryValueProvider);
    final fastProductAsync   = ref.watch(_fastestProductProvider);
    final pendingAsync       = ref.watch(_pendingTransfersProvider);
    final creditAsync        = ref.watch(_outstandingCreditProvider);
    final branchPerfAsync    = ref.watch(_branchPerformanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Executive Dashboard'),
            floating: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: const Icon(Icons.circle, color: Colors.green, size: 10),
                  label: const Text('Live'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                //  Section header 
                _SectionHeader(title: 'COMPANY OVERVIEW'),
                const SizedBox(height: 16),

                //  KPI grid 
                Wrap(spacing: 16, runSpacing: 16, children: [

                  _KpiCard(
                    title: 'Total Branches',
                    icon: Icons.store_outlined,
                    color: Colors.indigo,
                    value: branchesAsync.when(
                      data:    (b) => '${b.length}',
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Inventory Value',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.teal,
                    value: invValueAsync.when(
                      data:    (v) => Fmt.currency(v),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: "Today's Sales",
                    icon: Icons.point_of_sale_outlined,
                    color: Colors.green,
                    value: todaySalesAsync.when(
                      data:    (v) => Fmt.currency(v),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                    _KpiCard(
                    title: 'Monthly Purchases',
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.deepOrange,
                    value: monthlyPurchasesAsync.when(
                      data:    (v) => Fmt.currency(v),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Monthly Revenue',
                    icon: Icons.trending_up,
                    color: Colors.blue,
                    value: revenueAsync.when(
                      data:    (r) => Fmt.currency(r['total_income']),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Monthly Profit',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.purple,
                    value: revenueAsync.when(
                      data:    (r) => Fmt.currency(r['profit']),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Outstanding Credit',
                    icon: Icons.credit_card_outlined,
                    color: Colors.orange,
                    value: creditAsync.when(
                      data:    (v) => Fmt.currency(v),
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Low Stock Alerts',
                    icon: Icons.warning_amber_outlined,
                    color: Colors.red,
                    value: lowStockAsync.when(
                      data:    (items) => '${items.length} Products',
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                  _KpiCard(
                    title: 'Pending Transfers',
                    icon: Icons.swap_horiz_outlined,
                    color: Colors.brown,
                    value: pendingAsync.when(
                      data:    (v) => '$v',
                      loading: () => '...',
                      error:   (_, __) => 'Err',
                    ),
                  ),

                ]),

                const SizedBox(height: 24),

                //  Performance cards 
                _SectionHeader(title: 'PERFORMANCE HIGHLIGHTS'),
                const SizedBox(height: 16),

                Wrap(spacing: 16, runSpacing: 16, children: [

                  _HighlightCard(
                    title: 'Fastest Moving Product',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.deepOrange,
                    value: fastProductAsync.when(
                      data:    (v) => v,
                      loading: () => '...',
                      error:   (_, __) => 'N/A',
                    ),
                  ),

                  _HighlightCard(
                    title: 'Best Performing Branch',
                    icon: Icons.emoji_events_outlined,
                    color: Colors.amber[700]!,
                    value: branchPerfAsync.when(
                      data:    (m) => m['best'] ?? 'N/A',
                      loading: () => '...',
                      error:   (_, __) => 'N/A',
                    ),
                  ),

                  _HighlightCard(
                    title: 'Lowest Performing Branch',
                    icon: Icons.arrow_downward_outlined,
                    color: Colors.blueGrey,
                    value: branchPerfAsync.when(
                      data:    (m) => m['worst'] ?? 'N/A',
                      loading: () => '...',
                      error:   (_, __) => 'N/A',
                    ),
                  ),

                ]),

                const SizedBox(height: 24),

                //  Low stock table 
                _SectionHeader(title: 'LOW STOCK ALERTS'),
                const SizedBox(height: 16),

                lowStockAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error:   (e, _) => Text('$e'),
                  data:    (items) => items.isEmpty
                      ? _EmptyState(message: 'All stock levels are healthy')
                      : Card(
                          child: Column(
                            children: items.map((s) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                child: const Icon(Icons.warning_amber,
                                    color: Colors.red, size: 18),
                              ),
                              title: Text(s.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(s.branchName),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Stock: ${Fmt.number(s.stockQuantity)}',
                                      style: const TextStyle(
                                          color: Colors.red, fontWeight: FontWeight.bold)),
                                  Text('Reorder: ${Fmt.number(s.reorderLevel)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

//  Widgets 

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Colors.grey[600],
    )),
    const SizedBox(width: 12),
    Expanded(child: Divider(color: Colors.grey[300])),
  ]);
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                  fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    ),
  );
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _HighlightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      color: color.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w700,
                letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.green),
        const SizedBox(width: 12),
        Text(message, style: const TextStyle(color: Colors.green)),
      ]),
    ),
  );
}




