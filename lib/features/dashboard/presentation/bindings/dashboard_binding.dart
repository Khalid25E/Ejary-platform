import 'package:get/get.dart';
import '../../../invoices/presentation/controllers/invoices_controller.dart';
import '../../../properties/presentation/controllers/properties_controller.dart';
import '../../../tenants/presentation/controllers/tenants_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<PropertiesController>(() => PropertiesController());
    Get.lazyPut<TenantsController>(() => TenantsController());
    Get.lazyPut<InvoicesController>(() => InvoicesController());
  }
}
