import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/inventory/presentation/providers/inventory_provider.dart';

class GlobalInventoryPage extends ConsumerWidget {
  const GlobalInventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(inventoryStreamProvider(null));
    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Global Inventory'),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.circle, color: Colors.green, size: 10),
                label: const Text('Live'),
                backgroundColor: Colors.green.withOpacity(0.1),
              )),
          ],
        ),
        Expanded(child: stockAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (items) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary.withOpacity(0.08)),
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Stock'), numeric: true),
                DataColumn(label: Text('Reorder'), numeric: true),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Status')),
              ],
              rows: items.map((s) => DataRow(
                color: s.isLowStock
                    ? WidgetStateProperty.all(Colors.red.withOpacity(0.04))
                    : null,
                cells: [
                  DataCell(Text(s.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(s.sku ?? '')),
                  DataCell(Text(s.branchName)),
                  DataCell(Text(Fmt.number(s.stockQuantity),
                      style: TextStyle(
                          color: s.isLowStock ? Colors.red[700] : null,
                          fontWeight: s.isLowStock ? FontWeight.bold : null))),
                  DataCell(Text(Fmt.number(s.reorderLevel))),
                  DataCell(Text(s.unit)),
                  DataCell(Chip(
                    label: Text(s.isLowStock ? 'Low' : 'OK',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: s.isLowStock
                        ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )),
                ],
              )).toList(),
            ),
          ),
        )),
      ]),
    );
  }
}


