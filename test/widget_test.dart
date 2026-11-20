import 'package:ejary/app.dart';
import 'package:ejary/core/constants/app_constants.dart';
import 'package:ejary/core/database/app_database.dart';
import 'package:ejary/core/database/database_lookup_service.dart';
import 'package:ejary/core/localization/locale_service.dart';
import 'package:ejary/core/storage/local_storage_service.dart';
import 'package:ejary/core/theme/theme_service.dart';
import 'package:ejary/core/utils/currency_utils.dart';
import 'package:ejary/features/contracts/presentation/controllers/contracts_controller.dart';
import 'package:ejary/routes/app_routes.dart';
import 'package:ejary/routes/initial_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _TestLocalStorageService extends LocalStorageService {
  bool _setupDone = false;
  String _name = 'أحمد محمد المنصور';
  String _phone = '+966 50 123 4567';
  String _currency = 'SAR';
  String _theme = 'light';
  String _locale = 'ar';
  bool _notifications = true;

  @override
  bool get isOwnerSetupDone => _setupDone;

  @override
  Future<void> setOwnerSetupDone(bool value) async => _setupDone = value;

  @override
  String get ownerName => _name;

  @override
  Future<void> setOwnerName(String value) async {
    _name = value;
    rxOwnerName.value = value;
  }

  @override
  String get ownerPhone => _phone;

  @override
  Future<void> setOwnerPhone(String value) async {
    _phone = value;
    rxOwnerPhone.value = value;
  }

  @override
  String get defaultCurrency => _currency;

  @override
  Future<void> setDefaultCurrency(String value) async {
    _currency = value;
    rxCurrency.value = value;
  }

  @override
  String get themeMode => _theme;

  @override
  Future<void> setThemeMode(String value) async => _theme = value;

  @override
  String get localeCode => _locale;

  @override
  Future<void> setLocaleCode(String value) async => _locale = value;

  @override
  bool get notificationsEnabled => _notifications;

  @override
  Future<void> setNotificationsEnabled(bool value) async =>
      _notifications = value;

  @override
  Future<void> setOwnerAvatar(String? value) async {}
}

