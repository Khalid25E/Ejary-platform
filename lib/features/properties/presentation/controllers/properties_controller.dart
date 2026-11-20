import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/usecases/manage_properties_usecase.dart';

class PropertiesController extends GetxController
    with StateMixin<List<PropertyEntity>> {
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'all'.obs;
  final RxInt selectedZoneFilter = 0.obs; // 0 = all

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController lngCtrl = TextEditingController();
  final TextEditingController latCtrl = TextEditingController();
  final RxString selectedType = 'residential'.obs;
  final RxString selectedStatus = 'active'.obs;
  final RxInt selectedZoneId = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadProperties();
    everAll([searchQuery, statusFilter, selectedZoneFilter], (_) {
      loadProperties();
    });
  }

  Future<void> loadProperties({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final qLower = searchQuery.value.trim().toLowerCase();
      final st = statusFilter.value;
      final zId = selectedZoneFilter.value;

      final filtered = Phase1MockData.properties.where((p) {
        final matchesQuery = qLower.isEmpty ||
            p.name.toLowerCase().contains(qLower) ||
            p.description.toLowerCase().contains(qLower);
        final matchesStatus = st == 'all' || p.status == st;
        final matchesZone = zId == 0 || p.zoneId == zId;
        return matchesQuery && matchesStatus && matchesZone;
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

  void prepareForm({PropertyEntity? property}) {
    nameCtrl.text = property?.name ?? '';
    descCtrl.text = property?.description ?? '';
    lngCtrl.text = property?.longitude?.toString() ?? '46.6753';
    latCtrl.text = property?.latitude?.toString() ?? '24.8136';
    selectedType.value = property?.type ?? 'residential';
    selectedStatus.value = property?.status ?? 'active';
    final zones = Phase1MockData.zones;
    selectedZoneId.value =
        property?.zoneId ?? (zones.isNotEmpty ? zones.first.id : 1);
  }

  Future<void> saveProperty({PropertyEntity? existing}) async {
    if (!Get.isRegistered<ManagePropertiesUseCase>()) return;
    final useCase = Get.find<ManagePropertiesUseCase>();
    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final entity = PropertyEntity(
      id: existing?.id ?? 0,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      status: selectedStatus.value,
      type: selectedType.value,
      zoneId: selectedZoneId.value,
      longitude: double.tryParse(lngCtrl.text.trim()),
      latitude: double.tryParse(latCtrl.text.trim()),
      createdAt: existing?.createdAt ?? nowIso,
    );
    if (existing == null) {
      await useCase.addProperty(entity);
    } else {
      await useCase.updateProperty(entity);
    }
    await loadProperties(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  Future<void> deleteProperty(int id) async {
    if (!Get.isRegistered<ManagePropertiesUseCase>()) return;
    await Get.find<ManagePropertiesUseCase>().deleteProperty(id);
    await loadProperties(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    lngCtrl.dispose();
    latCtrl.dispose();
    super.onClose();
  }
}
