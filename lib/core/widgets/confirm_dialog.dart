import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool> show({
    required String title,
    required String message,
    String? confirmText,
    Color? confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            onPressed: () => Get.back(result: true),
            child: Text(confirmText ?? 'confirm'.tr),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Explicit notice required by Phase 1 rules:
  /// "لا تجعل الأزرار التي يفترض أن تحفظ بيانات تعطي انطباعاً بأن البيانات حُفظت فعلياً.
  /// وضّح العمليات التي لم يتم ربطها بعد بقاعدة البيانات."
  static void showPhase1NotConnectedNotice({String? customOperation}) {
    Get.dialog(
      AlertDialog(
        icon: const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 40),
        title: Text(
          'phase1_action_notice_title'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customOperation != null) ...[
              Text(
                customOperation,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            Text('phase1_action_notice_body'.tr),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }
}
