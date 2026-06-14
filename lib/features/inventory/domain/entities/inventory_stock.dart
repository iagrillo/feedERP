import 'package:equatable/equatable.dart';

class InventoryStock extends Equatable {
  final String    branchId;
  final String    branchName;
  final String    productId;
  final String    productName;
  final String?   sku;
  final String    unit;
  final double    reorderLevel;
  final double    stockQuantity;
  final DateTime? lastUpdated;

  const InventoryStock({
    required this.branchId,
    required this.branchName,
    required this.productId,
    required this.productName,
    this.sku,
    required this.unit,
    required this.reorderLevel,
    required this.stockQuantity,
    this.lastUpdated,
  });

  bool get isLowStock => stockQuantity <= reorderLevel;

  @override
  List<Object?> get props => [branchId, productId, stockQuantity];
}

class InventoryStockModel extends InventoryStock {
  const InventoryStockModel({
    required super.branchId,
    required super.branchName,
    required super.productId,
    required super.productName,
    super.sku,
    required super.unit,
    required super.reorderLevel,
    required super.stockQuantity,
    super.lastUpdated,
  });

  factory InventoryStockModel.fromJson(Map<String, dynamic> json) => InventoryStockModel(
    branchId:      json['branch_id'] as String,
    branchName:    json['branch_name'] as String,
    productId:     json['product_id'] as String,
    productName:   json['product_name'] as String,
    sku:           json['sku'] as String?,
    unit:          json['unit'] as String? ?? 'bag',
    reorderLevel:  (json['reorder_level'] as num?)?.toDouble() ?? 0,
    stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0,
    lastUpdated:   json['last_updated'] != null ? DateTime.parse(json['last_updated'] as String) : null,
  );
}
