import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/branch/presentation/providers/branch_provider.dart';
import 'package:erp_app/features/accounting/presentation/providers/accounting_provider.dart';

class BranchRevenueChart extends ConsumerWidget {
  const BranchRevenueChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchNotifierProvider);

    return branchesAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()))),
      error:   (e, _) => Text('$e'),
      data: (branches) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue by Branch',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: branches.isEmpty
                      ? const Center(child: Text('No branch data'))
                      : _BarChartWidget(branches: branches, ref: ref),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BarChartWidget extends ConsumerWidget {
  final List branches;
  const _BarChartWidget({required this.branches, required WidgetRef ref}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 1000000,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              Fmt.currency(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 56,
            getTitlesWidget: (v, _) => Text(Fmt.number(v / 1000) + 'k',
                style: const TextStyle(fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= branches.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(branches[idx].name.split(' ').first,
                    style: const TextStyle(fontSize: 10)),
              );
            },
          )),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(branches.length, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: 0, color: Colors.green, width: 20, borderRadius: BorderRadius.circular(4)),
          ],
        )),
      ),
    );
  }
}
