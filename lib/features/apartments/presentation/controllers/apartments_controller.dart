import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/apartment_entity.dart';
import '../../domain/entities/apartment_service_entity.dart';
import '../../domain/usecases/manage_apartments_usecase.dart';

class ApartmentsController extends GetxController
    with StateMixin<List<ApartmentEntity>> {
  final RxString searchQuery = ''.obs;
  final RxInt selectedPropertyId = 0.obs; // 0 = all
  final RxString selectedStatus = 'all'.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController aptNumberCtrl = TextEditingController();
  final TextEditingController floorCtrl = TextEditingController();
  final TextEditingController roomsCtrl = TextEditingController();
  final TextEditingController baseRentCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final RxInt formPropertyId = 1.obs;
  final RxString formStatus = 'vacant'.obs;

  @override
  void onInit() {
    super.onInit();
    loadApartments();
    everAll([searchQuery, selectedPropertyId, selectedStatus], (_) {
      loadApartments();
    });
  }

  Future<void> loadApartments({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final qLower = searchQuery.value.trim().toLowerCase();
      final pId = selectedPropertyId.value;
      final st = selectedStatus.value;

      final filtered = Phase1MockData.apartments.where((a) {
        final matchesQ = qLower.isEmpty ||
            a.apartmentNumber.toLowerCase().contains(qLower) ||
            a.notes.toLowerCase().contains(qLower);
        final matchesProp = pId == 0 || a.propertyId == pId;
        final matchesSt = st == 'all' || a.status == st;
        return matchesQ && matchesProp && matchesSt;
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

  void prepareForm({ApartmentEntity? apartment, int? initialPropertyId}) {
    aptNumberCtrl.text = apartment?.apartmentNumber ?? '';
    floorCtrl.text = (apartment?.floor ?? 1).toString();
    roomsCtrl.text = (apartment?.roomsCount ?? 3).toString();
    baseRentCtrl.text = (apartment?.baseRent ?? 2500).toString();
    notesCtrl.text = apartment?.notes ?? '';
    final props = Phase1MockData.properties;
    formPropertyId.value = apartment?.propertyId ??
        initialPropertyId ??
        (props.isNotEmpty ? props.first.id : 1);
    formStatus.value = apartment?.status ?? 'vacant';
  }

  Future<void> saveApartment({ApartmentEntity? existing}) async {
    if (!Get.isRegistered<ManageApartmentsUseCase>()) return;
    final useCase = Get.find<ManageApartmentsUseCase>();
    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final entity = ApartmentEntity(
      id: existing?.id ?? 0,
      propertyId: formPropertyId.value,
      apartmentNumber: aptNumberCtrl.text.trim(),
      floor: int.tryParse(floorCtrl.text.trim()) ?? 1,
      roomsCount: int.tryParse(roomsCtrl.text.trim()) ?? 3,
      baseRent: num.tryParse(baseRentCtrl.text.trim()) ?? 0,
      status: formStatus.value,
      notes: notesCtrl.text.trim(),
      createdAt: existing?.createdAt ?? nowIso,
    );
    if (existing == null) {
      await useCase.addApartment(entity);
    } else {
      await useCase.updateApartment(entity);
    }
    await loadApartments(syncFromDb: true);
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  Future<void> saveCustomServices(
    int apartmentId,
    List<ApartmentServiceEntity> services,
  ) async {
    if (!Get.isRegistered<ManageApartmentsUseCase>()) return;
    await Get.find<ManageApartmentsUseCase>().saveApartmentServices(
      apartmentId,
      services,
    );
    await loadApartments(syncFromDb: true);
  }

  @override
  void onClose() {
    aptNumberCtrl.dispose();
    floorCtrl.dispose();
    roomsCtrl.dispose();
    baseRentCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
