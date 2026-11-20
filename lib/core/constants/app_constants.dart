class AppConstants {
  AppConstants._();

  static const String appName = 'Ejary Platform';
  static const String appVersion = '1.0.0';

  // GetStorage keys
  static const String keyOwnerSetupDone = 'owner_setup_done';
  static const String keyOwnerName = 'owner_name';
  static const String keyOwnerPhone = 'owner_phone';
  static const String keyOwnerAvatar = 'owner_avatar';
  static const String keyCurrency = 'default_currency';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'app_locale';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  static const List<String> supportedCurrencies = [
    'SAR',
    'YER',
    'AED',
    'EGP',
    'USD',
    'KWD',
    'QAR',
    'OMR',
    'JOD',
  ];
}
