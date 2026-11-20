import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_lookup_service.dart';
import 'core/localization/locale_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/theme_service.dart';
import 'routes/initial_binding.dart';

Future<void> main() async {
  // 1. WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize GetStorage & LocalStorageService
  final storageService = await LocalStorageService().init();
  Get.put<LocalStorageService>(storageService, permanent: true);

  // 3 & 4 & 5. Initialize SQLite Database with Foreign Keys ON.
  // Production mode (isTestEnvironment: false) starts with an empty database
  // on first run per Section 3 policy so the owner enters their real data.
  final appDb = await AppDatabase(
    isTestEnvironment: false,
    autoSeedInTest: false,
  ).init();
  Get.put<AppDatabase>(appDb, permanent: true);

  // 6 & 7. Register Lookup Cache, Theme, Locale & Feature Repositories/UseCases
  final lookupService = await DatabaseLookupService(appDb).refreshAll();
  Get.put<DatabaseLookupService>(lookupService, permanent: true);

  Get.put<ThemeService>(ThemeService(), permanent: true);
  Get.put<LocaleService>(LocaleService(), permanent: true);
  InitialBinding().dependencies();

  // 8. Run Application
  runApp(const EjaryApp());
}
