import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/usecases/manage_tenants_usecase.dart';

class TenantsController extends GetxController
    with StateMixin<List<TenantEntity>> {
  final RxString searchQuery = ''.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController nationalIdCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadTenants();
    ever(searchQuery, (_) => loadTenants());
  }

  Future<void> loadTenants({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final qLower = searchQuery.value.trim().toLowerCase();
      final filtered = Phase1MockData.tenants.where((t) {
        if (qLower.isEmpty) return true;
        return t.fullName.toLowerCase().contains(qLower) ||
            t.phone.toLowerCase().contains(qLower) ||
            t.nationalId.toLowerCase().contains(qLower);
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

  void prepareForm({TenantEntity? tenant}) {
    fullNameCtrl.text = tenant?.fullName ?? '';
    phoneCtrl.text = tenant?.phone ?? '';
    nationalIdCtrl.text = tenant?.nationalId ?? '';
    notesCtrl.text = tenant?.notes ?? '';
  }

  Future<void> saveTenant({TenantEntity? existing}) async {
    if (!Get.isRegistered<ManageTenantsUseCase>()) return;
    final useCase = Get.find<ManageTenantsUseCase>();
    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final entity = TenantEntity(
      id: existing?.id ?? 0,
      fullName: fullNameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      nationalId: nationalIdCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
      createdAt: existing?.createdAt ?? nowIso,
    );
    if (existing == null) {
      await useCase.addTenant(entity);
    } else {
      await useCase.updateTenant(entity);
    }
    await loadTenants(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  @override
  void onClose() {
    fullNameCtrl.dispose();
    phoneCtrl.dispose();
    nationalIdCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
