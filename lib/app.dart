import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/locale_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'routes/initial_binding.dart';

class EjaryApp extends StatelessWidget {
  const EjaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final themeService = Get.find<ThemeService>();
    final localeService = Get.find<LocaleService>();

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      translations: AppTranslations(),
      locale: localeService.locale,
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: storage.isOwnerSetupDone
          ? AppRoutes.dashboard
          : AppRoutes.onboarding,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}
