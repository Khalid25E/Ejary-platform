class ContractServiceEntity {
  final int id;
  final int contractId;
  final int serviceId;
  final String serviceName;
  final num price;
  final String billingType;
  final String createdAt;

  const ContractServiceEntity({
    required this.id,
    required this.contractId,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.billingType,
    required this.createdAt,
  });
}
