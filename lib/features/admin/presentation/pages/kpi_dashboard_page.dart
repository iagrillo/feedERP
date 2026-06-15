import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/features/admin/presentation/providers/kpi_provider.dart';

class KpiDashboardPage extends ConsumerWidget {
  const KpiDashboardPage({super.key});

  static const _categories = ['All','Revenue','Profitability','Cash Flow','Liquidity','Efficiency','Customer'];

  static const _kpiMeta = {
    'revenue_total_sales':  {'name': 'Total Sales',           'cat': 'Revenue',       'fmt': 'currency'},
    'revenue_growth_rate':  {'name': 'Revenue Growth',        'cat': 'Revenue',       'fmt': 'percent'},
    'gross_profit':         {'name': 'Gross Profit',          'cat': 'Profitability', 'fmt': 'currency'},
    'gross_profit_margin':  {'name': 'Gross Profit Margin',   'cat': 'Profitability', 'fmt': 'percent'},
    'operating_profit':     {'name': 'Operating Profit',      'cat': 'Profitability', 'fmt': 'currency'},
    'net_profit':           {'name': 'Net Profit',            'cat': 'Profitability', 'fmt': 'currency'},
    'net_profit_margin':    {'name': 'Net Profit Margin',     'cat': 'Profitability', 'fmt': 'percent'},
    'operating_cash_flow':  {'name': 'Operating Cash Flow',   'cat': 'Cash Flow',     'fmt': 'currency'},
    'free_cash_flow':       {'name': 'Free Cash Flow',        'cat': 'Cash Flow',     'fmt': 'currency'},
    'total_purchases':      {'name': 'Total Purchases',       'cat': 'Cash Flow',     'fmt': 'currency'},
    'total_expenses':       {'name': 'Total Expenses',        'cat': 'Cash Flow',     'fmt': 'currency'},
    'current_ratio':        {'name': 'Current Ratio',         'cat': 'Liquidity',     'fmt': 'ratio'},
    'quick_ratio':          {'name': 'Quick Ratio',           'cat': 'Liquidity',     'fmt': 'ratio'},
    'working_capital':      {'name': 'Working Capital',       'cat': 'Liquidity',     'fmt': 'currency'},
    'debt_to_equity':       {'name': 'Debt to Equity',        'cat': 'Liquidity',     'fmt': 'ratio'},
    'asset_turnover':       {'name': 'Asset Turnover',        'cat': 'Efficiency',    'fmt': 'ratio'},
    'inventory_turnover':   {'name': 'Inventory Turnover',    'cat': 'Efficiency',    'fmt': 'ratio'},
    'days_sales_outstanding':{'name':'Days Sales Outstanding','cat': 'Efficiency',    'fmt': 'days'},
    'return_on_assets':     {'name': 'Return on Assets',      'cat': 'Efficiency',    'fmt': 'percent'},
    'return_on_equity':     {'name': 'Return on Equity',      'cat': 'Efficiency',    'fmt': 'percent'},
    'customer_lifetime_value':   {'name': 'Customer LTV',     'cat': 'Customer',      'fmt': 'currency'},
    'customer_acquisition_cost': {'name': 'Customer CAC',     'cat': 'Customer',      'fmt': 'currency'},
  };

  static const _green = Color(0xFF1a5c2e);

