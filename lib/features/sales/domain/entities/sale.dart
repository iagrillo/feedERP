import 'package:equatable/equatable.dart';

enum SaleStatus { draft, confirmed, cancelled }
enum PaymentMethod { cash, transfer, credit }

class SaleItem extends Equatable {
  final String  id;
  final String  productId;
  final String? productName;
  final double  quantity;
  final double  unitPrice;
  final double  lineTotal;

  const SaleItem({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [id, productId, quantity, unitPrice];
}

class Sale extends Equatable {
  final String        id;
  final String        branchId;
  final String        invoiceNumber;
  final String?       customerName;
  final String?       customerPhone;
  final PaymentMethod paymentMethod;
  final SaleStatus    status;
  final double        totalAmount;
  final double        amountPaid;
  final String?       notes;
  final List<SaleItem> items;
  final DateTime      createdAt;

  const Sale({
    required this.id,
    required this.branchId,
    required this.invoiceNumber,
    this.customerName,
    this.customerPhone,
    required this.paymentMethod,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  double get balance => totalAmount - amountPaid;

  @override
  List<Object?> get props => [id, invoiceNumber, status];
}
