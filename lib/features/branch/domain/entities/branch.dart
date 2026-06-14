import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String  id;
  final String  name;
  final String? address;
  final String? phone;
  final String? email;
  final bool    isActive;
  final DateTime createdAt;

  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, isActive];
}
