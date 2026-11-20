class ContractEntity {
  final int id;
  final String contractNumber;
  final int apartmentId;
  final int tenantId;
  final String startedAt;
  final String endAt;
  final String createdAt;
  final num price;
  final num totalServices;
  final String conditionsJson;
  final String dueDate;
  final int dueDay;
  final String rentalAt;
  final bool autoRenew;
  final String status; // active, expiring, expired, terminated
  final String notes;
  final int? renewalOfContractId;

  const ContractEntity({
    required this.id,
    required this.contractNumber,
    required this.apartmentId,
    required this.tenantId,
    required this.startedAt,
    required this.endAt,
    required this.createdAt,
    required this.price,
    required this.totalServices,
    required this.conditionsJson,
    required this.dueDate,
    required this.dueDay,
    required this.rentalAt,
    required this.autoRenew,
    required this.status,
    required this.notes,
    this.renewalOfContractId,
  });

  num get monthlyTotal => price + totalServices;
}
