import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.loyaltyPoints,
    required this.creditBalance,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final int loyaltyPoints;
  final double creditBalance;
  final DateTime createdAt;

  bool get hasOutstandingCredit => creditBalance > 0;

  @override
  List<Object?> get props => [id, name, phone, loyaltyPoints, creditBalance];
}
