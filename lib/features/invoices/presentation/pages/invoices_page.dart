import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/invoices_controller.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'invoices_title'.tr,
      body: const InvoicesListView(isEmbedded: false),
    );
  }
}

class InvoicesListView extends GetView<InvoicesController> {
  final bool isEmbedded;

  const InvoicesListView({super.key, required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showGenerateMonthlyDialog(context),
                icon: const Icon(Icons.auto_mode_outlined),
                label: Text('generate_monthly_invoices'.tr),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.payments),
                icon: const Icon(Icons.history),
                label: Text('payments_title'.tr),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('all', 'all'.tr),
                  const SizedBox(width: 8),
                  _statusChip('Overdue', 'inv_status_overdue'.tr),
                  const SizedBox(width: 8),
                  _statusChip('Partially Paid', 'inv_status_partial'.tr),
                  const SizedBox(width: 8),
                  _statusChip('Pending', 'inv_status_pending'.tr),
                  const SizedBox(width: 8),
                  _statusChip('Paid', 'inv_status_paid'.tr),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: controller.obx(
              (invoices) => Obx(() {
                final currency = storage.rxCurrency.value;
                return ListView.separated(
                  itemCount: invoices!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final cnt = Phase1MockData.getContract(inv.contractId);
                    final tenant = Phase1MockData.getTenant(cnt?.tenantId ?? 0);
                    final apt = Phase1MockData.getApartment(
                      cnt?.apartmentId ?? 0,
                    );

                    return Card(
                      child: ListTile(
                        onTap: () => Get.toNamed(
                          AppRoutes.invoiceDetails,
                          arguments: inv.id,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(
                            inv.status,
                          ).withValues(alpha: 0.14),
                          child: Icon(
                            Icons.receipt_long,
                            color: _statusColor(inv.status),
                          ),
                        ),
                        title: Text(
                          '${inv.billingMonth} • ${tenant?.fullName ?? ''} (${apt?.apartmentNumber ?? ''})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${'due_date'.tr}: ${inv.dueDate}\n${'total_amount'.tr}: ${CurrencyUtils.formatAmount(inv.totalAmount, currency: currency)} | ${'remaining_amount'.tr}: ${CurrencyUtils.formatAmount(inv.remainingAmount, currency: currency)}',
                        ),
                        isThreeLine: true,
                        trailing: StatusBadge(
                          label: inv.status,
                          color: _statusColor(inv.status),
                        ),
                      ),
                    );
                  },
                );
              }),
              onLoading: const AppLoading(),
              onEmpty: const AppEmptyState(icon: Icons.receipt_long_outlined),
              onError: (err) =>
                  AppErrorState(message: err, onRetry: controller.loadInvoices),
            ),
          ),
        ],
      ),
    );
  }

  void _showGenerateMonthlyDialog(BuildContext context) {
    final monthCtrl = TextEditingController(text: '2026-11');
    Get.dialog(
      AlertDialog(
        title: Text('generate_monthly_invoices'.tr),
        content: TextField(
          controller: monthCtrl,
          decoration: InputDecoration(
            labelText: '${'billing_month'.tr} (YYYY-MM)',
            prefixIcon: const Icon(Icons.calendar_month_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              final targetMonth = monthCtrl.text.trim();
              Get.back();
              try {
                final createdCount = await controller
                    .generateMonthlyInvoicesForMonth(targetMonth);
                Get.snackbar(
                  'generate_monthly_invoices'.tr,
                  'Generated $createdCount new invoice(s) for $targetMonth',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'generate_monthly_invoices'.tr,
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.statusFilter.value == key,
      onSelected: (_) => controller.statusFilter.value = key,
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppTheme.successColor;
      case 'Overdue':
        return AppTheme.errorColor;
      case 'Partially Paid':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}

class InvoiceDetailsPage extends StatelessWidget {
  const InvoiceDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final invoices = Phase1MockData.invoices;
    if (invoices.isEmpty) {
      return AppScaffold(
        title: 'invoice_details'.tr,
        body: const AppEmptyState(),
      );
    }

    final int invId = Get.arguments is int
        ? Get.arguments as int
        : invoices.first.id;
    final inv = Phase1MockData.getInvoice(invId) ?? invoices.first;
    final cnt = Phase1MockData.getContract(inv.contractId);
    final tenant = Phase1MockData.getTenant(cnt?.tenantId ?? 0);
    final apt = Phase1MockData.getApartment(cnt?.apartmentId ?? 0);
    final prop = Phase1MockData.getProperty(apt?.propertyId ?? 0);
    final invPayments = Phase1MockData.payments
        .where((p) => p.invoiceId == inv.id)
        .toList();

    return AppScaffold(
      title: '${'invoice_details'.tr} #${inv.id}',
      floatingActionButton: inv.remainingAmount > 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Get.toNamed(AppRoutes.paymentRecord, arguments: inv.id),
              icon: const Icon(Icons.payments_outlined),
              label: Text('record_payment'.tr),
            )
          : null,
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${'billing_month'.tr}: ${inv.billingMonth}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: inv.status,
                            color: InvoicesListView._statusColor(inv.status),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _kv('tenant_full_name'.tr, tenant?.fullName ?? '-'),
                          _kv('property_name'.tr, prop?.name ?? '-'),
                          _kv(
                            'apartment_number'.tr,
                            apt?.apartmentNumber ?? '-',
                          ),
                          _kv('contract_number'.tr, cnt?.contractNumber ?? '-'),
                          _kv('due_date'.tr, inv.dueDate),
                          _kv(
                            'base_rent'.tr,
                            CurrencyUtils.formatAmount(
                              inv.baseRent,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'services_total'.tr,
                            CurrencyUtils.formatAmount(
                              inv.servicesTotal,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'total_amount'.tr,
                            CurrencyUtils.formatAmount(
                              inv.totalAmount,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'paid_amount'.tr,
                            CurrencyUtils.formatAmount(
                              inv.paidAmount,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'remaining_amount'.tr,
                            CurrencyUtils.formatAmount(
                              inv.remainingAmount,
                              currency: currency,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${'payments_title'.tr} (${invPayments.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final pay in invPayments)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => Get.toNamed(
                      AppRoutes.paymentReceipt,
                      arguments: pay.id,
                    ),
                    leading: Icon(
                      pay.isCancelled
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      color: pay.isCancelled
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                    title: Text(
                      '${CurrencyUtils.formatAmount(pay.amount, currency: currency)} • ${pay.payRef}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: pay.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text('${pay.payAt} — ${pay.notes}'),
                    trailing: IconButton(
                      tooltip: 'payment_receipt'.tr,
                      onPressed: () => Get.toNamed(
                        AppRoutes.paymentReceipt,
                        arguments: pay.id,
                      ),
                      icon: const Icon(Icons.receipt_outlined),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}
