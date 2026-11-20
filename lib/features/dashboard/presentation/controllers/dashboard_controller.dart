import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/dashboard_summary_entity.dart';

class DashboardController extends GetxController
    with StateMixin<DashboardSummaryEntity> {
  final LocalStorageService storage = Get.find<LocalStorageService>();

  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
    if (index == 0) {
      loadDashboardData();
    }
  }

  Future<void> loadDashboardData({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }

      // Compute KPIs from the SQLite-synchronized DatabaseLookupService cache
      final props = Phase1MockData.properties;
      final apts = Phase1MockData.apartments;
      final rented = apts.where((a) => a.status == 'rented').length;
      final vacant = apts.where((a) => a.status == 'vacant').length;
      final maint = apts.where((a) => a.status == 'maintenance').length;
      final activeContracts = Phase1MockData.contracts
          .where((c) => c.status == 'active' || c.status == 'expiring')
          .toList();
      final expiring =
          Phase1MockData.contracts.where((c) => c.status == 'expiring').length;

      final expectedMonthly = activeContracts.fold<num>(
        0,
        (sum, c) => sum + c.monthlyTotal,
      );

      final novInvoices = Phase1MockData.invoices
          .where((i) => i.billingMonth == '2026-11')
          .toList();
      final monthlyCollected = novInvoices.fold<num>(
        0,
        (sum, i) => sum + i.paidAmount,
      );
      final totalDues = Phase1MockData.invoices.fold<num>(
        0,
        (sum, i) => sum + i.remainingAmount,
      );
      final totalOverdue = Phase1MockData.invoices
          .where((i) => i.status == 'Overdue')
          .fold<num>(0, (sum, i) => sum + i.remainingAmount);

      final summary = DashboardSummaryEntity(
        totalProperties: props.length,
        totalApartments: apts.length,
        rentedApartments: rented,
        vacantApartments: vacant,
        maintenanceApartments: maint,
        totalTenants: Phase1MockData.tenants.length,
        activeContracts: activeContracts.length,
        expiringContracts: expiring,
        expectedMonthlyRent: expectedMonthly,
        monthlyCollections: monthlyCollected,
        totalDues: totalDues,
        totalOverdue: totalOverdue,
      );

      change(summary, status: RxStatus.success());
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
