import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:erp_app/features/inventory/domain/entities/inventory_stock.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});
  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(authNotifierProvider).valueOrNull;
    final branchId    = user?.isAdmin == true ? null : user?.branchId;
    final stockAsync  = ref.watch(inventoryStreamProvider(branchId));

    return Scaffold(
      body: Column(
        children: [
          AppBar(
            title: const Text('Inventory'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
            ),
          ),
          Expanded(
            child: stockAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final filtered = _search.isEmpty
                    ? items
                    : items.where((i) =>
                        i.productName.toLowerCase().contains(_search) ||
                        (i.sku?.toLowerCase().contains(_search) ?? false) ||
                        i.branchName.toLowerCase().contains(_search)).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No inventory data'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width),
                    child: DataTable(
                      sortAscending: true,
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
                        DataColumn(label: Text('Last Updated')),
                      ],
                      rows: filtered.map((s) => DataRow(
                        cells: [
                          DataCell(Text(s.productName,
                              style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(s.sku ?? '—')),
                          DataCell(Text(s.branchName)),
                          DataCell(Text(Fmt.number(s.stockQuantity),
                              style: TextStyle(
                                color: s.isLowStock ? Colors.red[700] : null,
                                fontWeight: s.isLowStock ? FontWeight.bold : null,
                              ))),
                          DataCell(Text(Fmt.number(s.reorderLevel))),
                          DataCell(Text(s.unit)),
                          DataCell(_StatusChip(isLow: s.isLowStock)),
                          DataCell(Text(Fmt.date(s.lastUpdated))),
                        ],
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isLow;
  const _StatusChip({required this.isLow});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(isLow ? 'Low Stock' : 'Healthy',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    backgroundColor: isLow
        ? Colors.red.withOpacity(0.1)
        : Colors.green.withOpacity(0.1),
    side: BorderSide(color: isLow ? Colors.red : Colors.green, width: 0.5),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
  );
}
