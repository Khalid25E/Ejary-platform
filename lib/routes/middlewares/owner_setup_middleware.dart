import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/storage/local_storage_service.dart';
import '../app_routes.dart';

/// Verifies whether first-time Property Owner Setup has been completed.
/// Note: There are NO user accounts or login screens per Section 2 & 11.
class OwnerSetupMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final storage = Get.find<LocalStorageService>();
    if (!storage.isOwnerSetupDone && route != AppRoutes.onboarding) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }
    return null;
  }
}
