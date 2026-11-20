import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../../domain/entities/service_entity.dart';
import '../controllers/services_controller.dart';

class ServicesPage extends GetView<ServicesController> {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return AppScaffold(
      title: 'services_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceDialog(context),
        icon: const Icon(Icons.add),
        label: Text('add_service'.tr),
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
            const SizedBox(height: 14),
            Expanded(
              child: controller.obx(
                (services) => Obx(() {
                  final currency = storage.rxCurrency.value;
                  return ListView.separated(
                    itemCount: services!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final srv = services[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.miscellaneous_services,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            srv.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(srv.description),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StatusBadge(
                                    label: CurrencyUtils.formatAmount(
                                      srv.defaultPrice,
                                      currency: currency,
                                    ),
                                    color: AppTheme.primaryColor,
                                  ),
                                  StatusBadge(
                                    label: srv.billingType == 'fixed_monthly'
                                        ? 'billing_fixed_monthly'.tr
                                        : 'billing_usage_based'.tr,
                                    color: AppTheme.secondaryColor,
                                  ),
                                  StatusBadge(
                                    label: srv.isActive
                                        ? 'service_active'.tr
                                        : 'service_inactive'.tr,
                                    color: srv.isActive
                                        ? AppTheme.successColor
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _showServiceDialog(context, service: srv),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.errorColor,
                                ),
                                onPressed: () async {
                                  final ok = await ConfirmDialog.show(
                                    title: 'delete'.tr,
                                    message: '${'delete'.tr}: ${srv.name}?',
                                    confirmColor: AppTheme.errorColor,
                                  );
                                  if (ok) {
                                    try {
                                      await controller.deleteService(srv.id);
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
                          ),
                        ),
                      );
                    },
                  );
                }),
                onLoading: const AppLoading(),
                onEmpty: AppEmptyState(
                  onAction: () => _showServiceDialog(context),
                  actionLabel: 'add_service'.tr,
                ),
                onError: (err) => AppErrorState(
                  message: err,
                  onRetry: controller.loadServices,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, {ServiceEntity? service}) {
    final formKey = GlobalKey<FormState>();
    controller.nameCtrl.text = service?.name ?? '';
    controller.descCtrl.text = service?.description ?? '';
    controller.priceCtrl.text = (service?.defaultPrice ?? 100).toString();
    controller.billingType.value = service?.billingType ?? 'fixed_monthly';
    controller.isActive.value = service?.isActive ?? true;

    Get.dialog(
      AlertDialog(
        title: Text(service == null ? 'add_service'.tr : 'edit_service'.tr),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller.nameCtrl,
                    validator: AppValidators.requiredField,
                    decoration: InputDecoration(labelText: 'service_name'.tr),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.priceCtrl,
                    validator: AppValidators.positiveNumber,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'default_price'.tr),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.billingType.value,
                      decoration: InputDecoration(labelText: 'billing_type'.tr),
                      items: [
                        DropdownMenuItem(
                          value: 'fixed_monthly',
                          child: Text('billing_fixed_monthly'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'usage_based',
                          child: Text('billing_usage_based'.tr),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.billingType.value = v;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.descCtrl,
                    maxLines: 2,
                    decoration:
                        InputDecoration(labelText: 'service_description'.tr),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => SwitchListTile(
                      title: Text('service_active'.tr),
                      value: controller.isActive.value,
                      onChanged: (v) => controller.isActive.value = v,
                    ),
                  ),
                ],
              ),
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
                await controller.saveService(existing: service);
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
