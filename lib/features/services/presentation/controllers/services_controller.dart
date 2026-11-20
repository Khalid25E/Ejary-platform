import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/manage_services_usecase.dart';

class ServicesController extends GetxController
    with StateMixin<List<ServiceEntity>> {
  final RxString searchQuery = ''.obs;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final RxString billingType = 'fixed_monthly'.obs;
  final RxBool isActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadServices();
    ever(searchQuery, (_) => loadServices());
  }

  Future<void> loadServices({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final qLower = searchQuery.value.trim().toLowerCase();
      final filtered = Phase1MockData.services.where((s) {
        if (qLower.isEmpty) return true;
        return s.name.toLowerCase().contains(qLower) ||
            s.description.toLowerCase().contains(qLower);
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

  Future<void> saveService({ServiceEntity? existing}) async {
    if (!Get.isRegistered<ManageServicesUseCase>()) return;
    final useCase = Get.find<ManageServicesUseCase>();
    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final entity = ServiceEntity(
      id: existing?.id ?? 0,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      defaultPrice: num.tryParse(priceCtrl.text.trim()) ?? 0,
      billingType: billingType.value,
      isActive: isActive.value,
      createdAt: existing?.createdAt ?? nowIso,
    );
    if (existing == null) {
      await useCase.addService(entity);
    } else {
      await useCase.updateService(entity);
    }
    await loadServices(syncFromDb: true);
  }

  Future<void> deleteService(int id) async {
    if (!Get.isRegistered<ManageServicesUseCase>()) return;
    await Get.find<ManageServicesUseCase>().deleteService(id);
    await loadServices(syncFromDb: true);
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.onClose();
  }
}
