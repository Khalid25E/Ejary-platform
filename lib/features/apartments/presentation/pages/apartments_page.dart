import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/apartment_entity.dart';
import '../../domain/entities/apartment_service_entity.dart';
import '../controllers/apartments_controller.dart';

class ApartmentsPage extends GetView<ApartmentsController> {
  const ApartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return AppScaffold(
      title: 'apartments_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.apartmentForm),
        icon: const Icon(Icons.add),
        label: Text('add_apartment'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => controller.searchQuery.value = v,
                    decoration: InputDecoration(
                      hintText: '${'search'.tr} (${'apartment_number'.tr})',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: controller.selectedPropertyId.value,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            'all'.tr,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...Phase1MockData.properties.map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.selectedPropertyId.value = v;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('all', 'all'.tr),
                    const SizedBox(width: 8),
                    _statusChip('vacant', 'apt_status_vacant'.tr),
                    const SizedBox(width: 8),
                    _statusChip('rented', 'apt_status_rented'.tr),
                    const SizedBox(width: 8),
                    _statusChip('maintenance', 'apt_status_maintenance'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: controller.obx(
                (apts) => Obx(() {
                  final currency = storage.rxCurrency.value;
                  return ListView.separated(
                    itemCount: apts!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final apt = apts[index];
                      final prop = Phase1MockData.getProperty(apt.propertyId);
                      final services = Phase1MockData.apartmentServices
                          .where((s) => s.apartmentId == apt.id && s.isActive)
                          .toList();
                      final servicesSum = services.fold<num>(
                        0,
                        (sum, s) => sum + s.customPrice,
                      );

                      return Card(
                        child: ListTile(
                          onTap: () => Get.toNamed(
                            AppRoutes.apartmentDetails,
                            arguments: apt.id,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                _statusColor(apt.status).withValues(alpha: 0.14),
                            child: Text(
                              apt.apartmentNumber,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(apt.status),
                              ),
                            ),
                          ),
                          title: Text(
                            '${apt.apartmentNumber} • ${prop?.name ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${'floor'.tr}: ${apt.floor} | ${'rooms_count'.tr}: ${apt.roomsCount} | ${'total_monthly_rent'.tr}: ${CurrencyUtils.formatAmount(apt.baseRent + servicesSum, currency: currency)}',
                          ),
                          trailing: StatusBadge(
                            label: _statusLabel(apt.status),
                            color: _statusColor(apt.status),
                          ),
                        ),
                      );
                    },
                  );
                }),
                onLoading: const AppLoading(),
                onEmpty: AppEmptyState(
                  icon: Icons.meeting_room_outlined,
                  onAction: () => Get.toNamed(AppRoutes.apartmentForm),
                  actionLabel: 'add_apartment'.tr,
                ),
                onError: (err) => AppErrorState(
                  message: err,
                  onRetry: controller.loadApartments,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedStatus.value == key,
      onSelected: (_) => controller.selectedStatus.value = key,
    );
  }

  static String _statusLabel(String st) {
    switch (st) {
      case 'rented':
        return 'apt_status_rented'.tr;
      case 'vacant':
        return 'apt_status_vacant'.tr;
      case 'maintenance':
        return 'apt_status_maintenance'.tr;
      default:
        return 'apt_status_unavailable'.tr;
    }
  }

  static Color _statusColor(String st) {
    switch (st) {
      case 'rented':
        return AppTheme.successColor;
      case 'vacant':
        return AppTheme.primaryColor;
      case 'maintenance':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }
}

class ApartmentFormPage extends GetView<ApartmentsController> {
  const ApartmentFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    ApartmentEntity? editingApt;
    int? initialPropId;
    if (args is ApartmentEntity) {
      editingApt = args;
    } else if (args is Map && args['propertyId'] is int) {
      initialPropId = args['propertyId'] as int;
    }
    controller.prepareForm(
      apartment: editingApt,
      initialPropertyId: initialPropId,
    );

    return AppScaffold(
      title: editingApt == null ? 'add_apartment'.tr : 'edit_apartment'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(() {
                        final props = Phase1MockData.properties;
                        final validPropId = props.any(
                          (p) => p.id == controller.formPropertyId.value,
                        )
                            ? controller.formPropertyId.value
                            : (props.isNotEmpty ? props.first.id : null);
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: validPropId,
                          decoration: InputDecoration(
                            labelText: 'property_name'.tr,
                            prefixIcon: const Icon(Icons.domain),
                          ),
                          items: props
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) controller.formPropertyId.value = v;
                          },
                        );
                      }),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller.aptNumberCtrl,
                        validator: AppValidators.requiredField,
                        decoration: InputDecoration(
                          labelText: 'apartment_number'.tr,
                          prefixIcon:
                              const Icon(Icons.door_front_door_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.floorCtrl,
                              validator: AppValidators.requiredField,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'floor'.tr,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: controller.roomsCtrl,
                              validator: AppValidators.positiveNumber,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'rooms_count'.tr,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.baseRentCtrl,
                              validator: AppValidators.positiveNumber,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'base_rent'.tr,
                                prefixIcon:
                                    const Icon(Icons.payments_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: controller.formStatus.value,
                                decoration: InputDecoration(
                                  labelText: 'status'.tr,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'vacant',
                                    child: Text('apt_status_vacant'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rented',
                                    child: Text('apt_status_rented'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'maintenance',
                                    child: Text('apt_status_maintenance'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'unavailable',
                                    child: Text('apt_status_unavailable'.tr),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    controller.formStatus.value = v;
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller.notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: 'notes'.tr),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (controller.formKey.currentState?.validate() ??
                              false) {
                            await controller.saveApartment(
                              existing: editingApt,
                            );
                            Get.back();
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text('save'.tr),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ApartmentDetailsPage extends StatelessWidget {
  const ApartmentDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final apts = Phase1MockData.apartments;
    if (apts.isEmpty) {
      return AppScaffold(
        title: 'apartment_details'.tr,
        body: const AppEmptyState(),
      );
    }

    final int aptId = Get.arguments is int ? Get.arguments as int : apts.first.id;
    final apt = Phase1MockData.getApartment(aptId) ?? apts.first;
    final prop = Phase1MockData.getProperty(apt.propertyId);

    final activeContract = Phase1MockData.contracts
        .where(
          (c) =>
              c.apartmentId == apt.id &&
              (c.status == 'active' || c.status == 'expiring'),
        )
        .firstOrNull;
    final currentTenant = activeContract != null
        ? Phase1MockData.getTenant(activeContract.tenantId)
        : null;

    final customServices = Phase1MockData.apartmentServices
        .where((s) => s.apartmentId == apt.id)
        .toList();
    final activeServicesTotal = customServices
        .where((s) => s.isActive)
        .fold<num>(0, (sum, s) => sum + s.customPrice);

    return AppScaffold(
      title: '${'apartment_details'.tr}: ${apt.apartmentNumber}',
      actions: [
        IconButton(
          tooltip: 'edit_apartment'.tr,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              Get.toNamed(AppRoutes.apartmentForm, arguments: apt),
        ),
      ],
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${apt.apartmentNumber} — ${prop?.name ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: ApartmentsPage._statusLabel(apt.status),
                            color: ApartmentsPage._statusColor(apt.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(apt.notes),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          _kv('floor'.tr, '${apt.floor}'),
                          _kv('rooms_count'.tr, '${apt.roomsCount}'),
                          _kv(
                            'base_rent'.tr,
                            CurrencyUtils.formatAmount(
                              apt.baseRent,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'total_monthly_services'.tr,
                            CurrencyUtils.formatAmount(
                              activeServicesTotal,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'total_monthly_rent'.tr,
                            CurrencyUtils.formatAmount(
                              apt.baseRent + activeServicesTotal,
                              currency: currency,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Current Tenant & Current Contract section (FR-04 & Section 7 cross-links)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'current_tenant'.tr} & ${'current_contract'.tr}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (activeContract != null && currentTenant != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            currentTenant.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(currentTenant.phone),
                          trailing: OutlinedButton(
                            onPressed: () => Get.toNamed(
                              AppRoutes.tenantDetails,
                              arguments: currentTenant.id,
                            ),
                            child: Text('tenant_details'.tr),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.description_outlined),
                          ),
                          title: Text(
                            '${'contract_number'.tr}: ${activeContract.contractNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${activeContract.startedAt} → ${activeContract.endAt}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => Get.toNamed(
                              AppRoutes.contractDetails,
                              arguments: activeContract.id,
                            ),
                            child: Text('contract_details'.tr),
                          ),
                        ),
                      ] else
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('no_active_tenant'.tr),
                            if (apt.status == 'vacant')
                              ElevatedButton.icon(
                                onPressed: () => Get.toNamed(
                                  AppRoutes.contractCreate,
                                  arguments: {'apartmentId': apt.id},
                                ),
                                icon: const Icon(Icons.add),
                                label: Text('create_contract'.tr),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // FR-06: Custom Apartment Services section
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'custom_services'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.apartmentServices,
                      arguments: apt.id,
                    ),
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text('manage_apartment_services'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (final cs in customServices)
                      ListTile(
                        leading: const Icon(Icons.miscellaneous_services),
                        title: Text(
                          Phase1MockData.getService(cs.serviceId)?.name ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(cs.notes),
                        trailing: Text(
                          CurrencyUtils.formatAmount(
                            cs.customPrice,
                            currency: currency,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }
}

/// FR-06: Custom Apartment Services Screen
class ApartmentServicesPage extends StatefulWidget {
  const ApartmentServicesPage({super.key});

  @override
  State<ApartmentServicesPage> createState() => _ApartmentServicesPageState();
}

class _ApartmentServicesPageState extends State<ApartmentServicesPage> {
  late int aptId;
  final Map<int, bool> activeMap = {};
  final Map<int, TextEditingController> priceCtrls = {};

  @override
  void initState() {
    super.initState();
    final apts = Phase1MockData.apartments;
    aptId = Get.arguments is int
        ? Get.arguments as int
        : (apts.isNotEmpty ? apts.first.id : 0);
    for (final srv in Phase1MockData.services) {
      final existing = Phase1MockData.apartmentServices
          .where(
            (asrv) => asrv.apartmentId == aptId && asrv.serviceId == srv.id,
          )
          .firstOrNull;
      activeMap[srv.id] = existing?.isActive ?? false;
      priceCtrls[srv.id] = TextEditingController(
        text: (existing?.customPrice ?? srv.defaultPrice).toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final c in priceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  num get totalActiveServices {
    num sum = 0;
    for (final srv in Phase1MockData.services) {
      if (activeMap[srv.id] == true) {
        sum += num.tryParse(priceCtrls[srv.id]?.text ?? '0') ?? 0;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final apts = Phase1MockData.apartments;
    if (apts.isEmpty) {
      return AppScaffold(
        title: 'manage_apartment_services'.tr,
        body: const AppEmptyState(),
      );
    }
    final apt = Phase1MockData.getApartment(aptId) ?? apts.first;

    return AppScaffold(
      title: '${'manage_apartment_services'.tr} (${apt.apartmentNumber})',
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(
                    'total_monthly_services'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Text(
                    CurrencyUtils.formatAmount(
                      totalActiveServices,
                      currency: currency,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: Phase1MockData.services.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final srv = Phase1MockData.services[index];
                    final isChecked = activeMap[srv.id] ?? false;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (v) {
                                setState(() {
                                  activeMap[srv.id] = v ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    srv.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${'default_price'.tr}: ${CurrencyUtils.formatAmount(srv.defaultPrice, currency: currency)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: priceCtrls[srv.id],
                                enabled: isChecked,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'custom_price'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
                    final list = <ApartmentServiceEntity>[];
                    for (final srv in Phase1MockData.services) {
                      if (activeMap[srv.id] == true) {
                        final customPrice =
                            num.tryParse(priceCtrls[srv.id]?.text ?? '0') ??
                                srv.defaultPrice;
                        list.add(
                          ApartmentServiceEntity(
                            id: 0,
                            apartmentId: apt.id,
                            serviceId: srv.id,
                            customPrice: customPrice,
                            billingType: srv.billingType,
                            isActive: true,
                            notes: srv.name,
                            createdAt: nowIso,
                          ),
                        );
                      }
                    }
                    await Get.find<ApartmentsController>()
                        .saveCustomServices(apt.id, list);
                    Get.back();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: Text('save'.tr),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
