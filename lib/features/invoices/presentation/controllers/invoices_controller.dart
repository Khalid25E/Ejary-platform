import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/manage_invoices_usecase.dart';

class InvoicesController extends GetxController
    with StateMixin<List<InvoiceEntity>> {
  final RxString statusFilter = 'all'.obs;
  final RxString monthFilter = 'all'.obs;
  final RxInt propertyFilter = 0.obs; // 0 = all

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
    everAll([statusFilter, monthFilter, propertyFilter], (_) => loadInvoices());
  }

  Future<void> loadInvoices({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final st = statusFilter.value;
      final mo = monthFilter.value;
      final pId = propertyFilter.value;

      final filtered = Phase1MockData.invoices.where((inv) {
        final matchesSt = st == 'all' || inv.status == st;
        final matchesMo = mo == 'all' || inv.billingMonth == mo;
        bool matchesProp = true;
        if (pId != 0) {
          final cnt = Phase1MockData.getContract(inv.contractId);
          final apt = Phase1MockData.getApartment(cnt?.apartmentId ?? 0);
          matchesProp = apt?.propertyId == pId;
        }
        return matchesSt && matchesMo && matchesProp;
      }).toList();

      if (filtered.isEmpty) {
        change([], status: RxStatus.empty());
      } else {
        change(filtered, status: RxStatus.success());
      }
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }

  Future<int> generateMonthlyInvoicesForMonth(String billingMonth) async {
    if (!Get.isRegistered<ManageInvoicesUseCase>()) return 0;
    final count = await Get.find<ManageInvoicesUseCase>()
        .generateMonthlyInvoices(billingMonth);
    await loadInvoices(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
    return count;
  }
}
