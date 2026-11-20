import 'package:flutter/services.dart';

class AppFormatters {
  AppFormatters._();

  static List<TextInputFormatter> digitsOnly() => [
        FilteringTextInputFormatter.digitsOnly,
      ];

  static List<TextInputFormatter> decimalNumber() => [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ];
}
