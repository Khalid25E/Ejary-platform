import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/database_lookup_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../invoices/presentation/controllers/invoices_controller.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/manage_payments_usecase.dart';

class PaymentsController extends GetxController
    with StateMixin<List<PaymentEntity>> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxInt selectedInvoiceId = 1003.obs;
  final RxString paymentType = 'full'.obs;
  final RxString paymentMethod = 'bank'.obs;
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController payDateCtrl =
      TextEditingController(text: '2026-11-20');
  final TextEditingController payRefCtrl =
      TextEditingController(text: 'TRX-2026-1120');
  final TextEditingController notesCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadPayments();
    syncAmountWithInvoice();
  }

  Future<void> loadPayments({bool syncFromDb = false}) async {
    try {
      if (syncFromDb && Get.isRegistered<DatabaseLookupService>()) {
        await Get.find<DatabaseLookupService>().refreshAll();
      }
      final list = Phase1MockData.payments;
      if (list.isEmpty) {
        change([], status: RxStatus.empty());
      } else {
        change(list, status: RxStatus.success());
      }
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }

  void selectInvoice(int invId) {
    selectedInvoiceId.value = invId;
    syncAmountWithInvoice();
  }

  void syncAmountWithInvoice() {
    final inv = Phase1MockData.getInvoice(selectedInvoiceId.value);
    if (inv != null) {
      amountCtrl.text = inv.remainingAmount.toString();
    } else {
      final firstUnpaid = Phase1MockData.invoices
          .where((i) => i.remainingAmount > 0)
          .firstOrNull;
      if (firstUnpaid != null) {
        selectedInvoiceId.value = firstUnpaid.id;
        amountCtrl.text = firstUnpaid.remainingAmount.toString();
      }
    }
  }

  Future<int?> recordNewPayment() async {
    if (!Get.isRegistered<ManagePaymentsUseCase>()) return null;
    final inv = Phase1MockData.getInvoice(selectedInvoiceId.value);
    if (inv == null) return null;

    final nowIso = AppDateUtils.toIsoDate(DateTime.now());
    final payment = PaymentEntity(
      id: 0,
      contractId: inv.contractId,
      invoiceId: inv.id,
      type: paymentType.value,
      payAt: payDateCtrl.text.trim(),
      amount: num.tryParse(amountCtrl.text.trim()) ?? 0,
      payMethod: paymentMethod.value,
      payRef: payRefCtrl.text.trim(),
      billingMonth: inv.billingMonth,
      notes: notesCtrl.text.trim(),
      createdAt: nowIso,
    );

    final newPaymentId =
        await Get.find<ManagePaymentsUseCase>().recordPayment(payment);
    await _refreshAllAfterPaymentChange();
    return newPaymentId;
  }

  Future<void> cancelExistingPayment(int paymentId) async {
    if (!Get.isRegistered<ManagePaymentsUseCase>()) return;
    await Get.find<ManagePaymentsUseCase>().cancelPayment(paymentId);
    await _refreshAllAfterPaymentChange();
  }

  Future<void> _refreshAllAfterPaymentChange() async {
    await loadPayments(syncFromDb: true);
    if (Get.isRegistered<InvoicesController>()) {
      await Get.find<InvoicesController>().loadInvoices();
    }
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboardData();
    }
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    payDateCtrl.dispose();
    payRefCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
