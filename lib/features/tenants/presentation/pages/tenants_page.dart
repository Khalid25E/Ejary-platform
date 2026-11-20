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
import '../../../../core/widgets/status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/tenant_entity.dart';
import '../controllers/tenants_controller.dart';

class TenantsPage extends StatelessWidget {
  const TenantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'tenants_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.tenantForm),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text('add_tenant'.tr),
      ),
      body: const TenantsListView(isEmbedded: false),
    );
  }
}

class TenantsListView extends GetView<TenantsController> {
  final bool isEmbedded;

  const TenantsListView({super.key, required this.isEmbedded});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => controller.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText:
                        '${'search'.tr} (${'tenant_full_name'.tr} / ${'tenant_phone'.tr} / ${'tenant_national_id'.tr})',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              if (isEmbedded) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.tenantForm),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text('add_tenant'.tr),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: controller.obx(
              (tenants) => Obx(() {
                final currency = storage.rxCurrency.value;
                return ListView.separated(
                  itemCount: tenants!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    final tContracts = Phase1MockData.contracts
                        .where((c) => c.tenantId == tenant.id)
                        .toList();
                    final contractIds = tContracts.map((c) => c.id).toSet();
                    final tInvoices = Phase1MockData.invoices
                        .where((i) => contractIds.contains(i.contractId))
                        .toList();
                    final remaining = tInvoices.fold<num>(
                      0,
                      (sum, i) => sum + i.remainingAmount,
                    );

                    return Card(
                      child: ListTile(
                        onTap: () => Get.toNamed(
                          AppRoutes.tenantDetails,
                          arguments: tenant.id,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          tenant.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tenant.phone} • ${'tenant_national_id'.tr}: ${tenant.nationalId}',
                            ),
                            const SizedBox(height: 6),
                            StatusBadge(
                              label: remaining > 0
                                  ? '${'remaining_balance'.tr}: ${CurrencyUtils.formatAmount(remaining, currency: currency)}'
                                  : 'inv_status_paid'.tr,
                              color: remaining > 0
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              onLoading: const AppLoading(),
              onEmpty: AppEmptyState(
                icon: Icons.people_outline,
                onAction: () => Get.toNamed(AppRoutes.tenantForm),
                actionLabel: 'add_tenant'.tr,
              ),
              onError: (err) =>
                  AppErrorState(message: err, onRetry: controller.loadTenants),
            ),
          ),
        ],
      ),
    );
  }
}

class TenantFormPage extends GetView<TenantsController> {
  const TenantFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TenantEntity? editingTenant = Get.arguments is TenantEntity
        ? Get.arguments as TenantEntity
        : null;
    controller.prepareForm(tenant: editingTenant);

