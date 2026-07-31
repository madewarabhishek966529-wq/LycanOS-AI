import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.id, required super.name, super.description});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.contactPhone,
    super.contactEmail,
    super.address,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      address: json['address'] as String?,
    );
  }
}
