import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/mock/mock_data.dart';
import '../app_routes.dart';

/// Verifies ID validity and entity existence before navigating to detail pages
/// as required by Section 11:
/// - صحة المعرفات
/// - وجود العقار قبل عرض تفاصيله
/// - وجود الشقة
/// - وجود العقد
/// - وجود الفاتورة
class EntityGuardMiddleware extends GetMiddleware {
  final String entityType; // property, apartment, tenant, contract, invoice

  EntityGuardMiddleware({required this.entityType});

  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final args = Get.arguments;
    int? id;
    if (args is int) {
      id = args;
    } else if (args is Map && args['id'] is int) {
      id = args['id'] as int;
    } else {
      final paramId = Get.parameters['id'];
      if (paramId != null) {
        id = int.tryParse(paramId);
      }
    }

    // If no explicit ID is passed, allow the detail screen to fall back to the first record
    // for direct preview navigation, but block invalid negative/zero IDs or nonexistent IDs.
    if (id != null) {
      if (id <= 0) {
        return _fallbackRoute();
      }
      final exists = _checkExists(id);
      if (!exists) {
        return _fallbackRoute();
      }
    }
    return null;
  }

  bool _checkExists(int id) {
    switch (entityType) {
      case 'property':
        return Phase1MockData.getProperty(id) != null;
      case 'apartment':
        return Phase1MockData.getApartment(id) != null;
      case 'tenant':
        return Phase1MockData.getTenant(id) != null;
      case 'contract':
        return Phase1MockData.getContract(id) != null;
      case 'invoice':
        return Phase1MockData.getInvoice(id) != null;
      default:
        return true;
    }
  }

  RouteSettings _fallbackRoute() {
    switch (entityType) {
      case 'property':
        return const RouteSettings(name: AppRoutes.properties);
      case 'apartment':
        return const RouteSettings(name: AppRoutes.apartments);
      case 'tenant':
        return const RouteSettings(name: AppRoutes.tenants);
      case 'contract':
        return const RouteSettings(name: AppRoutes.contracts);
      case 'invoice':
        return const RouteSettings(name: AppRoutes.invoices);
      default:
        return const RouteSettings(name: AppRoutes.dashboard);
    }
  }
}
