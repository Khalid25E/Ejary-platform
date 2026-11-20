import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.defaultPrice,
    required super.billingType,
    required super.isActive,
    required super.createdAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      defaultPrice: map['default_price'] as num,
      billingType: map['billing_type'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'name': name,
      'description': description,
      'default_price': defaultPrice.round(),
      'billing_type': billingType,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
