import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';

final _purchasesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user   = ref.watch(authNotifierProvider).valueOrNull;
  final client = ref.watch(supabaseClientProvider);
  var q = client.from(AppConstants.tablePurchases).select('*, branches(name)');
  final query = (user?.isAdmin == false && user?.branchId != null)
      ? q.eq('branch_id', user!.branchId!).order('created_at', ascending: false)
      : q.order('created_at', ascending: false);
  return (await query).cast<Map<String, dynamic>>();
});

class PurchasesListPage extends ConsumerWidget {
  const PurchasesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(_purchasesProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      body: Column(children: [
        AppBar(
          title: const Text('Purchases'),
          actions: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Purchase'),
                  style: ElevatedButton.styleFrom(minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => context.go(user?.isAdmin == true
                      ? '/admin/purchases/create'
                      : '/branch/purchases/create'),
                ),
              ),
          ],
        ),
        Expanded(child: purchasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data:    (purchases) => purchases.isEmpty
              ? const Center(child: Text('No purchases recorded'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = purchases[i];
                    return _PurchaseTile(purchase: p, onRefresh: () => ref.invalidate(_purchasesProvider));
                  },
                ),
        )),
      ]),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onRefresh;
  const _PurchaseTile({required this.purchase, required this.onRefresh});

  Color _statusColor(String st) {
    switch (st) {
      case 'confirmed':  return Colors.blue;
      case 'ordered':    return Colors.orange;
      case 'delivered':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  IconData _statusIcon(String st) {
    switch (st) {
      case 'confirmed':  return Icons.check_circle_outline;
      case 'ordered':    return Icons.local_shipping_outlined;
      case 'delivered':  return Icons.inventory_2_outlined;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.shopping_cart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final st          = purchase['status'] as String;
    final clr         = _statusColor(st);
    final branchMap   = purchase['branches'] as Map<String, dynamic>?;
    final destination = branchMap?['name'] as String? ?? 'Unknown';
    final createdAt   = DateTime.tryParse(purchase['created_at'] as String? ?? '');
    final dateStr     = createdAt != null ? Fmt.date(createdAt) : '';
    final timeStr     = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: clr.withOpacity(0.1),
              child: Icon(_statusIcon(st), color: clr),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(purchase['supplier_name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(destination, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$dateStr  $timeStr',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              if (purchase['invoice_ref'] != null) ...[
                const SizedBox(height: 2),
                Text('Ref: ${purchase['invoice_ref']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ])),
            const SizedBox(width: 12),
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Fmt.currency(purchase['total_amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: clr.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(st, style: TextStyle(color: clr, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseDetailSheet(
          purchase: purchase, onRefresh: onRefresh),
    );
  }
}

class _PurchaseDetailSheet extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onRefresh;
  const _PurchaseDetailSheet({required this.purchase, required this.onRefresh});
  @override State<_PurchaseDetailSheet> createState() => _PurchaseDetailSheetState();
}

class _PurchaseDetailSheetState extends State<_PurchaseDetailSheet> {
  final _passwordCtrl      = TextEditingController();
  final _deliveredByCtrl   = TextEditingController();
  bool _loading            = false;
  bool _obscurePassword    = true;

  Color _statusColor(String st) {
    switch (st) {
      case 'confirmed':  return Colors.blue;
      case 'ordered':    return Colors.orange;
      case 'delivered':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus == 'delivered') {
      // Require password and delivered-by for delivery confirmation
      final confirmed = await _showDeliveryDialog();
      if (!confirmed) return;
    }
    setState(() => _loading = true);
    try {
      final client = ProviderScope.containerOf(context).read(supabaseClientProvider);
      final update = <String, dynamic>{'status': newStatus};
      if (newStatus == 'delivered') {
        update['confirmed_at']  = DateTime.now().toIso8601String();
        update['confirmed_by']  = _deliveredByCtrl.text.trim();
      }
      await client.from(AppConstants.tablePurchases)
          .update(update)
          .eq('id', widget.purchase['id'] as String);
      if (!mounted) return;
      widget.onRefresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'),
              backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _showDeliveryDialog() async {
    _passwordCtrl.clear();
    _deliveredByCtrl.clear();
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Confirm Delivery'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Enter your password and delivery details to confirm.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _deliveredByCtrl,
              decoration: const InputDecoration(
                labelText: 'Delivery Confirmed By *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDlg(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_deliveredByCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter who confirmed delivery')));
                  return;
                }
                if (_passwordCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your password')));
                  return;
                }
                // Verify password via Supabase auth
                try {
                  final client = ProviderScope.containerOf(context).read(supabaseClientProvider);
                  final user   = client.auth.currentUser;
                  if (user?.email == null) {
                    Navigator.pop(ctx, false);
                    return;
                  }
                  await client.auth.signInWithPassword(
                      email: user!.email!, password: _passwordCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incorrect password'),
                            backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p           = widget.purchase;
    final st          = p['status'] as String;
    final clr         = _statusColor(st);
    final branchMap   = p['branches'] as Map<String, dynamic>?;
    final destination = branchMap?['name'] as String? ?? 'Unknown';
    final createdAt   = DateTime.tryParse(p['created_at'] as String? ?? '');
    final dateStr     = createdAt != null ? Fmt.date(createdAt) : '';
    final timeStr     = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(24),
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(p['supplier_name'] as String,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: clr.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(st, style: TextStyle(color: clr,
                      fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 16),

              // Info rows
              _infoRow(Icons.location_on_outlined, 'Destination', destination),
              _infoRow(Icons.calendar_today_outlined, 'Date', dateStr),
              _infoRow(Icons.access_time, 'Time', timeStr),
              _infoRow(Icons.payments_outlined, 'Payment',
                  (p['payment_method'] as String? ?? '').toUpperCase()),
              _infoRow(Icons.attach_money, 'Total', Fmt.currency(p['total_amount'])),
              if (p['invoice_ref'] != null)
                _infoRow(Icons.receipt_outlined, 'Invoice Ref', p['invoice_ref'] as String),
              if (p['notes'] != null)
                _infoRow(Icons.notes_outlined, 'Notes', p['notes'] as String),
              if (p['confirmed_by'] != null)
                _infoRow(Icons.verified_user_outlined, 'Delivery Confirmed By',
                    p['confirmed_by'] as String),
              if (p['confirmed_at'] != null) ...[
                _infoRow(Icons.check_circle_outline, 'Delivered At',
                    Fmt.date(DateTime.tryParse(p['confirmed_at'] as String)!)),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Status update buttons
              if (st != 'cancelled' && st != 'delivered') ...[
                const Text('Update Status',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 14, color: Color(0xFF1B5E20))),
                const SizedBox(height: 12),
                if (st == 'draft' || st == 'confirmed')
                  _statusBtn(
                    label: 'Mark as Ordered',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.orange,
                    onTap: () => _updateStatus('ordered'),
                  ),
                if (st == 'ordered') ...[
                  const SizedBox(height: 8),
                  _statusBtn(
                    label: 'Mark as Delivered',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.green,
                    onTap: () => _updateStatus('delivered'),
                  ),
                ],
              ],

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
      const SizedBox(width: 12),
      Text('$label: ', style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13)),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 13, color: Colors.grey))),
    ]),
  );

  Widget _statusBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _loading ? null : onTap,
    ),
  );
}
