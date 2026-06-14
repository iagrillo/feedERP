import 'package:erp_app/core/utils/user_role.dart';
import 'package:erp_app/features/auth/domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.branchId,
    required super.fullName,
    required super.email,
    required super.role,
    required super.isActive,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) => AppUserModel(
    id:        json['id'] as String,
    branchId:  json['branch_id'] as String?,
    fullName:  json['full_name'] as String,
    email:     json['email'] as String,
    role:      UserRole.values.firstWhere((r) => r.name == json['role']),
    isActive:  json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id':        id,
    'branch_id': branchId,
    'full_name': fullName,
    'email':     email,
    'role':      role.name,
    'is_active': isActive,
  };
}
