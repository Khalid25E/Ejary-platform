class ApartmentServiceEntity {
  final int id;
  final int apartmentId;
  final int serviceId;
  final num customPrice;
  final String billingType; // fixed_monthly, usage_based
  final bool isActive;
  final String notes;
  final String createdAt;

  const ApartmentServiceEntity({
    required this.id,
    required this.apartmentId,
    required this.serviceId,
    required this.customPrice,
    required this.billingType,
    required this.isActive,
    required this.notes,
    required this.createdAt,
  });
}
