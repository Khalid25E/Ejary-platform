import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../localization/locale_service.dart';
import '../storage/local_storage_service.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static bool get _isArabic {
    if (Get.isRegistered<LocaleService>()) {
      return Get.find<LocaleService>().isArabic;
    }
    return (Get.locale?.languageCode ?? 'ar') == 'ar';
  }

  static String resolveActiveCurrency([String? currency]) {
    if (currency != null && currency.trim().isNotEmpty) {
      return currency.trim();
    }
    if (Get.isRegistered<LocalStorageService>()) {
      return Get.find<LocalStorageService>().defaultCurrency;
    }
    return 'SAR';
  }

  /// Returns the localized symbol for display.
  /// For YER: 'ر.ي' in Arabic, 'YER' in English.
  static String displaySymbol(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'YER') {
      return _isArabic ? 'ر.ي' : 'YER';
    }
    return normalized;
  }

  /// Returns the full localized name and symbol for currency pickers.
  static String getCurrencyLabel(String code) {
    final normalized = code.trim().toUpperCase();
    switch (normalized) {
      case 'YER':
        return _isArabic
            ? 'الريال اليمني (ر.ي) — YER'
            : 'Yemeni Rial (YER)';
      case 'SAR':
        return _isArabic
            ? 'الريال السعودي — SAR'
            : 'Saudi Riyal (SAR)';
      case 'AED':
        return _isArabic
            ? 'الدرهم الإماراتي — AED'
            : 'UAE Dirham (AED)';
      case 'EGP':
        return _isArabic
            ? 'الجنيه المصري — EGP'
            : 'Egyptian Pound (EGP)';
      case 'USD':
        return _isArabic
            ? 'الدولار الأمريكي — USD'
            : 'US Dollar (USD)';
      case 'KWD':
        return _isArabic
            ? 'الدينار الكويتي — KWD'
            : 'Kuwaiti Dinar (KWD)';
      case 'QAR':
        return _isArabic
            ? 'الريال القطري — QAR'
            : 'Qatari Riyal (QAR)';
      case 'OMR':
        return _isArabic
            ? 'الريال العماني — OMR'
            : 'Omani Rial (OMR)';
      case 'JOD':
        return _isArabic
            ? 'الدينار الأردني — JOD'
            : 'Jordanian Dinar (JOD)';
      default:
        return normalized;
    }
  }

  static String formatAmount(num amount, {String? currency}) {
    final activeCode = resolveActiveCurrency(currency);
    final symbol = displaySymbol(activeCode);
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }
}
