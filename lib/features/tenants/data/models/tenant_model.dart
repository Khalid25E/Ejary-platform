import '../../domain/entities/tenant_entity.dart';

class TenantModel extends TenantEntity {
  const TenantModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.nationalId,
    required super.notes,
    required super.createdAt,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      nationalId: map['national_id'] as String,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
