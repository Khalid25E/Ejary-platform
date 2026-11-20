class ServiceEntity {
  final int id;
  final String name;
  final String description;
  final num defaultPrice;
  final String billingType; // fixed_monthly, usage_based
  final bool isActive;
  final String createdAt;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPrice,
    required this.billingType,
    required this.isActive,
    required this.createdAt,
  });
}
