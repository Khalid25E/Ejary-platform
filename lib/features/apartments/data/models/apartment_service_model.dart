import '../../domain/entities/apartment_service_entity.dart';

class ApartmentServiceModel extends ApartmentServiceEntity {
  const ApartmentServiceModel({
    required super.id,
    required super.apartmentId,
    required super.serviceId,
    required super.customPrice,
    required super.billingType,
    required super.isActive,
    required super.notes,
    required super.createdAt,
  });

  factory ApartmentServiceModel.fromMap(Map<String, dynamic> map) {
    return ApartmentServiceModel(
      id: map['id'] as int,
      apartmentId: map['apartment_id'] as int,
      serviceId: map['service_id'] as int,
      customPrice: map['custom_price'] as num,
      billingType: map['billing_type'] as String,
      isActive: (map['is_active'] as int) == 1,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'apartment_id': apartmentId,
      'service_id': serviceId,
      'custom_price': customPrice.round(),
      'billing_type': billingType,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
