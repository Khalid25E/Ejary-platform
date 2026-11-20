import '../../domain/entities/zone_entity.dart';

class ZoneModel extends ZoneEntity {
  const ZoneModel({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
  });

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
    };
  }
}
