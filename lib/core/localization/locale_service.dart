import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../storage/local_storage_service.dart';

class LocaleService extends GetxService {
  final LocalStorageService _storage = Get.find<LocalStorageService>();
  final RxString currentLang = 'ar'.obs;

  @override
  void onInit() {
    super.onInit();
    currentLang.value = _storage.localeCode;
  }

  Locale get locale =>
      currentLang.value == 'en' ? const Locale('en') : const Locale('ar');

  bool get isArabic => currentLang.value == 'ar';

  Future<void> changeLocale(String langCode) async {
    currentLang.value = langCode;
    await _storage.setLocaleCode(langCode);
    await Get.updateLocale(Locale(langCode));
  }

  Future<void> toggleLocale() async {
    final next = isArabic ? 'en' : 'ar';
    await changeLocale(next);
  }
}
