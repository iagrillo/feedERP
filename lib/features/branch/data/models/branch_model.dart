import 'package:erp_app/features/branch/domain/entities/branch.dart';

class BranchModel extends Branch {
  const BranchModel({
    required super.id,
    required super.name,
    super.address,
    super.phone,
    super.email,
    required super.isActive,
    required super.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
    id:        json['id'] as String,
    name:      json['name'] as String,
    address:   json['address'] as String?,
    phone:     json['phone'] as String?,
    email:     json['email'] as String?,
    isActive:  json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name':      name,
    'address':   address,
    'phone':     phone,
    'email':     email,
    'is_active': isActive,
  };
}
