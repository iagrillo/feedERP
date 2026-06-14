import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/sales/domain/entities/sale.dart';
import 'package:erp_app/features/sales/presentation/providers/sales_provider.dart';
import 'package:erp_app/features/products/data/models/product_model.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';

class _CartItem {
  final String productId;
  final String productName;
  double quantity;
  final double unitPrice;
  _CartItem({required this.productId, required this.productName,
      required this.quantity, required this.unitPrice});
  double get lineTotal => quantity * unitPrice;
}

class CreateSalePage extends ConsumerStatefulWidget {
  const CreateSalePage({super.key});
  @override
  ConsumerState<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends ConsumerState<CreateSalePage> {
  final _customerCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final List<_CartItem> _cart  = [];
  bool _loading = false;
  String? _saleId;

  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final client = ref.read(supabaseClientProvider);
    final data   = await client.from(AppConstants.tableProducts)
        .select().eq('is_active', true).order('name');
    setState(() => _products = (data as List).map((e) => ProductModel.fromJson(e)).toList());
  }

  double get _total => _cart.fold(0, (s, i) => s + i.lineTotal);

  void _addProduct(ProductModel product, double qty, double price) {
    final existing = _cart.indexWhere((c) => c.productId == product.id);
    setState(() {
      if (existing >= 0) {
        _cart[existing].quantity += qty;
      } else {
        _cart.add(_CartItem(productId: product.id, productName: product.name,
            quantity: qty, unitPrice: price));
      }
    });
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user   = ref.read(authNotifierProvider).valueOrNull!;
      final notifier = ref.read(saleNotifierProvider.notifier);

      // Create draft
      final saleId = await notifier.createDraft(
        branchId:      user.branchId!,
        createdBy:     user.id,
        customerName:  _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        notes:         _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        paymentMethod: _paymentMethod,
      );

      // Add items
      for (final item in _cart) {
        await notifier.addItem(
          saleId:    saleId,
          productId: item.productId,
          quantity:  item.quantity,
          unitPrice: item.unitPrice,
        );
      }

      // Confirm (triggers DB inventory event + transaction)
      await notifier.confirmSale(
        saleId:      saleId,
        confirmedBy: user.id,
        amountPaid:  _total,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale confirmed'), backgroundColor: Colors.green));
      context.go('/branch/sales');
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Left: Customer + Product picker 
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader('Customer Details'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _customerCtrl,
                      decoration: const InputDecoration(labelText: 'Customer Name (optional)')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone (optional)')),
                  const SizedBox(height: 20),
                  _SectionHeader('Payment Method'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: PaymentMethod.values.map((m) =>
                    ChoiceChip(
                      label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                      selected: _paymentMethod == m,
                      onSelected: (_) => setState(() => _paymentMethod = m),
                    ),
                  ).toList()),
                  const SizedBox(height: 20),
                  _SectionHeader('Add Products'),
                  const SizedBox(height: 12),
                  _ProductPicker(products: _products, onAdd: _addProduct),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          //  Right: Cart 
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cart (${_cart.length} items)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(Fmt.currency(_total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                              color: Color(0xFF1B5E20))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('No items added'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final item = _cart[i];
                            return ListTile(
                              dense: true,
                              title: Text(item.productName),
                              subtitle: Text('${Fmt.number(item.quantity)} — ${Fmt.currency(item.unitPrice)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(Fmt.currency(item.lineTotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() => _cart.removeAt(i)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmSale,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirm Sale - N'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)));
}

class _ProductPicker extends StatefulWidget {
  final List<ProductModel> products;
  final void Function(ProductModel, double, double) onAdd;
  const _ProductPicker({required this.products, required this.onAdd});
  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  ProductModel? _selected;
  final _qtyCtrl   = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButtonFormField<ProductModel>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Select Product'),
            items: widget.products.map((p) => DropdownMenuItem(
              value: p, child: Text(p.name))).toList(),
            onChanged: (p) => setState(() { _selected = p; _priceCtrl.text = ''; }),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Qty'),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unit Price',
                prefixText: '\u20A6 ',
                helperText: _selected != null ? 'Enter selling price' : null,
              ),
            )),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              onPressed: () {
                if (_selected == null) return;
                final qty   = double.tryParse(_qtyCtrl.text) ?? 0;
                final price = double.tryParse(_priceCtrl.text) ?? 0;
                if (qty <= 0 || price <= 0) return;
                widget.onAdd(_selected!, qty, price);
                setState(() { _qtyCtrl.text = '1'; _priceCtrl.clear(); _selected = null; });
              },
            ),
          ),
        ]),
      ),
    );
  }
}





