import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:erp_app/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:erp_app/features/sales/presentation/providers/sales_provider.dart';
import 'package:erp_app/features/admin/presentation/widgets/metric_card.dart';
import 'package:erp_app/features/admin/presentation/widgets/low_stock_table.dart';

class BranchDashboardPage extends ConsumerWidget {
  const BranchDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authNotifierProvider).valueOrNull;
    final branchId   = user?.branchId;
    final revenueAsync   = ref.watch(branchRevenueSummaryProvider(branchId));
    final lowStockAsync  = ref.watch(lowStockProvider(branchId));
    final salesAsync     = ref.watch(salesStreamProvider(branchId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Branch Dashboard${user?.fullName != null ? " — ${user!.fullName}" : ""}'),
            floating: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Sale'),
                  onPressed: () => context.go('/branch/sales/create'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Metrics
              revenueAsync.when(
                data: (rev) => Wrap(spacing: 16, runSpacing: 16, children: [
                  MetricCard(title: 'Today Revenue', value: Fmt.currency(rev['total_income']),
                      icon: Icons.trending_up, color: Colors.green),
                  MetricCard(title: 'Expenses', value: Fmt.currency(rev['total_expense']),
                      icon: Icons.trending_down, color: Colors.orange),
                  MetricCard(title: 'Net Profit', value: Fmt.currency(rev['profit']),
                      icon: Icons.account_balance_wallet, color: Colors.blue),
                ]),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 24),

              // Recent sales
              salesAsync.when(
                data: (sales) => _RecentSalesCard(sales: sales.take(5).toList()),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 24),

              // Low stock
              lowStockAsync.when(
                data: (items) => LowStockTable(items: items),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
            ])),
          ),
        ],
      ),
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  final List sales;
  const _RecentSalesCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Sales', style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/branch/sales'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          if (sales.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No sales today'),
            )
          else
            ...sales.map((s) => ListTile(
              leading: CircleAvatar(
                backgroundColor: s.status.name == 'confirmed'
                    ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                child: Icon(
                  s.status.name == 'confirmed' ? Icons.check : Icons.pending_outlined,
                  color: s.status.name == 'confirmed' ? Colors.green : Colors.orange,
                  size: 18,
                ),
              ),
              title: Text(s.invoiceNumber),
              subtitle: Text(s.customerName ?? 'Walk-in customer'),
              trailing: Text(Fmt.currency(s.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
