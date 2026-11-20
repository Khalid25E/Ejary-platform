import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/property_entity.dart';
import '../controllers/properties_controller.dart';

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'properties_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.propertyForm),
        icon: const Icon(Icons.add_business_outlined),
        label: Text('add_property'.tr),
      ),
      body: const PropertiesListView(isEmbedded: false),
    );
  }
}

class PropertiesListView extends GetView<PropertiesController> {
  final bool isEmbedded;

  const PropertiesListView({super.key, required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => controller.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              if (isEmbedded) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.propertyForm),
                  icon: const Icon(Icons.add),
                  label: Text('add_property'.tr),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'all'.tr),
                  const SizedBox(width: 8),
                  _buildFilterChip('active', 'status_active'.tr),
                  const SizedBox(width: 8),
                  _buildFilterChip('maintenance', 'status_maintenance'.tr),
                  const SizedBox(width: 8),
                  _buildFilterChip('inactive', 'status_inactive'.tr),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.apartments),
                    icon: const Icon(Icons.meeting_room_outlined, size: 18),
                    label: Text('apartments_title'.tr),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: controller.obx(
              (properties) => ListView.separated(
                itemCount: properties!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prop = properties[index];
                  final zone = Phase1MockData.getZone(prop.zoneId);
                  final apts = Phase1MockData.apartments
                      .where((a) => a.propertyId == prop.id)
                      .toList();
                  final rentedCount =
                      apts.where((a) => a.status == 'rented').length;
                  final vacantCount =
                      apts.where((a) => a.status == 'vacant').length;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Get.toNamed(
                        AppRoutes.propertyDetails,
                        arguments: prop.id,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.domain,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prop.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${zone?.name ?? '-'} • ${_translateType(prop.type)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: _translateStatus(prop.status),
                                  color: _statusColor(prop.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              prop.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                StatusBadge(
                                  label:
                                      '${'total_apartments'.tr}: ${apts.length}',
                                  color: AppTheme.primaryColor,
                                  icon: Icons.meeting_room_outlined,
                                ),
                                StatusBadge(
                                  label:
                                      '${'rented_apartments'.tr}: $rentedCount',
                                  color: AppTheme.successColor,
                                ),
                                StatusBadge(
                                  label:
                                      '${'vacant_apartments'.tr}: $vacantCount',
                                  color: AppTheme.secondaryColor,
                                ),
                                Obx(
                                  () => Text(
                                    '${'owner_full_name'.tr}: ${storage.rxOwnerName.value}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              onLoading: const AppLoading(),
              onEmpty: AppEmptyState(
                icon: Icons.domain_disabled_outlined,
                onAction: () => Get.toNamed(AppRoutes.propertyForm),
                actionLabel: 'add_property'.tr,
              ),
              onError: (err) => AppErrorState(
                message: err,
                onRetry: controller.loadProperties,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = controller.statusFilter.value == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.statusFilter.value = key,
    );
  }

  static String _translateType(String type) {
    switch (type) {
      case 'residential':
        return 'type_residential'.tr;
      case 'commercial':
        return 'type_commercial'.tr;
      case 'mixed':
        return 'type_mixed'.tr;
      default:
        return 'type_other'.tr;
    }
  }

  static String _translateStatus(String status) {
    switch (status) {
      case 'active':
        return 'status_active'.tr;
      case 'maintenance':
        return 'status_maintenance'.tr;
      default:
        return 'status_inactive'.tr;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successColor;
      case 'maintenance':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }
}

class PropertyFormPage extends GetView<PropertiesController> {
  const PropertyFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PropertyEntity? editingProperty =
        Get.arguments is PropertyEntity ? Get.arguments as PropertyEntity : null;
    controller.prepareForm(property: editingProperty);

    return AppScaffold(
      title: editingProperty == null ? 'add_property'.tr : 'edit_property'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: controller.nameCtrl,
                        validator: AppValidators.requiredField,
                        decoration: InputDecoration(
                          labelText: 'property_name'.tr,
                          prefixIcon: const Icon(Icons.domain),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final zones = Phase1MockData.zones;
                        final validZoneId = zones
                                .any((z) => z.id == controller.selectedZoneId.value)
                            ? controller.selectedZoneId.value
                            : (zones.isNotEmpty ? zones.first.id : null);
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: validZoneId,
                          decoration: InputDecoration(
                            labelText: 'property_zone'.tr,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                          items: zones
                              .map(
                                (z) => DropdownMenuItem(
                                  value: z.id,
                                  child: Text(
                                    z.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) controller.selectedZoneId.value = v;
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: controller.selectedType.value,
                                decoration: InputDecoration(
                                  labelText: 'property_type'.tr,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'residential',
                                    child: Text('type_residential'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'commercial',
                                    child: Text('type_commercial'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'mixed',
                                    child: Text('type_mixed'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text('type_other'.tr),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    controller.selectedType.value = v;
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: controller.selectedStatus.value,
                                decoration: InputDecoration(
                                  labelText: 'property_status'.tr,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('status_active'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'maintenance',
                                    child: Text('status_maintenance'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'inactive',
                                    child: Text('status_inactive'.tr),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    controller.selectedStatus.value = v;
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.latCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'latitude'.tr,
                                prefixIcon: const Icon(Icons.my_location),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: controller.lngCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'longitude'.tr,
                                prefixIcon: const Icon(Icons.explore_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'property_description'.tr,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (controller.formKey.currentState?.validate() ??
                              false) {
                            await controller.saveProperty(
                              existing: editingProperty,
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

class PropertyDetailsPage extends GetView<PropertiesController> {
  const PropertyDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final props = Phase1MockData.properties;
    if (props.isEmpty) {
      return AppScaffold(
        title: 'property_details'.tr,
        body: const AppEmptyState(),
      );
    }

    final int propId = Get.arguments is int ? Get.arguments as int : props.first.id;
    final prop = Phase1MockData.getProperty(propId) ?? props.first;
    final zone = Phase1MockData.getZone(prop.zoneId);
    final apts = Phase1MockData.apartments
        .where((a) => a.propertyId == prop.id)
        .toList();
    final aptIds = apts.map((a) => a.id).toSet();
    final propContracts = Phase1MockData.contracts
        .where((c) => aptIds.contains(c.apartmentId))
        .toList();
    final contractIds = propContracts.map((c) => c.id).toSet();
    final propInvoices = Phase1MockData.invoices
        .where((i) => contractIds.contains(i.contractId))
        .toList();

    final collectedRev =
        propInvoices.fold<num>(0, (sum, i) => sum + i.paidAmount);
    final remainingDues =
        propInvoices.fold<num>(0, (sum, i) => sum + i.remainingAmount);

    return AppScaffold(
      title: '${'property_details'.tr}: ${prop.name}',
      actions: [
        IconButton(
          tooltip: 'edit_property'.tr,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              Get.toNamed(AppRoutes.propertyForm, arguments: prop),
        ),
        IconButton(
          tooltip: 'delete'.tr,
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await ConfirmDialog.show(
              title: 'delete'.tr,
              message: '${'delete'.tr}: ${prop.name}?',
              confirmColor: AppTheme.errorColor,
            );
            if (ok) {
              try {
                await controller.deleteProperty(prop.id);
                Get.back();
              } catch (e) {
                Get.snackbar(
                  'delete'.tr,
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(
          AppRoutes.apartmentForm,
          arguments: {'propertyId': prop.id},
        ),
        icon: const Icon(Icons.add),
        label: Text('add_apartment'.tr),
      ),
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
                              prop.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label:
                                PropertiesListView._translateStatus(prop.status),
                            color: PropertiesListView._statusColor(prop.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(prop.description),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _infoItem('property_zone'.tr, zone?.name ?? '-'),
                          _infoItem(
                            'property_type'.tr,
                            PropertiesListView._translateType(prop.type),
                          ),
                          _infoItem(
                            'owner_full_name'.tr,
                            storage.rxOwnerName.value,
                          ),
                          _infoItem(
                            'owner_phone'.tr,
                            storage.rxOwnerPhone.value,
                          ),
                          _infoItem(
                            'Coordinates',
                            '${prop.latitude ?? '-'}, ${prop.longitude ?? '-'}',
                          ),
                          _infoItem(
                            'property_revenues'.tr,
                            CurrencyUtils.formatAmount(
                              collectedRev,
                              currency: currency,
                            ),
                          ),
                          _infoItem(
                            'property_dues'.tr,
                            CurrencyUtils.formatAmount(
                              remainingDues,
                              currency: currency,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${'apartments_title'.tr} (${apts.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: apts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final apt = apts[index];
                  return Card(
                    child: ListTile(
                      onTap: () => Get.toNamed(
                        AppRoutes.apartmentDetails,
                        arguments: apt.id,
                      ),
                      leading: CircleAvatar(
                        child: Text(
                          apt.apartmentNumber,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(
                        '${'apartment_number'.tr}: ${apt.apartmentNumber} (${'floor'.tr} ${apt.floor})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${'rooms_count'.tr}: ${apt.roomsCount} • ${'base_rent'.tr}: ${CurrencyUtils.formatAmount(apt.baseRent, currency: currency)}',
                      ),
                      trailing: StatusBadge(
                        label: _aptStatusLabel(apt.status),
                        color: _aptStatusColor(apt.status),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  static String _aptStatusLabel(String status) {
    switch (status) {
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

  static Color _aptStatusColor(String status) {
    switch (status) {
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
