import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KpiDashboardPage extends ConsumerStatefulWidget {
  const KpiDashboardPage({super.key});
  @override
  ConsumerState<KpiDashboardPage> createState() => _KpiDashboardPageState();
}

class _KpiDashboardPageState extends ConsumerState<KpiDashboardPage> {
  List<Map<String, dynamic>> _kpis = [];
  bool _loading = true;
  String? _error;
  String _activeCategory = 'All';
  DateTime? _lastUpdated;

  static const _categories = ['All','Revenue','Profitability','Cash Flow','Liquidity','Efficiency','Customer'];

  static const _kpiMeta = {
    'revenue_total_sales':       {'name': 'Total Sales',           'cat': 'Revenue',        'fmt': 'currency'},
    'revenue_growth_rate':       {'name': 'Revenue Growth',        'cat': 'Revenue',        'fmt': 'percent'},
    'gross_profit':              {'name': 'Gross Profit',          'cat': 'Profitability',  'fmt': 'currency'},
    'gross_profit_margin':       {'name': 'Gross Profit Margin',   'cat': 'Profitability',  'fmt': 'percent'},
    'operating_profit':          {'name': 'Operating Profit',      'cat': 'Profitability',  'fmt': 'currency'},
    'net_profit':                {'name': 'Net Profit',            'cat': 'Profitability',  'fmt': 'currency'},
    'net_profit_margin':         {'name': 'Net Profit Margin',     'cat': 'Profitability',  'fmt': 'percent'},
    'operating_cash_flow':       {'name': 'Operating Cash Flow',   'cat': 'Cash Flow',      'fmt': 'currency'},
    'free_cash_flow':            {'name': 'Free Cash Flow',        'cat': 'Cash Flow',      'fmt': 'currency'},
    'current_ratio':             {'name': 'Current Ratio',         'cat': 'Liquidity',      'fmt': 'ratio'},
    'quick_ratio':               {'name': 'Quick Ratio',           'cat': 'Liquidity',      'fmt': 'ratio'},
    'working_capital':           {'name': 'Working Capital',       'cat': 'Liquidity',      'fmt': 'currency'},
    'debt_to_equity':            {'name': 'Debt to Equity',        'cat': 'Liquidity',      'fmt': 'ratio'},
    'asset_turnover':            {'name': 'Asset Turnover',        'cat': 'Efficiency',     'fmt': 'ratio'},
    'inventory_turnover':        {'name': 'Inventory Turnover',    'cat': 'Efficiency',     'fmt': 'ratio'},
    'days_sales_outstanding':    {'name': 'Days Sales Outstanding','cat': 'Efficiency',     'fmt': 'days'},
    'return_on_assets':          {'name': 'Return on Assets',      'cat': 'Efficiency',     'fmt': 'percent'},
    'return_on_equity':          {'name': 'Return on Equity',      'cat': 'Efficiency',     'fmt': 'percent'},
    'customer_lifetime_value':   {'name': 'Customer LTV',          'cat': 'Customer',       'fmt': 'currency'},
    'customer_acquisition_cost': {'name': 'Customer CAC',          'cat': 'Customer',       'fmt': 'currency'},
  };

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client
          .from('vw_kpi_latest_values')
          .select('kpi_key, value, value_formatted, delta_pct, period')
          .eq('rn', 1);
      setState(() {
        _kpis = List<Map<String, dynamic>>.from(data);
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatValue(dynamic value, String fmt) {
    if (value == null) return '—';
    final v = (value as num).toDouble();
    switch (fmt) {
      case 'currency':
        if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(2)}M';
        if (v >= 1000)    return '₦${(v / 1000).toStringAsFixed(1)}K';
        return '₦${v.toStringAsFixed(0)}';
      case 'percent': return '${v.toStringAsFixed(1)}%';
      case 'ratio':   return '${v.toStringAsFixed(2)}x';
      case 'days':    return '${v.toStringAsFixed(0)} days';
      default:        return v.toStringAsFixed(2);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _kpis.where((k) {
      final meta = _kpiMeta[k['kpi_key']];
      if (meta == null) return false;
      if (_activeCategory == 'All') return true;
      return meta['cat'] == _activeCategory;
    }).toList();
  }

  Map<String, dynamic>? _find(String key) =>
      _kpis.cast<Map<String, dynamic>?>().firstWhere(
        (k) => k?['kpi_key'] == key, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF1a5c2e);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top bar
          Container(
            color: green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const Text('KPI Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_lastUpdated != null)
                  Text(
                    'Updated ${_lastUpdated!.hour}:${_lastUpdated!.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _loadKpis,
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text('Refresh', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: green))
                : _error != null
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 12),
                          Text('Failed to load KPIs', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadKpis, child: const Text('Retry')),
                        ],
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary cards
                            Row(children: [
                              _SummaryCard(
                                label: 'Total Revenue',
                                value: _formatValue(_find('revenue_total_sales')?['value'], 'currency'),
                                delta: _find('revenue_total_sales')?['delta_pct'],
                                icon: Icons.trending_up,
                                iconColor: Colors.green,
                                iconBg: const Color(0xFFE8F5E9),
                              ),
                              const SizedBox(width: 12),
                              _SummaryCard(
                                label: 'Net Profit',
                                value: _formatValue(_find('net_profit')?['value'], 'currency'),
                                delta: _find('net_profit')?['delta_pct'],
                                icon: Icons.monetization_on_outlined,
                                iconColor: Colors.blue,
                                iconBg: const Color(0xFFE3F2FD),
                              ),
                              const SizedBox(width: 12),
                              _SummaryCard(
                                label: 'Operating Cash Flow',
                                value: _formatValue(_find('operating_cash_flow')?['value'], 'currency'),
                                delta: _find('operating_cash_flow')?['delta_pct'],
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: Colors.orange,
                                iconBg: const Color(0xFFFFF3E0),
                              ),
                            ]),
                            const SizedBox(height: 20),

                            // Category filter chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(cat),
                                    selected: _activeCategory == cat,
                                    onSelected: (_) => setState(() => _activeCategory = cat),
                                    selectedColor: green,
                                    labelStyle: TextStyle(
                                      color: _activeCategory == cat ? Colors.white : Colors.black87,
                                      fontSize: 12,
                                    ),
                                    checkmarkColor: Colors.white,
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // KPI grid
                            _buildKpiGrid(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No KPIs found for this category.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in filtered) {
      final cat = (_kpiMeta[row['kpi_key']]?['cat'] as String?) ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(row);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(entry.key,
                style: const TextStyle(color: Color(0xFF1a5c2e), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: entry.value.length,
            itemBuilder: (context, i) {
              final row = entry.value[i];
              final meta = _kpiMeta[row['kpi_key']];
              if (meta == null) return const SizedBox.shrink();
              final delta = row['delta_pct'] as num?;
              return _KpiCard(
                name: meta['name'] as String,
                value: _formatValue(row['value'], meta['fmt'] as String),
                delta: delta?.toDouble(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      )).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final double? delta;
  final IconData icon;
  final Color iconColor, iconBg;
  const _SummaryCard({required this.label, required this.value,
      this.delta, required this.icon, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              if (delta != null)
                Text(
                  '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}% vs last period',
                  style: TextStyle(fontSize: 11, color: delta! >= 0 ? Colors.green : Colors.red),
                ),
            ],
          )),
        ]),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String name, value;
  final double? delta;
  const _KpiCard({required this.name, required this.value, this.delta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(delta! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 12, color: delta! >= 0 ? Colors.green : Colors.red),
              const SizedBox(width: 3),
              Text('${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: delta! >= 0 ? Colors.green : Colors.red)),
            ]),
          ],
        ],
      ),
    );
  }
}
