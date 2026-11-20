import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../storage/local_storage_service.dart';

class ThemeService extends GetxService {
  final LocalStorageService _storage = Get.find<LocalStorageService>();
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.themeMode == 'dark';
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await _storage.setThemeMode(isDarkMode.value ? 'dark' : 'light');
    Get.changeThemeMode(themeMode);
  }

  Future<void> setDarkMode(bool dark) async {
    isDarkMode.value = dark;
    await _storage.setThemeMode(dark ? 'dark' : 'light');
    Get.changeThemeMode(themeMode);
  }
}
