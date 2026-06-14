import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/accounting/domain/entities/transaction.dart';
import 'package:erp_app/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:erp_app/features/admin/presentation/widgets/metric_card.dart';

class AccountingPage extends ConsumerWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authNotifierProvider).valueOrNull;
    final branchId = user?.isAdmin == true ? null : user?.branchId;
    final txAsync  = ref.watch(transactionsStreamProvider(branchId));
    final revAsync = ref.watch(branchRevenueSummaryProvider(branchId));

    return Scaffold(
      body: Column(children: [
        AppBar(title: const Text('Accounting Ledger')),
        Padding(
          padding: const EdgeInsets.all(20),
          child: revAsync.when(
            loading: () => const CircularProgressIndicator(),
            error:   (e, _) => Text('$e'),
            data: (rev) => Wrap(spacing: 16, runSpacing: 16, children: [
              MetricCard(title: 'Total Income', value: Fmt.currency(rev['total_income']),
                  icon: Icons.arrow_upward, color: Colors.green),
              MetricCard(title: 'Total Expenses', value: Fmt.currency(rev['total_expense']),
                  icon: Icons.arrow_downward, color: Colors.red),
              MetricCard(title: 'Net Profit', value: Fmt.currency(rev['profit']),
                  icon: Icons.account_balance, color: Colors.blue),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (txs) => txs.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final tx  = txs[i];
                    final clr = tx.type == TransactionType.income
                        ? Colors.green
                        : tx.type == TransactionType.expense ? Colors.red : Colors.blue;
                    final sign = tx.type == TransactionType.income ? '+' : '-';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: clr.withOpacity(0.1),
                          child: Icon(_txIcon(tx.type), color: clr, size: 16)),
                      title: Text(tx.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${tx.referenceType ?? ''} · ${Fmt.dateTime(tx.createdAt)}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Text('$sign${Fmt.currency(tx.amount)}',
                          style: TextStyle(
                              color: clr,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    );
                  },
                ),
        )),
      ]),
    );
  }

  IconData _txIcon(TransactionType t) => switch (t) {
    TransactionType.income   => Icons.arrow_downward,
    TransactionType.expense  => Icons.arrow_upward,
    TransactionType.transfer => Icons.swap_horiz,
  };
}