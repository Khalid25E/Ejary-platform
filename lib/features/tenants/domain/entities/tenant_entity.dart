class TenantEntity {
  final int id;
  final String fullName;
  final String phone;
  final String nationalId;
  final String notes;
  final String createdAt;

  const TenantEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    required this.notes,
    required this.createdAt,
  });
}
