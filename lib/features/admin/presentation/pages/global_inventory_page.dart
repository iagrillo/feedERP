import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/inventory/presentation/providers/inventory_provider.dart';

class GlobalInventoryPage extends ConsumerStatefulWidget {
  const GlobalInventoryPage({super.key});
  @override
  ConsumerState<GlobalInventoryPage> createState() => _GlobalInventoryPageState();
}

class _GlobalInventoryPageState extends ConsumerState<GlobalInventoryPage> {
  String? _selectedBranch; // null = All Branches
  String  _search = '';

  @override
  Widget build(BuildContext context) {
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
          data:    (items) {
            // Build distinct branch list from the stream itself
            final branches = {
              for (final s in items) s.branchId: s.branchName
            };

            var filtered = _selectedBranch == null
                ? items
                : items.where((s) => s.branchId == _selectedBranch).toList();

            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              filtered = filtered.where((s) =>
                  s.productName.toLowerCase().contains(q) ||
                  (s.sku?.toLowerCase().contains(q) ?? false)).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    const Text('Branch:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 10),
                    DropdownButton<String?>(
                      value: _selectedBranch,
                      hint: const Text('All Branches'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Branches'),
                        ),
                        ...branches.entries.map((e) => DropdownMenuItem<String?>(
                              value: e.key,
                              child: Text(e.value),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedBranch = val),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by product name or SKU...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No inventory data'))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
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
                              rows: filtered.map((s) => DataRow(
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
                        ),
                ),
              ],
            );
          },
        )),
      ]),
    );
  }
}
