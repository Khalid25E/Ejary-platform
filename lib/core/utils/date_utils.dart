import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatIsoDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  static String toIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String toBillingMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static int daysRemaining(String endIsoDate) {
    final end = DateTime.tryParse(endIsoDate);
    if (end == null) return 0;
    final now = DateTime(2026, 11, 20);
    return end.difference(now).inDays;
  }
}
