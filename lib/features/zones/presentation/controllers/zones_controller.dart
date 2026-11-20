import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/usecases/manage_zones_usecase.dart';

class ZonesController extends GetxController
    with StateMixin<List<ZoneEntity>> {
  final RxString searchQuery = ''.obs;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadZones();
    ever(searchQuery, (_) => loadZones());
  }

  Future<void> loadZones({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final q = searchQuery.value.trim().toLowerCase();
      final filtered = Phase1MockData.zones.where((z) {
        if (q.isEmpty) return true;
        return z.name.toLowerCase().contains(q) ||
            z.description.toLowerCase().contains(q);
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

  int getPropertyCountForZone(int zoneId) {
    return Phase1MockData.properties.where((p) => p.zoneId == zoneId).length;
  }

  Future<void> saveZone({ZoneEntity? existing}) async {
    if (!Get.isRegistered<ManageZonesUseCase>()) return;
    final useCase = Get.find<ManageZonesUseCase>();
    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    if (existing == null) {
      await useCase.addZone(
        ZoneEntity(
          id: 0,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          createdAt: nowIso,
        ),
      );
    } else {
      await useCase.updateZone(
        ZoneEntity(
          id: existing.id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          createdAt: existing.createdAt,
        ),
      );
    }
    await loadZones(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  Future<void> deleteZone(int zoneId) async {
    if (!Get.isRegistered<ManageZonesUseCase>()) return;
    await Get.find<ManageZonesUseCase>().deleteZone(zoneId);
    await loadZones(syncFromDb: true);
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    super.onClose();
  }
}
