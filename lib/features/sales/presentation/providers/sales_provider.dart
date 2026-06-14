import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_app/core/constants/app_constants.dart';
import 'package:erp_app/core/network/supabase_client.dart';
import 'package:erp_app/features/sales/domain/entities/sale.dart';

// Sales list (realtime)
final salesStreamProvider =
    StreamProvider.family<List<Sale>, String?>((ref, branchId) {
  final client = ref.watch(supabaseClientProvider);

  return client
      .from(AppConstants.tableSales)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => (data).map((e) => _saleFromJson(e)).toList());
});

Sale _saleFromJson(Map<String, dynamic> json) => Sale(
  id:            json['id'] as String,
  branchId:      json['branch_id'] as String,
  invoiceNumber: json['invoice_number'] as String,
  customerName:  json['customer_name'] as String?,
  customerPhone: json['customer_phone'] as String?,
  paymentMethod: PaymentMethod.values
      .firstWhere((m) => m.name == (json['payment_method'] ?? 'cash')),
  status:        SaleStatus.values
      .firstWhere((s) => s.name == (json['status'] ?? 'draft')),
  totalAmount:   (json['total_amount'] as num?)?.toDouble() ?? 0,
  amountPaid:    (json['amount_paid'] as num?)?.toDouble() ?? 0,
  notes:         json['notes'] as String?,
  items:         const [],   // loaded separately when needed
  createdAt:     DateTime.parse(json['created_at'] as String),
);

// Sale creation notifier
class SaleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<String> createDraft({
    required String branchId,
    required String createdBy,
    String?  customerName,
    String?  customerPhone,
    String?  notes,
    required PaymentMethod paymentMethod,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final now    = DateTime.now();
    final invoiceNum = 'INV-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch % 100000}';

    final result = await client.from(AppConstants.tableSales).insert({
      'branch_id':      branchId,
      'invoice_number': invoiceNum,
      'customer_name':  customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod.name,
      'notes':          notes,
      'created_by':     createdBy,
    }).select().single();

    return result['id'] as String;
  }

  Future<void> addItem({
    required String saleId,
    required String productId,
    required double quantity,
    required double unitPrice,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from(AppConstants.tableSaleItems).insert({
      'sale_id':    saleId,
      'product_id': productId,
      'quantity':   quantity,
      'unit_price': unitPrice,
    });
    // Recompute total
    final items = await client
        .from(AppConstants.tableSaleItems)
        .select('line_total')
        .eq('sale_id', saleId);
    final total = (items as List).fold<double>(
        0, (sum, e) => sum + ((e['line_total'] as num?)?.toDouble() ?? 0));
    await client.from(AppConstants.tableSales)
        .update({'total_amount': total})
        .eq('id', saleId);
  }

  Future<void> confirmSale({
    required String saleId,
    required String confirmedBy,
    required double amountPaid,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from(AppConstants.tableSales).update({
      'status':       'confirmed',
      'confirmed_by': confirmedBy,
      'confirmed_at': DateTime.now().toIso8601String(),
      'amount_paid':  amountPaid,
    }).eq('id', saleId);
    // Trigger on DB auto-creates inventory_events + transaction
  }

  Future<void> cancelSale(String saleId) async {
    final client = ref.read(supabaseClientProvider);
    await client.from(AppConstants.tableSales)
        .update({'status': 'cancelled'})
        .eq('id', saleId)
        .eq('status', 'draft');   // can only cancel drafts
  }
}

final saleNotifierProvider = NotifierProvider<SaleNotifier, void>(SaleNotifier.new);
