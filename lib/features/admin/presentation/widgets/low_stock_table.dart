import 'package:flutter/material.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/inventory/domain/entities/inventory_stock.dart';

class LowStockTable extends StatelessWidget {
  final List<InventoryStock> items;
  const LowStockTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 12),
            Text('All stock levels are healthy', style: TextStyle(color: Colors.green[700])),
          ]),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Low Stock Alerts (${items.length})',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Current Stock'), numeric: true),
                DataColumn(label: Text('Reorder Level'), numeric: true),
                DataColumn(label: Text('Unit')),
              ],
              rows: items.map((s) => DataRow(
                color: WidgetStateProperty.all(Colors.orange.withOpacity(0.05)),
                cells: [
                  DataCell(Text(s.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(s.branchName)),
                  DataCell(Text(Fmt.number(s.stockQuantity),
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))),
                  DataCell(Text(Fmt.number(s.reorderLevel))),
                  DataCell(Text(s.unit)),
                ],
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
