import 'package:equatable/equatable.dart';
import 'package:erp_app/core/utils/user_role.dart';

class AppUser extends Equatable {
  final String   id;
  final String?  branchId;
  final String   fullName;
  final String   email;
  final UserRole role;
  final bool     isActive;

  const AppUser({
    required this.id,
    this.branchId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin   => role.isAdmin;
  bool get isManager => role.isManager;

  @override
  List<Object?> get props => [id, branchId, email, role, isActive];
}