    return AppScaffold(
      title: editingTenant == null ? 'add_tenant'.tr : 'edit_tenant'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: controller.fullNameCtrl,
                        validator: AppValidators.requiredField,
                        decoration: InputDecoration(
                          labelText: 'tenant_full_name'.tr,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller.phoneCtrl,
                        validator: AppValidators.phoneValidator,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'tenant_phone'.tr,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller.nationalIdCtrl,
                        validator: AppValidators.requiredField,
                        decoration: InputDecoration(
                          labelText: 'tenant_national_id'.tr,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller.notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'notes'.tr),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (controller.formKey.currentState?.validate() ??
                              false) {
                            await controller.saveTenant(
                              existing: editingTenant,
                            );
                            Get.back();
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text('save'.tr),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TenantDetailsPage extends StatelessWidget {
  const TenantDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final tenants = Phase1MockData.tenants;
    if (tenants.isEmpty) {
      return AppScaffold(
        title: 'tenant_details'.tr,
        body: const AppEmptyState(),
      );
    }

    final int tenantId = Get.arguments is int
        ? Get.arguments as int
        : tenants.first.id;
    final tenant = Phase1MockData.getTenant(tenantId) ?? tenants.first;

    final tContracts = Phase1MockData.contracts
        .where((c) => c.tenantId == tenant.id)
        .toList();
    final contractIds = tContracts.map((c) => c.id).toSet();
    final tInvoices = Phase1MockData.invoices
        .where((i) => contractIds.contains(i.contractId))
        .toList();

    final totalBilled = tInvoices.fold<num>(0, (sum, i) => sum + i.totalAmount);
    final totalPaid = tInvoices.fold<num>(0, (sum, i) => sum + i.paidAmount);
    final totalRemaining = tInvoices.fold<num>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );

    return AppScaffold(
      title: '${'tenant_details'.tr}: ${tenant.fullName}',
      actions: [
        IconButton(
          tooltip: 'edit_tenant'.tr,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Get.toNamed(AppRoutes.tenantForm, arguments: tenant),
        ),
      ],
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tenant.phone} • ${'tenant_national_id'.tr}: ${tenant.nationalId}',
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Get.toNamed(
                              AppRoutes.tenantStatement,
                              arguments: tenant.id,
                            ),
                            icon: const Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            label: Text('tenant_statement'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(tenant.notes),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          _finItem(
                            'total_billed'.tr,
                            CurrencyUtils.formatAmount(
                              totalBilled,
                              currency: currency,
                            ),
                            AppTheme.primaryColor,
                          ),
                          _finItem(
                            'total_paid'.tr,
                            CurrencyUtils.formatAmount(
                              totalPaid,
                              currency: currency,
                            ),
                            AppTheme.successColor,
                          ),
                          _finItem(
                            'remaining_balance'.tr,
                            CurrencyUtils.formatAmount(
                              totalRemaining,
                              currency: currency,
                            ),
                            totalRemaining > 0
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'tenant_contracts'.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final cnt in tContracts)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => Get.toNamed(
                      AppRoutes.contractDetails,
                      arguments: cnt.id,
                    ),
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      '${cnt.contractNumber} • ${Phase1MockData.getApartment(cnt.apartmentId)?.apartmentNumber ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${cnt.startedAt} → ${cnt.endAt}'),
                    trailing: StatusBadge(
                      label: cnt.status,
                      color: cnt.status == 'active'
                          ? AppTheme.successColor
                          : cnt.status == 'expiring'
                          ? AppTheme.warningColor
                          : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _finItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// FR-14: Tenant Statement of Account Page (كشف حساب المستأجر)
class TenantStatementPage extends StatelessWidget {
  const TenantStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final tenants = Phase1MockData.tenants;
    if (tenants.isEmpty) {
      return AppScaffold(
        title: 'tenant_statement'.tr,
        body: const AppEmptyState(),
      );
    }

    final int tenantId = Get.arguments is int
        ? Get.arguments as int
        : tenants.first.id;
    final tenant = Phase1MockData.getTenant(tenantId) ?? tenants.first;

    final tContracts = Phase1MockData.contracts
        .where((c) => c.tenantId == tenant.id)
        .toList();
    final contractIds = tContracts.map((c) => c.id).toSet();
    final tInvoices = Phase1MockData.invoices
        .where((i) => contractIds.contains(i.contractId))
        .toList();
    final tPayments = Phase1MockData.payments
        .where((p) => contractIds.contains(p.contractId))
        .toList();

    final totalBilled = tInvoices.fold<num>(0, (sum, i) => sum + i.totalAmount);
    final totalPaid = tPayments
        .where((p) => !p.isCancelled)
        .fold<num>(0, (sum, p) => sum + p.amount);
    final remaining = totalBilled - totalPaid;

    // Build chronological ledger entries
    final List<Map<String, dynamic>> ledger = [
      for (final inv in tInvoices)
        {
          'date': inv.createdAt,
          'type': 'INVOICE',
          'title': '${'invoices_title'.tr} (${inv.billingMonth})',
          'amount': inv.totalAmount,
          'status': inv.status,
          'isDebit': true,
        },
      for (final pay in tPayments)
        {
          'date': pay.payAt,
          'type': 'PAYMENT',
          'title':
              '${'record_payment'.tr} (${pay.payRef}) ${pay.isCancelled ? '[${'payment_cancelled'.tr}]' : ''}',
          'amount': pay.amount,
          'status': pay.payMethod,
          'isDebit': false,
          'isCancelled': pay.isCancelled,
        },
    ]..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return AppScaffold(
      title: '${'tenant_statement'.tr}: ${tenant.fullName}',
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _summaryCol(
                          'total_billed'.tr,
                          CurrencyUtils.formatAmount(
                            totalBilled,
                            currency: currency,
                          ),
                          AppTheme.primaryColor,
                        ),
                        _summaryCol(
                          'total_paid'.tr,
                          CurrencyUtils.formatAmount(
                            totalPaid,
                            currency: currency,
                          ),
                          AppTheme.successColor,
                        ),
                        _summaryCol(
                          'remaining_balance'.tr,
                          CurrencyUtils.formatAmount(
                            remaining,
                            currency: currency,
                          ),
                          remaining > 0
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'chronological_ledger'.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ledger.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = ledger[index];
                    final isDebit = entry['isDebit'] as bool;
                    final isCancelled =
                        (entry['isCancelled'] as bool?) ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDebit
                            ? AppTheme.warningColor.withValues(alpha: 0.14)
                            : AppTheme.successColor.withValues(alpha: 0.14),
                        child: Icon(
                          isDebit
                              ? Icons.receipt_long
                              : Icons.payments_outlined,
                          color: isDebit
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                      title: Text(
                        entry['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(entry['date'] as String),
                      trailing: Text(
                        '${isDebit ? '+' : '-'} ${CurrencyUtils.formatAmount(entry['amount'] as num, currency: currency)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isCancelled
                              ? Colors.grey
                              : isDebit
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
