import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/localization/locale_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/datasources/backup_local_datasource.dart';
import '../../domain/entities/backup_metadata_entity.dart';

class SettingsController extends GetxController {
  final LocalStorageService storage = Get.find<LocalStorageService>();
  final ThemeService themeService = Get.find<ThemeService>();
  final LocaleService localeService = Get.find<LocaleService>();

  late final TextEditingController ownerNameCtrl;
  late final TextEditingController ownerPhoneCtrl;
  final RxString currency = 'SAR'.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxList<BackupMetadataEntity> localBackups =
      <BackupMetadataEntity>[].obs;
  final RxString lastExportedBackupPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ownerNameCtrl = TextEditingController(text: storage.ownerName);
    ownerPhoneCtrl = TextEditingController(text: storage.ownerPhone);
    currency.value = storage.defaultCurrency;
    notificationsEnabled.value = storage.notificationsEnabled;
    refreshLocalBackups();
  }

  Future<void> saveOwnerProfile() async {
    if (ownerNameCtrl.text.trim().isEmpty ||
        ownerPhoneCtrl.text.trim().isEmpty) {
      return;
    }
    await storage.setOwnerName(ownerNameCtrl.text.trim());
    await storage.setOwnerPhone(ownerPhoneCtrl.text.trim());
    await storage.setDefaultCurrency(currency.value);
    Get.snackbar(
      'settings_title'.tr,
      'owner_profile_saved'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> toggleNotifications(bool val) async {
    notificationsEnabled.value = val;
    await storage.setNotificationsEnabled(val);
  }

  Future<void> refreshLocalBackups() async {
    if (!Get.isRegistered<BackupLocalDataSource>()) return;
    final list =
        await Get.find<BackupLocalDataSource>().listLocalBackups();
    localBackups.assignAll(list);
    if (list.isNotEmpty && lastExportedBackupPath.value.isEmpty) {
      lastExportedBackupPath.value = list.first.fileName;
    }
  }

  Future<File?> exportLocalBackup() async {
    if (!Get.isRegistered<BackupLocalDataSource>()) return null;
    final file =
        await Get.find<BackupLocalDataSource>().exportBackupToFile();
    lastExportedBackupPath.value = file.path;
    await refreshLocalBackups();
    return file;
  }

  Future<void> shareLatestBackup() async {
    File? file;
    if (lastExportedBackupPath.value.isNotEmpty &&
        await File(lastExportedBackupPath.value).exists()) {
      file = File(lastExportedBackupPath.value);
    } else {
      file = await exportLocalBackup();
    }
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Ejary Platform Local Database Backup',
        ),
      );
    }
  }

  Future<File?> restoreBackupFromFile(File backupFile) async {
    if (!Get.isRegistered<BackupLocalDataSource>()) return null;
    final safetyFile = await Get.find<BackupLocalDataSource>()
        .restoreFromBackupFile(backupFile);
    await _reloadGlobalDatabaseState();
    await refreshLocalBackups();
    return safetyFile;
  }

  /// Section 3 Policy: Optional action to load realistic interconnected demo seed data
  /// only if the database is currently empty. Never overwrites existing owner data.
  Future<bool> loadOptionalDemoData() async {
    if (!Get.isRegistered<AppDatabase>()) return false;
    final inserted =
        await Get.find<AppDatabase>().loadOptionalDemoSeedData();
    if (inserted) {
      await _reloadGlobalDatabaseState();
    }
    return inserted;
  }

  Future<void> _reloadGlobalDatabaseState() async {
    if (Get.isRegistered<DatabaseLookupService>()) {
      await Get.find<DatabaseLookupService>().refreshAll();
    }
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  Future<void> resetApplication() async {
    await storage.setOwnerSetupDone(false);
    Get.offAllNamed(AppRoutes.onboarding);
  }

  List<String> get currencies => AppConstants.supportedCurrencies;

  @override
  void onClose() {
    ownerNameCtrl.dispose();
    ownerPhoneCtrl.dispose();
    super.onClose();
  }
}
