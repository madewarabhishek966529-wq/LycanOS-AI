import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.notes,
    required super.loyaltyPoints,
    required super.creditBalance,
    required super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      loyaltyPoints: json['loyalty_points'] as int,
      creditBalance: double.parse(json['credit_balance'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
