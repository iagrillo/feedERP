import 'package:flutter/material.dart';
import 'package:erp_app/core/utils/formatters.dart';
import 'package:erp_app/features/sales/domain/entities/sale.dart';

class SaleDetailPage extends StatelessWidget {
  final Sale sale;
  const SaleDetailPage({super.key, required this.sale});

  static const _green = Color(0xFF1a5c2e);

  Color get _statusColor => switch (sale.status) {
        SaleStatus.confirmed => Colors.green,
        SaleStatus.cancelled => Colors.red,
        SaleStatus.draft     => Colors.orange,
      };

  String get _paymentLabel => switch (sale.paymentMethod) {
        PaymentMethod.cash     => 'Cash',
        PaymentMethod.transfer => 'Transfer',
        PaymentMethod.credit   => 'Credit',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top bar
          Container(
            color: _green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(sale.invoiceNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _statusColor.withOpacity(0.4)),
                              ),
                              child: Text(sale.status.name,
                                  style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Text(Fmt.dateTime(sale.createdAt),
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(Fmt.currency(sale.totalAmount),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Total Amount', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer + Payment info
                  Row(
                    children: [
                      Expanded(child: _InfoCard(
                        title: 'Customer',
                        rows: [
                          _InfoRow('Name', sale.customerName ?? 'Walk-in customer'),
                          _InfoRow('Phone', sale.customerPhone ?? '—'),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoCard(
                        title: 'Payment',
                        rows: [
                          _InfoRow('Method', _paymentLabel),
                          _InfoRow('Paid', Fmt.currency(sale.amountPaid)),
                          _InfoRow('Balance', Fmt.currency(sale.balance),
                              valueColor: sale.balance > 0 ? Colors.red : Colors.green),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Items
                  const Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Header row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                              Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (sale.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No items recorded', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ...sale.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(item.productName ?? item.productId, style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 1, child: Text(item.quantity.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 2, child: Text(Fmt.currency(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 2, child: Text(Fmt.currency(item.lineTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),

                  if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(sale.notes!, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
