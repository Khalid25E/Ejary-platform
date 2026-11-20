import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/zone_entity.dart';
import '../controllers/zones_controller.dart';

class ZonesPage extends GetView<ZonesController> {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'zones_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showZoneFormDialog(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text('add_zone'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.obx(
                (zones) => ListView.separated(
                  itemCount: zones!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    final propCount =
                        controller.getPropertyCountForZone(zone.id);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        title: Text(
                          zone.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(zone.description),
                            const SizedBox(height: 8),
                            StatusBadge(
                              label: '${'properties_count'.tr}: $propCount',
                              color: scheme.primary,
                              icon: Icons.apartment,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'edit'.tr,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showZoneFormDialog(context, zone: zone),
                            ),
                            IconButton(
                              tooltip: 'delete'.tr,
                              icon: Icon(
                                Icons.delete_outline,
                                color: scheme.error,
                              ),
                              onPressed: () =>
                                  _handleDeleteZone(zone, propCount),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                onLoading: const AppLoading(),
                onEmpty: AppEmptyState(
                  icon: Icons.map_outlined,
                  onAction: () => _showZoneFormDialog(context),
                  actionLabel: 'add_zone'.tr,
                ),
                onError: (err) => AppErrorState(
                  message: err,
                  onRetry: controller.loadZones,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteZone(ZoneEntity zone, int propCount) async {
    if (propCount > 0) {
      Get.dialog(
        AlertDialog(
          icon: const Icon(Icons.block, color: Color(0xFFB91C1C), size: 40),
          title: Text('delete'.tr),
          content: Text('zone_delete_blocked'.tr),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('close'.tr),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await ConfirmDialog.show(
      title: 'delete'.tr,
      message: '${'delete'.tr}: ${zone.name}?',
      confirmColor: const Color(0xFFB91C1C),
    );
    if (confirmed) {
      await controller.deleteZone(zone.id);
    }
  }

  void _showZoneFormDialog(BuildContext context, {ZoneEntity? zone}) {
    final formKey = GlobalKey<FormState>();
    controller.nameCtrl.text = zone?.name ?? '';
    controller.descCtrl.text = zone?.description ?? '';

    Get.dialog(
      AlertDialog(
        title: Text(zone == null ? 'add_zone'.tr : 'edit_zone'.tr),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller.nameCtrl,
                  validator: AppValidators.requiredField,
                  decoration: InputDecoration(labelText: 'zone_name'.tr),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller.descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: 'zone_description'.tr),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                await controller.saveZone(existing: zone);
                Get.back();
              }
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