void main() {
  late _TestLocalStorageService testStorage;
  late AppDatabase appDb;

  setUp(() async {
    Get.reset();
    testStorage = _TestLocalStorageService();
    Get.put<LocalStorageService>(testStorage, permanent: true);

    appDb = await AppDatabase(
      isTestEnvironment: true,
      autoSeedInTest: true,
    ).init();
    Get.put<AppDatabase>(appDb, permanent: true);

    final lookupService = await DatabaseLookupService(appDb).refreshAll();
    Get.put<DatabaseLookupService>(lookupService, permanent: true);

    Get.put<ThemeService>(ThemeService(), permanent: true);
    Get.put<LocaleService>(LocaleService(), permanent: true);
    InitialBinding().dependencies();
  });

  tearDown(() async {
    await appDb.close();
  });

  test('Yemeni Rial (YER) currency support in Arabic and English', () {
    expect(AppConstants.supportedCurrencies.contains('YER'), isTrue);

    final localeService = Get.find<LocaleService>();
    localeService.currentLang.value = 'ar';
    expect(CurrencyUtils.displaySymbol('YER'), equals('ر.ي'));
    expect(
      CurrencyUtils.getCurrencyLabel('YER'),
      contains('الريال اليمني'),
    );
    expect(
      CurrencyUtils.formatAmount(9550, currency: 'YER'),
      equals('9,550 ر.ي'),
    );

    localeService.currentLang.value = 'en';
    expect(CurrencyUtils.displaySymbol('YER'), equals('YER'));
    expect(
      CurrencyUtils.getCurrencyLabel('YER'),
      equals('Yemeni Rial (YER)'),
    );
    expect(
      CurrencyUtils.formatAmount(9550, currency: 'YER'),
      equals('9,550 YER'),
    );
  });

  testWidgets(
      'End-to-End SQLite UI Integration on Small Mobile Screen (360x780): Onboarding with YER, Dashboard KPIs, Charts, and All 26 Screens have ZERO overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const EjaryApp());
    await tester.pumpAndSettle();

    // 1. Verify Onboarding screen & select Yemeni Rial (YER)
    expect(find.text('إعداد بيانات مالك العقارات'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('الريال اليمني (ر.ي) — YER'), findsWidgets);
    await tester.tap(find.text('الريال اليمني (ر.ي) — YER').last);
    await tester.pumpAndSettle();

    // Complete setup
    final setupBtn = find.text('إتمام الإعداد والدخول للوحة التحكم');
    await tester.ensureVisible(setupBtn);
    await tester.pumpAndSettle();
    await tester.tap(setupBtn);
    await tester.pumpAndSettle();

    // 2. Verify YER currency ('ر.ي') appears on SQLite-backed Dashboard KPI cards without any overflow
    expect(testStorage.defaultCurrency, equals('YER'));
    expect(find.textContaining('9,550 ر.ي'), findsWidgets);
    expect(find.textContaining('4,250 ر.ي'), findsWidgets);

    // Scroll down Dashboard to render Alerts & Charts on 360px width
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // 3. Navigate across all 5 Bottom Navigation tabs on 360px screen
    await tester.tap(find.text('العقارات'));
    await tester.pumpAndSettle();
    expect(find.text('مجمع النرجس السكني'), findsOneWidget);

    await tester.tap(find.text('المستأجرون'));
    await tester.pumpAndSettle();
    expect(find.text('خالد بن عبد الله العتيبي'), findsOneWidget);

    await tester.tap(find.text('المستحقات'));
    await tester.pumpAndSettle();
    expect(find.text('توليد فواتير الشهر'), findsOneWidget);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();

    // 4. Navigate through all detail & form routes on 360px screen to verify zero RenderFlex overflow
    final routesToTest = [
      AppRoutes.propertyForm,
      AppRoutes.propertyDetails,
      AppRoutes.apartments,
      AppRoutes.apartmentForm,
      AppRoutes.apartmentDetails,
      AppRoutes.apartmentServices,
      AppRoutes.services,
      AppRoutes.zones,
      AppRoutes.tenantForm,
      AppRoutes.tenantDetails,
      AppRoutes.tenantStatement,
      AppRoutes.contracts,
      AppRoutes.contractCreate,
      AppRoutes.contractDetails,
      AppRoutes.contractRenew,
      AppRoutes.contractTerminate,
      AppRoutes.invoiceDetails,
      AppRoutes.payments,
      AppRoutes.paymentRecord,
      AppRoutes.paymentReceipt,
      AppRoutes.settings,
      AppRoutes.backupRestore,
      AppRoutes.reports,
    ];

    for (final route in routesToTest) {
      Get.toNamed(route);
      await tester.pumpAndSettle();
      if (route == AppRoutes.contractCreate) {
        final wizardCtrl = Get.find<ContractsController>();
        for (int step = 0; step <= 5; step++) {
          wizardCtrl.setWizardStep(step);
          await tester.pumpAndSettle();
        }
      }
    }
  });

  testWidgets(
      'Ultra-narrow screen (320x640) in English LTR & Dark Mode: ZERO overflow on SQLite-backed Dashboard and key screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await testStorage.setOwnerSetupDone(true);
    await testStorage.setDefaultCurrency('YER');
    Get.find<LocaleService>().currentLang.value = 'en';
    Get.find<ThemeService>().isDarkMode.value = true;

    await tester.pumpWidget(const EjaryApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('9,550 YER'), findsWidgets);

    // Scroll Dashboard on 320px width
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // Test Payment Receipt & Contract Details on 320px width in English LTR
    Get.toNamed(AppRoutes.paymentReceipt);
    await tester.pumpAndSettle();
    Get.toNamed(AppRoutes.contractDetails);
    await tester.pumpAndSettle();
  });
}
