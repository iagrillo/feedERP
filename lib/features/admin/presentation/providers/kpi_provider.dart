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

// FeedERP fixed company ID
const kFeedErpCompanyId = '00000000-0000-0000-0000-000000000001';

final kpiValuesProvider = FutureProvider<List<KpiValue>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('kpi_values')
      .select('kpi_key, value, value_formatted, delta_pct, period')
      .eq('company_id', kFeedErpCompanyId)
      .order('kpi_key');
  return (data as List).map((e) => KpiValue.fromMap(e)).toList();
});

// Refresh KPIs by recalculating from real transactions
final kpiRefreshProvider = FutureProvider<void>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  // Fetch totals from transactions
  final txns = await client
      .from('transactions')
      .select('type, amount');

  double totalSales    = 0;
  double totalExpenses = 0;
  for (final t in txns) {
    final amt = (t['amount'] as num).toDouble();
    if (t['type'] == 'income')  totalSales    += amt;
    if (t['type'] == 'expense') totalExpenses += amt;
  }

  // Fetch delivered purchases
  final purchasesData = await client
      .from('purchases')
      .select('total_amount')
      .eq('status', 'delivered');

  double totalPurchases = 0;
  for (final p in purchasesData) {
    totalPurchases += (p['total_amount'] as num).toDouble();
  }

  final grossProfit    = totalSales - totalPurchases;
  final netProfit      = totalSales - totalExpenses;
  final grossMargin    = totalSales > 0 ? (grossProfit / totalSales) * 100 : 0.0;
  final netMargin      = totalSales > 0 ? (netProfit   / totalSales) * 100 : 0.0;

  String fmtNaira(double v) {
    if (v.abs() >= 1000000) return '₦${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000)    return '₦${(v / 1000).toStringAsFixed(1)}K';
    return '₦${v.toStringAsFixed(0)}';
  }

  final now = DateTime.now().toIso8601String().substring(0, 10);

  final upserts = [
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'revenue_total_sales',  'value': totalSales,    'value_formatted': fmtNaira(totalSales),    'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'gross_profit',         'value': grossProfit,   'value_formatted': fmtNaira(grossProfit),   'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'gross_profit_margin',  'value': grossMargin,   'value_formatted': '${grossMargin.toStringAsFixed(1)}%',  'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'net_profit',           'value': netProfit,     'value_formatted': fmtNaira(netProfit),     'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'net_profit_margin',    'value': netMargin,     'value_formatted': '${netMargin.toStringAsFixed(1)}%',    'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'operating_cash_flow',  'value': netProfit,     'value_formatted': fmtNaira(netProfit),     'delta_pct': 0, 'period': now},
    {'company_id': kFeedErpCompanyId, 'kpi_key': 'operating_profit',     'value': grossProfit,   'value_formatted': fmtNaira(grossProfit),   'delta_pct': 0, 'period': now},
  ];

  await client
      .from('kpi_values')
      .upsert(upserts, onConflict: 'company_id,kpi_key');

  ref.invalidate(kpiValuesProvider);
});
