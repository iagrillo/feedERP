import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/branch/data/models/branch_model.dart';
import 'package:erp_app/features/products/data/models/product_model.dart';

class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({super.key});
  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Stock Transfers'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('New Transfer'),
                style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => setState(() => _showForm = !_showForm),
              ),
            ),
          ],
        ),
        if (_showForm) _TransferForm(onDone: () => setState(() => _showForm = false)),
        const Expanded(child: _TransfersList()),
      ]),
    );
  }
}

class _TransfersList extends ConsumerWidget {
  const _TransfersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authNotifierProvider).valueOrNull;
    final client = ref.watch(supabaseClientProvider);

    return FutureBuilder(
      future: client.from(AppConstants.tableTransfers)
          .select('*, from_branch:branches!from_branch_id(name), to_branch:branches!to_branch_id(name)')
          .order('created_at', ascending: false),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        final data = (snap.data as List?) ?? [];
        if (data.isEmpty) return const Center(child: Text('No transfers yet'));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t   = data[i] as Map<String, dynamic>;
            final st  = t['status'] as String;
            final clr = switch (st) {
              'completed'  => Colors.green,
              'cancelled'  => Colors.red,
              'in_transit' => Colors.blue,
              _            => Colors.orange,
            };
            return Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(backgroundColor: clr.withOpacity(0.1),
                  child: Icon(Icons.swap_horiz, color: clr)),
              title: Row(children: [
                Text((t['from_branch'] as Map?)?['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16)),
                Text((t['to_branch'] as Map?)?['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ]),
              subtitle: Text(Fmt.date(DateTime.tryParse(t['created_at'] as String? ?? '')),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: clr.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(st, style: TextStyle(color: clr, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ));
          },
        );
      },
    );
  }
}

class _TransferForm extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const _TransferForm({required this.onDone});
  @override
  ConsumerState<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends ConsumerState<_TransferForm> {
  List<BranchModel> _branches  = [];
  List<ProductModel> _products = [];
  String? _toBranchId;
  ProductModel? _product;
  final _qtyCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final b = await client.from(AppConstants.tableBranches).select().eq('is_active', true);
    final p = await client.from(AppConstants.tableProducts).select().eq('is_active', true).order('name');
    setState(() {
      _branches = (b as List).map((e) => BranchModel.fromJson(e)).toList();
      _products = (p as List).map((e) => ProductModel.fromJson(e)).toList();
    });
  }

  Future<void> _submit() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user?.branchId == null || _toBranchId == null || _product == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final result = await client.from(AppConstants.tableTransfers).insert({
        'from_branch_id': user!.branchId,
        'to_branch_id':   _toBranchId,
        'notes':          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'created_by':     user.id,
      }).select().single();

      final tid = result['id'] as String;

      await client.from(AppConstants.tableTransferItems).insert({
        'transfer_id': tid,
        'product_id':  _product!.id,
        'quantity':    qty,
      });

      // Auto-complete (in production, admin may approve)
      await client.from(AppConstants.tableTransfers).update({
        'status':      'completed',
        'approved_by': user.id,
        'approved_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', tid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed'), backgroundColor: Colors.green));
      widget.onDone();
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
    final otherBranches = _branches.where((b) => b.id != user?.branchId).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('New Stock Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _toBranchId,
              decoration: const InputDecoration(labelText: 'To Branch'),
              items: otherBranches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: (v) => setState(() => _toBranchId = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<ProductModel>(
              value: _product,
              decoration: const InputDecoration(labelText: 'Product'),
              items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (v) => setState(() => _product = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'))),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: ElevatedButton(onPressed: _loading ? null : _submit,
                child: _loading ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Transfer Stock'))),
            const SizedBox(width: 8),
            TextButton(onPressed: widget.onDone, child: const Text('Cancel')),
          ]),
        ]),
      ),
    );
  }
}


