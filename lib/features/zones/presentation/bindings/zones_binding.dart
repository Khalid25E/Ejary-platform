import 'package:get/get.dart';
import '../controllers/zones_controller.dart';

class ZonesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ZonesController>(() => ZonesController());
  }
}
