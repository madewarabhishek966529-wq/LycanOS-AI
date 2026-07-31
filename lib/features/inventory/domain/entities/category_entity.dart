import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id, name, description];
}

class SupplierEntity extends Equatable {
  const SupplierEntity({
    required this.id,
    required this.name,
    this.contactPhone,
    this.contactEmail,
    this.address,
  });

  final String id;
  final String name;
  final String? contactPhone;
  final String? contactEmail;
  final String? address;

  @override
  List<Object?> get props => [id, name, contactPhone, contactEmail, address];
}
