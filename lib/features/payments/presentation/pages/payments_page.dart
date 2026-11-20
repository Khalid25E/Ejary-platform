import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../data/datasources/receipt_pdf_service.dart';
import '../controllers/payments_controller.dart';

class PaymentsPage extends GetView<PaymentsController> {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return AppScaffold(
      title: 'payments_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.paymentRecord),
        icon: const Icon(Icons.add_card_outlined),
        label: Text('record_payment'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: controller.obx(
          (payments) => Obx(() {
            final currency = storage.rxCurrency.value;
            return ListView.separated(
              itemCount: payments!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pay = payments[index];
                final cnt = Phase1MockData.getContract(pay.contractId);
                final tenant = Phase1MockData.getTenant(cnt?.tenantId ?? 0);

                return Card(
                  child: ListTile(
                    onTap: () => Get.toNamed(
                      AppRoutes.paymentReceipt,
                      arguments: pay.id,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          (pay.isCancelled
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor)
                              .withValues(alpha: 0.14),
                      child: Icon(
                        pay.isCancelled
                            ? Icons.money_off_csred_outlined
                            : Icons.payments_outlined,
                        color: pay.isCancelled
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                      ),
                    ),
                    title: Text(
                      '${CurrencyUtils.formatAmount(pay.amount, currency: currency)} • ${tenant?.fullName ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: pay.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${pay.billingMonth} | ${pay.payAt} | ${pay.payRef}\n${pay.notes}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!pay.isCancelled)
                          IconButton(
                            tooltip: 'cancel_payment'.tr,
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AppTheme.errorColor,
                            ),
                            onPressed: () async {
                              final ok = await ConfirmDialog.show(
                                title: 'cancel_payment'.tr,
                                message: '${'cancel_payment'.tr}: #${pay.id}?',
                                confirmColor: AppTheme.errorColor,
                              );
                              if (ok) {
                                await controller.cancelExistingPayment(pay.id);
                              }
                            },
                          ),
                        IconButton(
                          tooltip: 'payment_receipt'.tr,
                          icon: const Icon(Icons.receipt_long_outlined),
                          onPressed: () => Get.toNamed(
                            AppRoutes.paymentReceipt,
                            arguments: pay.id,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
          onLoading: const AppLoading(),
          onEmpty: const AppEmptyState(),
          onError: (err) =>
              AppErrorState(message: err, onRetry: controller.loadPayments),
        ),
      ),
    );
  }
}

/// FR-11: Record Full or Partial Payment Page
class RecordPaymentPage extends GetView<PaymentsController> {
  const RecordPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final argId = Get.arguments;
    if (argId is int) {
      controller.selectInvoice(argId);
    }

    final unpaidInvoices = Phase1MockData.invoices
        .where((i) => i.remainingAmount > 0)
        .toList();

    return AppScaffold(
      title: 'record_payment'.tr,
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        final validInvoiceId =
            unpaidInvoices.any(
              (i) => i.id == controller.selectedInvoiceId.value,
            )
            ? controller.selectedInvoiceId.value
            : (unpaidInvoices.isNotEmpty ? unpaidInvoices.first.id : null);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: validInvoiceId,
                          decoration: InputDecoration(
                            labelText: 'invoice_details'.tr,
                            prefixIcon: const Icon(Icons.receipt_long_outlined),
                          ),
                          items: unpaidInvoices.map((inv) {
                            final cnt = Phase1MockData.getContract(
                              inv.contractId,
                            );
                            final t = Phase1MockData.getTenant(
                              cnt?.tenantId ?? 0,
                            );
                            return DropdownMenuItem(
                              value: inv.id,
                              child: Text(
                                '#${inv.id} (${inv.billingMonth}) - ${t?.fullName ?? ''} [${CurrencyUtils.formatAmount(inv.remainingAmount, currency: currency)}]',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) controller.selectInvoice(v);
                          },
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text('payment_full'.tr),
                              selected: controller.paymentType.value == 'full',
                              onSelected: (_) {
                                controller.paymentType.value = 'full';
                                controller.syncAmountWithInvoice();
                              },
                            ),
                            ChoiceChip(
                              label: Text('payment_partial'.tr),
                              selected:
                                  controller.paymentType.value == 'partial',
                              onSelected: (_) {
                                controller.paymentType.value = 'partial';
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: controller.amountCtrl,
                          validator: AppValidators.positiveNumber,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'payment_amount'.tr,
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: controller.paymentMethod.value,
                          decoration: InputDecoration(
                            labelText: 'payment_method'.tr,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('method_cash'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text('method_bank'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'remittance',
                              child: Text('method_remittance'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('method_other'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) controller.paymentMethod.value = v;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.payDateCtrl,
                                validator: AppValidators.requiredField,
                                decoration: InputDecoration(
                                  labelText: 'payment_date'.tr,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: controller.payRefCtrl,
                                decoration: InputDecoration(
                                  labelText: 'payment_ref'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: controller.notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(labelText: 'notes'.tr),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (controller.formKey.currentState?.validate() ??
                                false) {
                              try {
                                final newPayId = await controller
                                    .recordNewPayment();
                                if (newPayId != null) {
                                  Get.offNamed(
                                    AppRoutes.paymentReceipt,
                                    arguments: newPayId,
                                  );
                                }
                              } catch (e) {
                                Get.snackbar(
                                  'record_payment'.tr,
                                  e.toString(),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('save'.tr),
                        ),
                        if (Phase1MockData.payments.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed(
                              AppRoutes.paymentReceipt,
                              arguments: Phase1MockData.payments.first.id,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text('payment_receipt'.tr),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// FR-13: Payment Receipt Preview Screen (معاينة إيصال الدفع)
class PaymentReceiptPage extends StatelessWidget {
  const PaymentReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final payments = Phase1MockData.payments;
    if (payments.isEmpty) {
      return AppScaffold(
        title: 'payment_receipt'.tr,
        body: const AppEmptyState(),
      );
    }

    final int payId = Get.arguments is int
        ? Get.arguments as int
        : payments.first.id;
    final pay =
        payments.where((p) => p.id == payId).firstOrNull ?? payments.first;
    final inv = Phase1MockData.getInvoice(pay.invoiceId);
    final cnt = Phase1MockData.getContract(pay.contractId);
    final tenant = Phase1MockData.getTenant(cnt?.tenantId ?? 0);
    final apt = Phase1MockData.getApartment(cnt?.apartmentId ?? 0);
    final prop = Phase1MockData.getProperty(apt?.propertyId ?? 0);

    return AppScaffold(
      title: 'payment_receipt'.tr,
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        final pdfData = ReceiptPdfData(
          paymentId: pay.id,
          receiptNumber: 'RCP-${pay.id}',
          ownerName: storage.rxOwnerName.value,
          ownerPhone: storage.rxOwnerPhone.value,
          tenantName: tenant?.fullName ?? '-',
          propertyName: prop?.name ?? '-',
          apartmentNumber: apt?.apartmentNumber ?? '-',
          contractNumber: cnt?.contractNumber ?? '-',
          billingMonth: pay.billingMonth,
          paymentDate: pay.payAt,
          paidAmount: pay.amount,
          invoiceTotalAmount: inv?.totalAmount ?? pay.amount,
          remainingAmount: inv?.remainingAmount ?? 0,
          paymentMethod: pay.payMethod,
          paymentRef: pay.payRef,
          notes: pay.notes,
          currency: currency,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ejary Header & Receipt Number
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.apartment,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ejary — منصة إيجاري',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        Text(
                                          'payment_receipt'.tr,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(
                                label: '${'receipt_number'.tr}: RCP-${pay.id}',
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          _receiptLine(
                            'owner_full_name'.tr,
                            storage.rxOwnerName.value,
                          ),
                          _receiptLine(
                            'owner_phone'.tr,
                            storage.rxOwnerPhone.value,
                          ),
                          const Divider(height: 24),
                          _receiptLine(
                            'tenant_full_name'.tr,
                            tenant?.fullName ?? '-',
                          ),
                          _receiptLine('property_name'.tr, prop?.name ?? '-'),
                          _receiptLine(
                            'apartment_number'.tr,
                            apt?.apartmentNumber ?? '-',
                          ),
                          _receiptLine(
                            'contract_number'.tr,
                            cnt?.contractNumber ?? '-',
                          ),
                          _receiptLine('billing_month'.tr, pay.billingMonth),
                          _receiptLine('payment_date'.tr, pay.payAt),
                          const Divider(height: 24),
                          _receiptLine(
                            'total_amount'.tr,
                            CurrencyUtils.formatAmount(
                              inv?.totalAmount ?? pay.amount,
                              currency: currency,
                            ),
                          ),
                          _receiptLine(
                            'payment_amount'.tr,
                            CurrencyUtils.formatAmount(
                              pay.amount,
                              currency: currency,
                            ),
                            highlight: true,
                          ),
                          _receiptLine(
                            'remaining_amount'.tr,
                            CurrencyUtils.formatAmount(
                              inv?.remainingAmount ?? 0,
                              currency: currency,
                            ),
                          ),
                          const Divider(height: 24),
                          _receiptLine('payment_method'.tr, pay.payMethod),
                          _receiptLine('payment_ref'.tr, pay.payRef),
                          _receiptLine('notes'.tr, pay.notes),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final pdfService =
                              Get.isRegistered<ReceiptPdfService>()
                              ? Get.find<ReceiptPdfService>()
                              : const ReceiptPdfService();
                          final file = await pdfService.exportReceiptPdfToFile(
                            pdfData,
                          );
                          Get.snackbar(
                            'export_pdf'.tr,
                            file.path,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text('export_pdf'.tr),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pdfService =
                              Get.isRegistered<ReceiptPdfService>()
                              ? Get.find<ReceiptPdfService>()
                              : const ReceiptPdfService();
                          await pdfService.shareReceiptPdf(pdfData);
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: Text('share_receipt'.tr),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pdfService =
                              Get.isRegistered<ReceiptPdfService>()
                              ? Get.find<ReceiptPdfService>()
                              : const ReceiptPdfService();
                          await pdfService.printReceiptPdf(pdfData);
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: Text('print_receipt'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _receiptLine(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
                fontSize: highlight ? 17 : 14,
                color: highlight ? AppTheme.successColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
