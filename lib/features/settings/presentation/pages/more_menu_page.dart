import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

/// Section 7 "More" Tab Hub View
class MoreMenuView extends StatelessWidget {
  const MoreMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final firstContractId = Phase1MockData.contracts.isNotEmpty
        ? Phase1MockData.contracts.first.id
        : 1;

    final items = [
      _MoreItem(
        title: 'contracts_title'.tr,
        subtitle: 'create_contract'.tr,
        icon: Icons.description_outlined,
        color: AppTheme.primaryColor,
        onTap: () => Get.toNamed(AppRoutes.contracts),
      ),
      _MoreItem(
        title: 'create_contract'.tr,
        subtitle: 'step_1_title'.tr,
        icon: Icons.note_add_outlined,
        color: AppTheme.successColor,
        onTap: () => Get.toNamed(AppRoutes.contractCreate),
      ),
      _MoreItem(
        title: 'renew_contract'.tr,
        subtitle: 'expiring_contracts'.tr,
        icon: Icons.autorenew,
        color: AppTheme.secondaryColor,
        onTap: () => Get.toNamed(
          AppRoutes.contractRenew,
          arguments: firstContractId,
        ),
      ),
      _MoreItem(
        title: 'terminate_contract'.tr,
        subtitle: 'contract_status_terminated'.tr,
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
        onTap: () => Get.toNamed(
          AppRoutes.contractTerminate,
          arguments: firstContractId,
        ),
      ),
      _MoreItem(
        title: 'services_title'.tr,
        subtitle: 'custom_services'.tr,
        icon: Icons.miscellaneous_services_outlined,
        color: AppTheme.primaryColor,
        onTap: () => Get.toNamed(AppRoutes.services),
      ),
      _MoreItem(
        title: 'zones_title'.tr,
        subtitle: 'property_zone'.tr,
        icon: Icons.map_outlined,
        color: AppTheme.secondaryColor,
        onTap: () => Get.toNamed(AppRoutes.zones),
      ),
      _MoreItem(
        title: 'reports_title'.tr,
        subtitle: 'monthly_collections'.tr,
        icon: Icons.analytics_outlined,
        color: AppTheme.primaryColor,
        onTap: () => Get.toNamed(AppRoutes.reports),
      ),
      _MoreItem(
        title: 'backup_restore_title'.tr,
        subtitle: 'export_backup'.tr,
        icon: Icons.backup_outlined,
        color: AppTheme.warningColor,
        onTap: () => Get.toNamed(AppRoutes.backupRestore),
      ),
      _MoreItem(
        title: 'settings_title'.tr,
        subtitle: 'appearance_language_section'.tr,
        icon: Icons.settings_outlined,
        color: AppTheme.primaryColor,
        onTap: () => Get.toNamed(AppRoutes.settings),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            onTap: item.onTap,
            leading: CircleAvatar(
              backgroundColor: item.color.withValues(alpha: 0.12),
              child: Icon(item.icon, color: item.color),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
          ),
        );
      },
    );
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// FR-18: Full Settings Page
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'settings_title'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Property Owner Profile
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'owner_info_section'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: controller.ownerNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'owner_full_name'.tr,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.ownerPhoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'owner_phone'.tr,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.currency.value,
                            decoration: InputDecoration(
                              labelText: 'default_currency'.tr,
                              prefixIcon: const Icon(Icons.payments_outlined),
                            ),
                            items: controller.currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      CurrencyUtils.getCurrencyLabel(c),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) controller.currency.value = v;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: controller.saveOwnerProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: Text('save'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 2. Language, Theme & Notifications
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'appearance_language_section'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.language),
                            title: Text('language'.tr),
                            subtitle: Text(
                              controller.localeService.isArabic
                                  ? 'arabic'.tr
                                  : 'english'.tr,
                            ),
                            trailing: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'ar', label: Text('AR')),
                                ButtonSegment(value: 'en', label: Text('EN')),
                              ],
                              selected: {
                                controller.localeService.currentLang.value,
                              },
                              onSelectionChanged: (s) =>
                                  controller.localeService.changeLocale(s.first),
                            ),
                          ),
                        ),
                        const Divider(),
                        Obx(
                          () => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              controller.themeService.isDarkMode.value
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                            ),
                            title: Text('theme_mode'.tr),
                            subtitle: Text(
                              controller.themeService.isDarkMode.value
                                  ? 'dark_theme'.tr
                                  : 'light_theme'.tr,
                            ),
                            value: controller.themeService.isDarkMode.value,
                            onChanged: (v) =>
                                controller.themeService.setDarkMode(v),
                          ),
                        ),
                        const Divider(),
                        Obx(
                          () => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary:
                                const Icon(Icons.notifications_active_outlined),
                            title: Text('local_notifications'.tr),
                            value: controller.notificationsEnabled.value,
                            onChanged: controller.toggleNotifications,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 3. Backup, Demo Data Option, App Info & Reset
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: Text('backup_restore_title'.tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                        onTap: () => Get.toNamed(AppRoutes.backupRestore),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.dataset_outlined,
                          color: AppTheme.secondaryColor,
                        ),
                        title: const Text('Load Demo Seed Data / بيانات تجريبية'),
                        subtitle: const Text(
                          'Inserts sample records only if the database is empty.',
                        ),
                        onTap: () async {
                          final inserted =
                              await controller.loadOptionalDemoData();
                          Get.snackbar(
                            'app_name'.tr,
                            inserted
                                ? 'Demo seed data loaded successfully.'
                                : 'Database already contains data (skipped to protect existing data).',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text('app_info'.tr),
                        subtitle: const Text(
                          '${AppConstants.appName} v${AppConstants.appVersion} (Offline-First • Single Owner)',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.restore_page_outlined,
                          color: AppTheme.errorColor,
                        ),
                        title: Text(
                          'reset_app'.tr,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text('reset_app_warning'.tr),
                        onTap: () async {
                          final ok = await ConfirmDialog.show(
                            title: 'reset_app'.tr,
                            message: 'reset_app_warning'.tr,
                            confirmColor: AppTheme.errorColor,
                          );
                          if (ok) {
                            await controller.resetApplication();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section 17: Local Backup & Restore Page
class BackupRestorePage extends GetView<SettingsController> {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'backup_restore_title'.tr,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.security_update_good_outlined,
                        size: 52,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'backup_restore_title'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'backup_safety_note'.tr,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final file = await controller.exportLocalBackup();
                          if (file != null) {
                            Get.snackbar(
                              'export_backup'.tr,
                              file.path,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: Text('export_backup'.tr),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await controller.shareLatestBackup();
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: Text('share_backup'.tr),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final path = controller.lastExportedBackupPath.value;
                          if (path.isNotEmpty && await File(path).exists()) {
                            final safety = await controller
                                .restoreBackupFromFile(File(path));
                            Get.snackbar(
                              'restore_backup'.tr,
                              'Restored successfully (Safety backup: ${safety?.path ?? ''})',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              'restore_backup'.tr,
                              'No local backup file found to restore.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text('restore_backup'.tr),
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

/// Section 7: Financial & Property Reports Overview Screen
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final totalInvoiced = Phase1MockData.invoices.fold<num>(
      0,
      (sum, i) => sum + i.totalAmount,
    );
    final totalPaid = Phase1MockData.invoices.fold<num>(
      0,
      (sum, i) => sum + i.paidAmount,
    );
    final totalRemaining = Phase1MockData.invoices.fold<num>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );

    return AppScaffold(
      title: 'reports_title'.tr,
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reports_title'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(height: 24),
                    _reportRow(
                      'total_billed'.tr,
                      CurrencyUtils.formatAmount(
                        totalInvoiced,
                        currency: currency,
                      ),
                    ),
                    _reportRow(
                      'total_paid'.tr,
                      CurrencyUtils.formatAmount(totalPaid, currency: currency),
                    ),
                    _reportRow(
                      'remaining_balance'.tr,
                      CurrencyUtils.formatAmount(
                        totalRemaining,
                        currency: currency,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(flex: 2, child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
