import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../../apartments/presentation/controllers/apartments_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../invoices/presentation/controllers/invoices_controller.dart';
import '../../../tenants/domain/entities/tenant_entity.dart';
import '../../../tenants/presentation/controllers/tenants_controller.dart';
import '../../domain/entities/contract_entity.dart';
import '../../domain/entities/contract_service_entity.dart';
import '../../domain/usecases/manage_contracts_usecase.dart';

class ContractsController extends GetxController
    with StateMixin<List<ContractEntity>> {
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'all'.obs;

  int currentWizardStep = 0;
  int selectedPropertyId = 1;
  int? selectedVacantApartmentId;
  bool isAddingNewTenantInline = false;
  int selectedTenantId = 1;

  final TextEditingController inlineTenantNameCtrl = TextEditingController();
  final TextEditingController inlineTenantPhoneCtrl = TextEditingController();
  final TextEditingController inlineTenantNationalIdCtrl =
      TextEditingController();

  final TextEditingController startDateCtrl =
      TextEditingController(text: '2026-12-01');
  final TextEditingController endDateCtrl =
      TextEditingController(text: '2027-11-30');
  final TextEditingController rentalDateCtrl =
      TextEditingController(text: '2026-12-01');
  final TextEditingController dueDayCtrl = TextEditingController(text: '1');
  final TextEditingController baseRentCtrl =
      TextEditingController(text: '2200');
  final TextEditingController notesCtrl = TextEditingController();
  bool autoRenew = true;

  final Map<int, bool> selectedServices = {};
  final Map<int, TextEditingController> servicePriceCtrls = {};

  final List<String> conditionsList = [
    'الالتزام بسداد الإيجار الشهري في يوم الاستحقاق المحدد',
    'المحافظة على سلامة الشقة والمرافق المشتركة',
    'عدم التأجير من الباطن دون موافقة خطية من المالك',
  ];
  final TextEditingController newConditionCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadContracts();
    initWizardDefaults();
    everAll([searchQuery, statusFilter], (_) => loadContracts());
  }

  Future<void> loadContracts({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final qLower = searchQuery.value.trim().toLowerCase();
      final st = statusFilter.value;

      final filtered = Phase1MockData.contracts.where((c) {
        final tenantName =
            Phase1MockData.getTenant(c.tenantId)?.fullName.toLowerCase() ?? '';
        final aptNum = Phase1MockData.getApartment(c.apartmentId)
                ?.apartmentNumber
                .toLowerCase() ??
            '';
        final matchesQ = qLower.isEmpty ||
            c.contractNumber.toLowerCase().contains(qLower) ||
            tenantName.contains(qLower) ||
            aptNum.contains(qLower);
        final matchesSt = st == 'all' || c.status == st;
        return matchesQ && matchesSt;
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

  void initWizardDefaults({int? preselectedApartmentId}) {
    currentWizardStep = 0;
    final vacantApts =
        Phase1MockData.apartments.where((a) => a.status == 'vacant').toList();
    final props = Phase1MockData.properties;
    if (props.isNotEmpty) {
      selectedPropertyId = props.first.id;
    }
    final tenants = Phase1MockData.tenants;
    if (tenants.isNotEmpty) {
      selectedTenantId = tenants.first.id;
    }

    if (preselectedApartmentId != null) {
      final apt = Phase1MockData.getApartment(preselectedApartmentId);
      if (apt != null && apt.status == 'vacant') {
        selectedPropertyId = apt.propertyId;
        selectedVacantApartmentId = apt.id;
        baseRentCtrl.text = apt.baseRent.toString();
      }
    } else if (vacantApts.isNotEmpty) {
      selectedPropertyId = vacantApts.first.propertyId;
      selectedVacantApartmentId = vacantApts.first.id;
      baseRentCtrl.text = vacantApts.first.baseRent.toString();
    } else {
      selectedVacantApartmentId = null;
    }

    _loadApartmentServicesForWizard(selectedVacantApartmentId);
  }

  void _loadApartmentServicesForWizard(int? apartmentId) {
    selectedServices.clear();
    for (final c in servicePriceCtrls.values) {
      c.dispose();
    }
    servicePriceCtrls.clear();

    for (final srv in Phase1MockData.services) {
      final aptSrv = Phase1MockData.apartmentServices
          .where((s) => s.apartmentId == apartmentId && s.serviceId == srv.id)
          .firstOrNull;
      selectedServices[srv.id] = aptSrv != null ? aptSrv.isActive : false;
      servicePriceCtrls[srv.id] = TextEditingController(
        text: (aptSrv?.customPrice ?? srv.defaultPrice).toString(),
      );
    }
  }

  List<ApartmentEntity> get vacantApartmentsForSelectedProperty {
    return Phase1MockData.apartments
        .where(
          (a) => a.propertyId == selectedPropertyId && a.status == 'vacant',
        )
        .toList();
  }

  void selectWizardProperty(int propId) {
    selectedPropertyId = propId;
    final vacant = vacantApartmentsForSelectedProperty;
    selectedVacantApartmentId = vacant.isNotEmpty ? vacant.first.id : null;
    if (vacant.isNotEmpty) {
      baseRentCtrl.text = vacant.first.baseRent.toString();
    }
    _loadApartmentServicesForWizard(selectedVacantApartmentId);
    update(['wizard']);
  }

  void selectWizardApartment(int aptId) {
    selectedVacantApartmentId = aptId;
    final apt = Phase1MockData.getApartment(aptId);
    if (apt != null) {
      baseRentCtrl.text = apt.baseRent.toString();
    }
    _loadApartmentServicesForWizard(aptId);
    update(['wizard']);
  }

  void toggleInlineNewTenant(bool value) {
    isAddingNewTenantInline = value;
    update(['wizard']);
  }

  void selectExistingTenant(int tenantId) {
    selectedTenantId = tenantId;
    update(['wizard']);
  }

  void toggleAutoRenew(bool value) {
    autoRenew = value;
    update(['wizard']);
  }

  void toggleWizardService(int serviceId, bool checked) {
    selectedServices[serviceId] = checked;
    update(['wizard']);
  }

  void refreshWizardTotals() {
    update(['wizard']);
  }

  void addCondition() {
    final text = newConditionCtrl.text.trim();
    if (text.isNotEmpty) {
      conditionsList.add(text);
      newConditionCtrl.clear();
      update(['wizard']);
    }
  }

  void removeCondition(int index) {
    conditionsList.removeAt(index);
    update(['wizard']);
  }

  void setWizardStep(int step) {
    if (step >= 0 && step <= 5) {
      currentWizardStep = step;
      update(['wizard']);
    }
  }

  num get wizardBaseRent => num.tryParse(baseRentCtrl.text.trim()) ?? 0;

  num get wizardServicesTotal {
    num sum = 0;
    for (final srv in Phase1MockData.services) {
      if (selectedServices[srv.id] == true) {
        sum += num.tryParse(servicePriceCtrls[srv.id]?.text ?? '0') ?? 0;
      }
    }
    return sum;
  }

  num get wizardMonthlyTotal => wizardBaseRent + wizardServicesTotal;

  Future<int?> confirmWizardContractCreation() async {
    if (!Get.isRegistered<ManageContractsUseCase>()) return null;
    if (selectedVacantApartmentId == null) return null;

    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final snapshot = <ContractServiceEntity>[];
    for (final srv in Phase1MockData.services) {
      if (selectedServices[srv.id] == true) {
        final customPrice =
            num.tryParse(servicePriceCtrls[srv.id]?.text ?? '0') ??
                srv.defaultPrice;
        snapshot.add(
          ContractServiceEntity(
            id: 0,
            contractId: 0,
            serviceId: srv.id,
            serviceName: srv.name,
            price: customPrice,
            billingType: srv.billingType,
            createdAt: nowIso,
          ),
        );
      }
    }

    TenantEntity? inlineTenant;
    if (isAddingNewTenantInline) {
      inlineTenant = TenantEntity(
        id: 0,
        fullName: inlineTenantNameCtrl.text.trim(),
        phone: inlineTenantPhoneCtrl.text.trim(),
        nationalId: inlineTenantNationalIdCtrl.text.trim(),
        notes: '',
        createdAt: nowIso,
      );
    }

    final cntNumber =
        'CNT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final contract = ContractEntity(
      id: 0,
      contractNumber: cntNumber,
      apartmentId: selectedVacantApartmentId!,
      tenantId: selectedTenantId,
      startedAt: startDateCtrl.text.trim(),
      endAt: endDateCtrl.text.trim(),
      createdAt: nowIso,
      price: wizardBaseRent,
      totalServices: wizardServicesTotal,
      conditionsJson: jsonEncode(conditionsList),
      dueDate: startDateCtrl.text.trim(),
      dueDay: (int.tryParse(dueDayCtrl.text.trim()) ?? 1).clamp(1, 31),
      rentalAt: rentalDateCtrl.text.trim(),
      autoRenew: autoRenew,
      status: 'active',
      notes: notesCtrl.text.trim(),
    );

    final newId = await Get.find<ManageContractsUseCase>().createContract(
      contract: contract,
      servicesSnapshot: snapshot,
      inlineNewTenant: inlineTenant,
    );

    await _refreshAllDependentControllers();
    return newId;
  }

  Future<int?> executeContractRenewal({
    required int oldContractId,
    required String newStartDate,
    required String newEndDate,
    required num newBaseRent,
    required num newServicesTotal,
  }) async {
    if (!Get.isRegistered<ManageContractsUseCase>()) return null;
    final useCase = Get.find<ManageContractsUseCase>();
    final oldSnapshot = await useCase.getContractServices(oldContractId);
    final cntNumber =
        'CNT-RNW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newId = await useCase.renewContract(
      oldContractId: oldContractId,
      newContractNumber: cntNumber,
      newStartDate: newStartDate,
      newEndDate: newEndDate,
      newBaseRent: newBaseRent,
      newServicesSnapshot: oldSnapshot,
    );
    await _refreshAllDependentControllers();
    return newId;
  }

  Future<void> executeContractTermination({
    required int contractId,
    required String terminationDate,
    required String terminationReason,
    required String nextApartmentStatus,
  }) async {
    if (!Get.isRegistered<ManageContractsUseCase>()) return;
    await Get.find<ManageContractsUseCase>().terminateContract(
      contractId: contractId,
      terminationDate: terminationDate,
      terminationReason: terminationReason,
      nextApartmentStatus: nextApartmentStatus,
    );
    await _refreshAllDependentControllers();
  }

  Future<void> _refreshAllDependentControllers() async {
    await loadContracts(syncFromDb: true);
    if (Get.isRegistered<ApartmentsController>()) {
      await Get.find<ApartmentsController>().loadApartments();
    }
    if (Get.isRegistered<TenantsController>()) {
      await Get.find<TenantsController>().loadTenants();
    }
    if (Get.isRegistered<InvoicesController>()) {
      await Get.find<InvoicesController>().loadInvoices();
    }
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  @override
  void onClose() {
    inlineTenantNameCtrl.dispose();
    inlineTenantPhoneCtrl.dispose();
    inlineTenantNationalIdCtrl.dispose();
    startDateCtrl.dispose();
    endDateCtrl.dispose();
    rentalDateCtrl.dispose();
    dueDayCtrl.dispose();
    baseRentCtrl.dispose();
    notesCtrl.dispose();
    newConditionCtrl.dispose();
    for (final c in servicePriceCtrls.values) {
      c.dispose();
    }
    super.onClose();
  }
}
