import '../../domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required super.type,
    required super.zoneId,
    super.longitude,
    super.latitude,
    required super.createdAt,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      status: map['status'] as String,
      type: map['type'] as String,
      zoneId: map['zone_id'] as int,
      longitude: (map['longitude'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'name': name,
      'description': description,
      'status': status,
      'type': type,
      'zone_id': zoneId,
      'longitude': longitude,
      'latitude': latitude,
      'created_at': createdAt,
    };
  }
}
