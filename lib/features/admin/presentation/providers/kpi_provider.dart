import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/network/supabase_client.dart';

class KpiValue {
  final String kpiKey;
  final double value;
  final String? valueFormatted;
  final double? deltaPct;
  final String? period;

  const KpiValue({
    required this.kpiKey,
    required this.value,
    this.valueFormatted,
    this.deltaPct,
    this.period,
  });

  factory KpiValue.fromMap(Map<String, dynamic> m) => KpiValue(
        kpiKey:         m['kpi_key'] as String,
        value:          (m['value'] as num).toDouble(),
        valueFormatted: m['value_formatted'] as String?,
        deltaPct:       (m['delta_pct'] as num?)?.toDouble(),
        period:         m['period'] as String?,
      );
}

class BranchInfo {
  final String id;
  final String name;
  const BranchInfo({required this.id, required this.name});
  factory BranchInfo.fromMap(Map<String, dynamic> m) => BranchInfo(
        id:   m['id'] as String,
        name: m['name'] as String,
      );
}

const kFeedErpCompanyId = '00000000-0000-0000-0000-000000000001';

// Selected branch filter — null means all branches
final selectedBranchProvider = StateProvider<String?>((ref) => null);

// Fetch all branches for the dropdown
final branchesProvider = FutureProvider<List<BranchInfo>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('branches')
      .select('id, name')
      .eq('is_active', true)
      .order('name');
  return (data as List).map((e) => BranchInfo.fromMap(e)).toList();
});

// Compute KPIs from real transactions filtered by branch
final kpiValuesProvider = FutureProvider<List<KpiValue>>((ref) async {
  final client     = ref.watch(supabaseClientProvider);
  final branchId   = ref.watch(selectedBranchProvider);

  // Fetch transactions
  var txnQuery = client.from('transactions').select('type, amount');
  if (branchId != null) txnQuery = txnQuery.eq('branch_id', branchId);
  final txns = await txnQuery;

  double totalSales    = 0;
  double totalExpenses = 0;
  for (final t in txns) {
    final amt = (t['amount'] as num).toDouble();
    if (t['type'] == 'income')  totalSales    += amt;
    if (t['type'] == 'expense') totalExpenses += amt;
  }

  // Fetch purchases
  var purchaseQuery = client
      .from('purchases')
      .select('total_amount')
      .eq('status', 'delivered');
  if (branchId != null) purchaseQuery = purchaseQuery.eq('branch_id', branchId);
  final purchasesData = await purchaseQuery;

  double totalPurchases = 0;
  for (final p in purchasesData) {
    totalPurchases += (p['total_amount'] as num).toDouble();
  }

  final grossProfit  = totalSales - totalPurchases;
  final netProfit    = totalSales - totalExpenses;
  final grossMargin  = totalSales > 0 ? (grossProfit / totalSales) * 100 : 0.0;
  final netMargin    = totalSales > 0 ? (netProfit   / totalSales) * 100 : 0.0;

  String fmtNaira(double v) {
    if (v.abs() >= 1000000) return '₦${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000)    return '₦${(v / 1000).toStringAsFixed(1)}K';
    return '₦${v.toStringAsFixed(0)}';
  }

  return [
    KpiValue(kpiKey: 'revenue_total_sales',  value: totalSales,    valueFormatted: fmtNaira(totalSales),                          deltaPct: 0),
    KpiValue(kpiKey: 'gross_profit',         value: grossProfit,   valueFormatted: fmtNaira(grossProfit),                         deltaPct: 0),
    KpiValue(kpiKey: 'gross_profit_margin',  value: grossMargin,   valueFormatted: '${grossMargin.toStringAsFixed(1)}%',          deltaPct: 0),
    KpiValue(kpiKey: 'net_profit',           value: netProfit,     valueFormatted: fmtNaira(netProfit),                           deltaPct: 0),
    KpiValue(kpiKey: 'net_profit_margin',    value: netMargin,     valueFormatted: '${netMargin.toStringAsFixed(1)}%',            deltaPct: 0),
    KpiValue(kpiKey: 'operating_cash_flow',  value: netProfit,     valueFormatted: fmtNaira(netProfit),                           deltaPct: 0),
    KpiValue(kpiKey: 'operating_profit',     value: grossProfit,   valueFormatted: fmtNaira(grossProfit),                         deltaPct: 0),
    KpiValue(kpiKey: 'total_purchases',      value: totalPurchases,valueFormatted: fmtNaira(totalPurchases),                      deltaPct: 0),
    KpiValue(kpiKey: 'total_expenses',       value: totalExpenses, valueFormatted: fmtNaira(totalExpenses),                       deltaPct: 0),
  ];
});
