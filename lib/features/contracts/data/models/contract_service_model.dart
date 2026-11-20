import '../../domain/entities/contract_service_entity.dart';

class ContractServiceModel extends ContractServiceEntity {
  const ContractServiceModel({
    required super.id,
    required super.contractId,
    required super.serviceId,
    required super.serviceName,
    required super.price,
    required super.billingType,
    required super.createdAt,
  });

  factory ContractServiceModel.fromMap(Map<String, dynamic> map) {
    return ContractServiceModel(
      id: map['id'] as int,
      contractId: map['contract_id'] as int,
      serviceId: map['service_id'] as int,
      serviceName: map['service_name'] as String,
      price: map['price'] as num,
      billingType: map['billing_type'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'contract_id': contractId,
      'service_id': serviceId,
      'service_name': serviceName,
      'price': price.round(),
      'billing_type': billingType,
      'created_at': createdAt,
    };
  }
}
