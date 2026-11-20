import '../../domain/entities/apartment_entity.dart';

class ApartmentModel extends ApartmentEntity {
  const ApartmentModel({
    required super.id,
    required super.propertyId,
    required super.apartmentNumber,
    required super.floor,
    required super.roomsCount,
    required super.baseRent,
    required super.status,
    required super.notes,
    required super.createdAt,
  });

  factory ApartmentModel.fromMap(Map<String, dynamic> map) {
    return ApartmentModel(
      id: map['id'] as int,
      propertyId: map['property_id'] as int,
      apartmentNumber: map['apartment_number'] as String,
      floor: map['floor'] as int,
      roomsCount: map['rooms_count'] as int,
      baseRent: map['base_rent'] as num,
      status: map['status'] as String,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'property_id': propertyId,
      'apartment_number': apartmentNumber,
      'floor': floor,
      'rooms_count': roomsCount,
      'base_rent': baseRent.round(),
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
