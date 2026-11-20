class DashboardSummaryEntity {
  final int totalProperties;
  final int totalApartments;
  final int rentedApartments;
  final int vacantApartments;
  final int maintenanceApartments;
  final int totalTenants;
  final int activeContracts;
  final int expiringContracts;
  final num expectedMonthlyRent;
  final num monthlyCollections;
  final num totalDues;
  final num totalOverdue;

  const DashboardSummaryEntity({
    required this.totalProperties,
    required this.totalApartments,
    required this.rentedApartments,
    required this.vacantApartments,
    required this.maintenanceApartments,
    required this.totalTenants,
    required this.activeContracts,
    required this.expiringContracts,
    required this.expectedMonthlyRent,
    required this.monthlyCollections,
    required this.totalDues,
    required this.totalOverdue,
  });
}
