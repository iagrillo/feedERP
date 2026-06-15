import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/network/supabase_client.dart';

// Single KPI value model
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

// Fetch all latest KPI values from the view (rn=1 = most recent per key)
final kpiValuesProvider = FutureProvider<List<KpiValue>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('vw_kpi_latest_values')
      .select('kpi_key, value, value_formatted, delta_pct, period')
      .eq('rn', 1);
  return (data as List).map((e) => KpiValue.fromMap(e)).toList();
});
