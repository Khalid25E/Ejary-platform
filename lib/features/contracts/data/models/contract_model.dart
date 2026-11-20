import '../../domain/entities/contract_entity.dart';

class ContractModel extends ContractEntity {
  final String? terminationDate;
  final String? terminationReason;

  const ContractModel({
    required super.id,
    required super.contractNumber,
    required super.apartmentId,
    required super.tenantId,
    required super.startedAt,
    required super.endAt,
    required super.createdAt,
    required super.price,
    required super.totalServices,
    required super.conditionsJson,
    required super.dueDate,
    required super.dueDay,
    required super.rentalAt,
    required super.autoRenew,
    required super.status,
    required super.notes,
    super.renewalOfContractId,
    this.terminationDate,
    this.terminationReason,
  });

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] as int,
      contractNumber: map['contract_number'] as String,
      apartmentId: map['apartment_id'] as int,
      tenantId: map['tenant_id'] as int,
      startedAt: map['started_at'] as String,
      endAt: map['end_at'] as String,
      createdAt: map['created_at'] as String,
      price: map['price'] as num,
      totalServices: map['total_services'] as num,
      conditionsJson: (map['conditions_json'] as String?) ?? '[]',
      dueDate: map['due_date'] as String,
      dueDay: map['due_day'] as int,
      rentalAt: map['rental_at'] as String,
      autoRenew: (map['auto_renew'] as int) == 1,
      status: map['status'] as String,
      notes: (map['notes'] as String?) ?? '',
      renewalOfContractId: map['renewal_of_contract_id'] as int?,
      terminationDate: map['termination_date'] as String?,
      terminationReason: map['termination_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'contract_number': contractNumber,
      'apartment_id': apartmentId,
      'tenant_id': tenantId,
      'started_at': startedAt,
      'end_at': endAt,
      'created_at': createdAt,
      'price': price.round(),
      'total_services': totalServices.round(),
      'conditions_json': conditionsJson,
      'due_date': dueDate,
      'due_day': dueDay,
      'rental_at': rentalAt,
      'auto_renew': autoRenew ? 1 : 0,
      'status': status,
      'notes': notes,
      'renewal_of_contract_id': renewalOfContractId,
      'termination_date': terminationDate,
      'termination_reason': terminationReason,
    };
  }
}
