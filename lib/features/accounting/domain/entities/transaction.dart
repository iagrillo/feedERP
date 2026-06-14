import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }

class LedgerTransaction extends Equatable {
  final String          id;
  final String          branchId;
  final TransactionType type;
  final double          amount;
  final String          description;
  final String?         referenceId;
  final String?         referenceType;
  final String?         paymentMethod;
  final DateTime        createdAt;

  const LedgerTransaction({
    required this.id,
    required this.branchId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    this.referenceType,
    this.paymentMethod,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, branchId, type, amount];
}