  String _fmt(double value, String type) {
    switch (type) {
      case 'currency':
        final neg = value < 0 ? '-' : '';
        final abs = value.abs();
        if (abs >= 1000000) return '$neg₦${(abs / 1000000).toStringAsFixed(2)}M';
        if (abs >= 1000)    return '$neg₦${(abs / 1000).toStringAsFixed(1)}K';
        return '$neg₦${abs.toStringAsFixed(0)}';
      case 'percent': return '${value.toStringAsFixed(1)}%';
      case 'ratio':   return '${value.toStringAsFixed(2)}x';
      case 'days':    return '${value.toStringAsFixed(0)} days';
      default:        return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync     = ref.watch(kpiValuesProvider);
    final branchAsync  = ref.watch(branchesProvider);
    final selectedBranch = ref.watch(selectedBranchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top bar
          Container(
            color: _green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Text('KPI Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(width: 20),

                // Branch dropdown
                branchAsync.when(
                  loading: () => const SizedBox(width: 160, child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (branches) => Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedBranch,
                        dropdownColor: _green,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Branches', style: TextStyle(color: Colors.white)),
                          ),
                          ...branches.map((b) => DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(b.name, style: const TextStyle(color: Colors.white)),
                              )),
                        ],
                        onChanged: (val) {
                          ref.read(selectedBranchProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.invalidate(kpiValuesProvider),
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

          // Body
          Expanded(
            child: kpiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _green)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    const Text('Failed to load KPI data', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(e.toString(), style: const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(kpiValuesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (kpis) => _KpiBody(kpis: kpis, fmt: _fmt, kpiMeta: _kpiMeta, categories: _categories),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiBody extends StatefulWidget {
  final List<KpiValue> kpis;
  final String Function(double, String) fmt;
  final Map<String, Map<String, String>> kpiMeta;
  final List<String> categories;
  const _KpiBody({required this.kpis, required this.fmt, required this.kpiMeta, required this.categories});

  @override
  State<_KpiBody> createState() => _KpiBodyState();
}

class _KpiBodyState extends State<_KpiBody> {
  String _activeCategory = 'All';

  KpiValue? _find(String key) =>
      widget.kpis.cast<KpiValue?>().firstWhere((k) => k?.kpiKey == key, orElse: () => null);

  List<KpiValue> get _filtered => widget.kpis.where((k) {
        final meta = widget.kpiMeta[k.kpiKey];
        if (meta == null) return false;
        if (_activeCategory == 'All') return true;
        return meta['cat'] == _activeCategory;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final rev      = _find('revenue_total_sales');
    final profit   = _find('net_profit');
    final cashflow = _find('operating_cash_flow');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SummaryCard(
              label: 'Total Revenue',
              value: rev != null ? widget.fmt(rev.value, 'currency') : '₦0',
              delta: rev?.deltaPct,
              icon: Icons.trending_up,
              iconColor: Colors.green,
              iconBg: const Color(0xFFE8F5E9),
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Net Profit',
              value: profit != null ? widget.fmt(profit.value, 'currency') : '₦0',
              delta: profit?.deltaPct,
              icon: Icons.monetization_on_outlined,
              iconColor: Colors.blue,
              iconBg: const Color(0xFFE3F2FD),
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Operating Cash Flow',
              value: cashflow != null ? widget.fmt(cashflow.value, 'currency') : '₦0',
              delta: cashflow?.deltaPct,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.orange,
              iconBg: const Color(0xFFFFF3E0),
            ),
          ]),
          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: _activeCategory == cat,
                  onSelected: (_) => setState(() => _activeCategory = cat),
                  selectedColor: const Color(0xFF1a5c2e),
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

          ..._buildGrouped(),
        ],
      ),
    );
  }

  List<Widget> _buildGrouped() {
    final grouped = <String, List<KpiValue>>{};
    for (final k in _filtered) {
      final cat = widget.kpiMeta[k.kpiKey]?['cat'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(k);
    }
    if (grouped.isEmpty) {
      return [const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: Text('No KPI data for this filter.', style: TextStyle(color: Colors.grey)),
      ))];
    }
    return grouped.entries.map((entry) => Column(
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
          itemBuilder: (_, i) {
            final k    = entry.value[i];
            final meta = widget.kpiMeta[k.kpiKey]!;
            return _KpiCard(
              name:  meta['name']!,
              value: widget.fmt(k.value, meta['fmt']!),
              delta: k.deltaPct,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    )).toList();
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
              if (delta != null && delta != 0)
                Text(
                  '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}% vs last period',
                  style: TextStyle(fontSize: 11,
                      color: delta! >= 0 ? Colors.green : Colors.red),
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
          if (delta != null && delta != 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(delta! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 12, color: delta! >= 0 ? Colors.green : Colors.red),
              const SizedBox(width: 3),
              Text('${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11,
                      color: delta! >= 0 ? Colors.green : Colors.red)),
            ]),
          ],
        ],
      ),
    );
  }
}
