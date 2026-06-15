import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/products/data/models/product_model.dart';
import 'package:erp_app/features/sales/domain/entities/sale.dart';

class _PurchaseItem {
  final String productId;
  final String productName;
  double quantity;
  double unitCost;
  _PurchaseItem({required this.productId, required this.productName,
      required this.quantity, required this.unitCost});
  double get lineTotal => quantity * unitCost;
}

class CreatePurchasePage extends ConsumerStatefulWidget {
  const CreatePurchasePage({super.key});
  @override
  ConsumerState<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends ConsumerState<CreatePurchasePage> {
  final _supplierCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _refCtrl      = TextEditingController();
  final _notesCtrl    = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final List<_PurchaseItem> _items = [];
  List<ProductModel> _products = [];
  bool _loading = false;

  String _destinationType = 'branch';
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _warehouses = [];
  String? _selectedBranchId;
  String? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadBranches();
    _loadWarehouses();
  }

  Future<void> _loadProducts() async {
    final client = ref.read(supabaseClientProvider);
    final data = await client.from(AppConstants.tableProducts)
        .select().eq('is_active', true).order('name');
    setState(() => _products = (data as List).map((e) => ProductModel.fromJson(e)).toList());
  }

  Future<void> _loadBranches() async {
    final client = ref.read(supabaseClientProvider);
    final data = await client.from('branches').select().eq('is_active', true).order('name');
    setState(() => _branches = (data as List).cast<Map<String, dynamic>>());
  }

  Future<void> _loadWarehouses() async {
    final client = ref.read(supabaseClientProvider);
    final data = await client.from('warehouses').select().order('name');
    setState(() => _warehouses = (data as List).cast<Map<String, dynamic>>());
  }

  double get _total => _items.fold(0, (s, i) => s + i.lineTotal);

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull!;

    if (user.isAdmin == true) {
      if (_destinationType == 'branch' && _selectedBranchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a branch')));
        return;
      }
      if (_destinationType == 'warehouse' && _selectedWarehouseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a warehouse')));
        return;
      }
    }
    if (_supplierCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter supplier name')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);

      final result = await client.from(AppConstants.tablePurchases).insert({
        'branch_id': user.isAdmin == true
            ? (_destinationType == 'branch' ? _selectedBranchId : null)
            : user.branchId,
        'warehouse_id': user.isAdmin == true && _destinationType == 'warehouse'
            ? _selectedWarehouseId
            : null,
        'supplier_name':  _supplierCtrl.text.trim(),
        'supplier_phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'invoice_ref':    _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'payment_method': _paymentMethod.name,
        'total_amount':   _total,
        'notes':          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'created_by':     user.id,
      }).select().single();

      final purchaseId = result['id'] as String;

      for (final item in _items) {
        await client.from(AppConstants.tablePurchaseItems).insert({
          'purchase_id': purchaseId,
          'product_id':  item.productId,
          'quantity':    item.quantity,
          'unit_cost':   item.unitCost,
        });
      }

      await client.from(AppConstants.tablePurchases).update({
        'status':       'confirmed',
        'confirmed_by': user.id,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', purchaseId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase recorded & stock updated'),
              backgroundColor: Colors.green));
      context.go('/branch/purchases');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Record Purchase')),
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Supplier Details', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            TextFormField(controller: _supplierCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Name *')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _refCtrl,
                  decoration: const InputDecoration(labelText: 'Invoice Ref'))),
            ]),

            if (user?.isAdmin == true) ...[
              const SizedBox(height: 24),
              const Text('Destination', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _destinationType == 'branch'
                          ? const Color(0xFF1B5E20)
                          : Colors.transparent,
                      foregroundColor: _destinationType == 'branch'
                          ? Colors.white
                          : const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() {
                      _destinationType = 'branch';
                      _selectedBranchId = null;
                      _selectedWarehouseId = null;
                    }),
                    child: const Text('Branch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _destinationType == 'warehouse'
                          ? const Color(0xFF1B5E20)
                          : Colors.transparent,
                      foregroundColor: _destinationType == 'warehouse'
                          ? Colors.white
                          : const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() {
                      _destinationType = 'warehouse';
                      _selectedBranchId = null;
                      _selectedWarehouseId = null;
                    }),
                    child: const Text('Warehouse'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_destinationType == 'branch')
                DropdownButtonFormField<String>(
                  key: const ValueKey('branch_dd'),
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Select Branch *'),
                  items: _branches.map((b) => DropdownMenuItem(
                    value: b['id'] as String,
                    child: Text(b['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                )
              else
                DropdownButtonFormField<String>(
                  key: const ValueKey('warehouse_dd'),
                  value: _selectedWarehouseId,
                  decoration: const InputDecoration(labelText: 'Select Warehouse *'),
                  items: _warehouses.map((w) => DropdownMenuItem(
                    value: w['id'] as String,
                    child: Text(w['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedWarehouseId = v),
                ),
            ],

            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: PaymentMethod.values.map((m) => ChoiceChip(
              label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
              selected: _paymentMethod == m,
              onSelected: (_) => setState(() => _paymentMethod = m),
            )).toList()),
            const SizedBox(height: 20),
            const Text('Products', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            _ItemAdder(products: _products, onAdd: (p, qty, cost) {
              setState(() => _items.add(_PurchaseItem(
                  productId: p.id, productName: p.name,
                  quantity: qty, unitCost: cost)));
            }),
          ]),
        )),
        const VerticalDivider(width: 1),
        Expanded(flex: 2, child: Column(children: [
          Padding(padding: const EdgeInsets.all(20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Items (${_items.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(Fmt.currency(_total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                      color: Color(0xFF1B5E20))),
            ])),
          const Divider(height: 1),
          Expanded(child: _items.isEmpty
              ? const Center(child: Text('No items added'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return ListTile(dense: true,
                      title: Text(item.productName),
                      subtitle: Text('${Fmt.number(item.quantity)} — ${Fmt.currency(item.unitCost)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(Fmt.currency(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _items.removeAt(i))),
                      ]),
                    );
                  })),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Confirm Purchase  ${Fmt.currency(_total)}'),
            )),
        ])),
      ]),
    );
  }
}

class _ItemAdder extends StatefulWidget {
  final List<ProductModel> products;
  final void Function(ProductModel, double, double) onAdd;
  const _ItemAdder({required this.products, required this.onAdd});
  @override State<_ItemAdder> createState() => _ItemAdderState();
}
class _ItemAdderState extends State<_ItemAdder> {
  ProductModel? _sel;
  final _qty  = TextEditingController(text: '1');
  final _cost = TextEditingController();
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      DropdownButtonFormField<ProductModel>(
        value: _sel,
        decoration: const InputDecoration(labelText: 'Select Product'),
        items: widget.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
        onChanged: (p) => setState(() { _sel = p; }),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _qty, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qty'))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: TextFormField(controller: _cost, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cost Price ()', prefixText: ' '))),
      ]),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: () {
          if (_sel == null) return;
          final qty  = double.tryParse(_qty.text) ?? 0;
          final cost = double.tryParse(_cost.text) ?? 0;
          if (qty <= 0 || cost <= 0) return;
          widget.onAdd(_sel!, qty, cost);
          setState(() { _qty.text = '1'; _cost.clear(); _sel = null; });
        },
      )),
    ]),
  ));
}
