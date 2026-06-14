import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/core/utils/user_role.dart';
import 'package:erp_app/features/products/data/models/product_model.dart';

final _productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data   = await client.from(AppConstants.tableProducts).select().order('name');
  return (data as List).map((e) => ProductModel.fromJson(e)).toList();
});

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  bool _showForm = false;
  final _nameCtrl    = TextEditingController();
  final _skuCtrl     = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _unitCtrl    = TextEditingController(text: 'bag');
  final _reorderCtrl = TextEditingController(text: '0');
  bool _saving = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final user   = ref.read(authNotifierProvider).valueOrNull!;
      await client.from(AppConstants.tableProducts).insert({
        'name':          _nameCtrl.text.trim(),
        'sku':           _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        'description':   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'unit':          _unitCtrl.text.trim().isEmpty ? 'bag' : _unitCtrl.text.trim(),
        'reorder_level': double.tryParse(_reorderCtrl.text) ?? 0,
        'created_by':    user.id,
      });
      ref.invalidate(_productsProvider);
      setState(() { _showForm = false; });
      _nameCtrl.clear(); _skuCtrl.clear(); _descCtrl.clear();
      _unitCtrl.text = 'bag'; _reorderCtrl.text = '0';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user     = ref.watch(authNotifierProvider).valueOrNull;
    final canWrite = user?.role.canWrite ?? false;
    final productsAsync = ref.watch(_productsProvider);

    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Products'),
          actions: [
            if (canWrite)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => setState(() => _showForm = !_showForm),
                ),
              ),
          ],
        ),
        if (_showForm)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextFormField(controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name *'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _skuCtrl,
                      decoration: const InputDecoration(labelText: 'SKU'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit (bag/kg/litre)'))),
                  const SizedBox(width: 12),
                  SizedBox(width: 120, child: TextFormField(controller: _reorderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reorder Level'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description (optional)'))),
                  const SizedBox(width: 12),
                  SizedBox(width: 120, child: ElevatedButton(onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Product'))),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => setState(() => _showForm = false),
                      child: const Text('Cancel')),
                ]),
              ]),
            ),
          ),
        Expanded(child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (products) => products.isEmpty
              ? const Center(child: Text('No products yet'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary.withOpacity(0.08)),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Reorder Level'), numeric: true),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: products.map((p) => DataRow(cells: [
                      DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(p.sku ?? '')),
                      DataCell(Text(p.unit)),
                      DataCell(Text(p.reorderLevel.toStringAsFixed(0))),
                      DataCell(Chip(
                        label: Text(p.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: p.isActive
                            ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )),
                    ])).toList(),
                  ),
                ),
        )),
      ]),
    );
  }
}


