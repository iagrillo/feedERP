import 'package:erp_app/features/products/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    super.sku,
    super.description,
    required super.unit,
    required super.reorderLevel,
    required super.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id:           json['id'] as String,
    name:         json['name'] as String,
    sku:          json['sku'] as String?,
    description:  json['description'] as String?,
    unit:         json['unit'] as String? ?? 'bag',
    reorderLevel: (json['reorder_level'] as num?)?.toDouble() ?? 0,
    isActive:     json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name':          name,
    'sku':           sku,
    'description':   description,
    'unit':          unit,
    'reorder_level': reorderLevel,
    'is_active':     isActive,
  };
}
