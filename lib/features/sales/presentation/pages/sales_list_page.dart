import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/sales/domain/entities/sale.dart';
import 'package:erp_app/features/sales/presentation/providers/sales_provider.dart';

class SalesListPage extends ConsumerWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authNotifierProvider).valueOrNull;
    final branchId = user?.isAdmin == true ? null : user?.branchId;
    final salesAsync = ref.watch(salesStreamProvider(branchId));
    final isAdmin  = user?.isAdmin ?? false;
    final canCreate = !(user?.isAdmin ?? false);

    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Sales'),
          actions: [
            if (canCreate)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Sale'),
                  style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => context.go('/branch/sales/create'),
                ),
              ),
          ],
        ),
        Expanded(child: salesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data:    (sales) => sales.isEmpty
              ? const Center(child: Text('No sales yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
                ),
        )),
      ]),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (sale.status) {
      SaleStatus.confirmed => Colors.green,
      SaleStatus.cancelled => Colors.red,
      SaleStatus.draft     => Colors.orange,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.receipt_outlined, color: statusColor),
        ),
        title: Row(children: [
          Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _Chip(sale.status.name, statusColor),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sale.customerName ?? 'Walk-in customer'),
            Text(Fmt.dateTime(sale.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.currency(sale.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (sale.balance > 0)
              Text('Balance: ${Fmt.currency(sale.balance)}',
                  style: TextStyle(color: Colors.red[700], fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
