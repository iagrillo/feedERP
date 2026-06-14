import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String  id;
  final String  name;
  final String? sku;
  final String? description;
  final String  unit;
  final double  reorderLevel;
  final bool    isActive;

  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    required this.unit,
    required this.reorderLevel,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, sku, unit];
}
