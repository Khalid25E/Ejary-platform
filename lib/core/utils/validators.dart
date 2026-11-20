import 'package:get/get.dart';

class AppValidators {
  AppValidators._();

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'val_required'.tr;
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'val_required'.tr;
    }
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'val_positive_number'.tr;
    }
    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'val_required'.tr;
    }
    if (value.trim().length < 7) {
      return 'val_invalid_phone'.tr;
    }
    return null;
  }
}
