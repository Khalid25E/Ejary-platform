import 'dart:convert';
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
import '../controllers/contracts_controller.dart';

class ContractsPage extends GetView<ContractsController> {
  const ContractsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();

    return AppScaffold(
      title: 'contracts_title'.tr,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.contractCreate),
        icon: const Icon(Icons.note_add_outlined),
        label: Text('create_contract'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('all', 'all'.tr),
                    const SizedBox(width: 8),
                    _chip('active', 'contract_status_active'.tr),
                    const SizedBox(width: 8),
                    _chip('expiring', 'contract_status_expiring'.tr),
                    const SizedBox(width: 8),
                    _chip('expired', 'contract_status_expired'.tr),
                    const SizedBox(width: 8),
                    _chip('terminated', 'contract_status_terminated'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: controller.obx(
                (contracts) => Obx(() {
                  final currency = storage.rxCurrency.value;
                  return ListView.separated(
                    itemCount: contracts!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cnt = contracts[index];
                      final tenant = Phase1MockData.getTenant(cnt.tenantId);
                      final apt = Phase1MockData.getApartment(cnt.apartmentId);
                      final prop =
                          Phase1MockData.getProperty(apt?.propertyId ?? 0);

                      return Card(
                        child: ListTile(
                          onTap: () => Get.toNamed(
                            AppRoutes.contractDetails,
                            arguments: cnt.id,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                _statusColor(cnt.status).withValues(alpha: 0.14),
                            child: Icon(
                              Icons.description_outlined,
                              color: _statusColor(cnt.status),
                            ),
                          ),
                          title: Text(
                            '${cnt.contractNumber} • ${tenant?.fullName ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${prop?.name ?? ''} (${apt?.apartmentNumber ?? ''}) | ${cnt.startedAt} → ${cnt.endAt}\n${'total_monthly_rent'.tr}: ${CurrencyUtils.formatAmount(cnt.monthlyTotal, currency: currency)}',
                          ),
                          isThreeLine: true,
                          trailing: StatusBadge(
                            label: _statusLabel(cnt.status),
                            color: _statusColor(cnt.status),
                          ),
                        ),
                      );
                    },
                  );
                }),
                onLoading: const AppLoading(),
                onEmpty: AppEmptyState(
                  onAction: () => Get.toNamed(AppRoutes.contractCreate),
                  actionLabel: 'create_contract'.tr,
                ),
                onError: (err) => AppErrorState(
                  message: err,
                  onRetry: controller.loadContracts,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.statusFilter.value == key,
      onSelected: (_) => controller.statusFilter.value = key,
    );
  }

  static String _statusLabel(String st) {
    switch (st) {
      case 'active':
        return 'contract_status_active'.tr;
      case 'expiring':
        return 'contract_status_expiring'.tr;
      case 'terminated':
        return 'contract_status_terminated'.tr;
      default:
        return 'contract_status_expired'.tr;
    }
  }

  static Color _statusColor(String st) {
    switch (st) {
      case 'active':
        return AppTheme.successColor;
      case 'expiring':
        return AppTheme.warningColor;
      case 'terminated':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}

class ContractDetailsPage extends StatelessWidget {
  const ContractDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final contracts = Phase1MockData.contracts;
    if (contracts.isEmpty) {
      return AppScaffold(
        title: 'contract_details'.tr,
        body: const AppEmptyState(),
      );
    }

    final int cntId =
        Get.arguments is int ? Get.arguments as int : contracts.first.id;
    final cnt = Phase1MockData.getContract(cntId) ?? contracts.first;
    final tenant = Phase1MockData.getTenant(cnt.tenantId);
    final apt = Phase1MockData.getApartment(cnt.apartmentId);
    final prop = Phase1MockData.getProperty(apt?.propertyId ?? 0);

    final cntServices = Phase1MockData.contractServices
        .where((s) => s.contractId == cnt.id)
        .toList();
    final cntInvoices = Phase1MockData.invoices
        .where((i) => i.contractId == cnt.id)
        .toList();

    List<String> conditions = [];
    try {
      final decoded = jsonDecode(cnt.conditionsJson);
      if (decoded is List) {
        conditions = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      conditions = [cnt.conditionsJson];
    }

    return AppScaffold(
      title: '${'contract_details'.tr}: ${cnt.contractNumber}',
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
                              cnt.contractNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: ContractsPage._statusLabel(cnt.status),
                            color: ContractsPage._statusColor(cnt.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(cnt.notes),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed(
                              AppRoutes.contractRenew,
                              arguments: cnt.id,
                            ),
                            icon: const Icon(Icons.autorenew, size: 18),
                            label: Text('renew_contract'.tr),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                            ),
                            onPressed: () => Get.toNamed(
                              AppRoutes.contractTerminate,
                              arguments: cnt.id,
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: Text('terminate_contract'.tr),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _kv('property_name'.tr, prop?.name ?? '-'),
                          _kv(
                            'apartment_number'.tr,
                            apt?.apartmentNumber ?? '-',
                          ),
                          _kv('tenant_full_name'.tr, tenant?.fullName ?? '-'),
                          _kv('created_at'.tr, cnt.createdAt),
                          _kv('start_date'.tr, cnt.startedAt),
                          _kv('end_date'.tr, cnt.endAt),
                          _kv('rental_date'.tr, cnt.rentalAt),
                          _kv('due_day'.tr, '${cnt.dueDay}'),
                          _kv('due_date'.tr, cnt.dueDate),
                          _kv(
                            'base_rent'.tr,
                            CurrencyUtils.formatAmount(
                              cnt.price,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'services_total'.tr,
                            CurrencyUtils.formatAmount(
                              cnt.totalServices,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'total_monthly_rent'.tr,
                            CurrencyUtils.formatAmount(
                              cnt.monthlyTotal,
                              currency: currency,
                            ),
                          ),
                          _kv(
                            'auto_renew'.tr,
                            cnt.autoRenew ? 'ON' : 'OFF',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // FR-09: Historical Contract Services Snapshot (contract_services)
              Text(
                '${'custom_services'.tr} (contract_services Snapshot)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'contract_services_snapshot_note'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final cs in cntServices)
                      ListTile(
                        leading: const Icon(Icons.history_edu_outlined),
                        title: Text(
                          cs.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          cs.billingType == 'fixed_monthly'
                              ? 'billing_fixed_monthly'.tr
                              : 'billing_usage_based'.tr,
                        ),
                        trailing: Text(
                          CurrencyUtils.formatAmount(
                            cs.price,
                            currency: currency,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Contract Conditions JSON
              Text(
                'contract_conditions'.tr,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < conditions.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${i + 1}. ${conditions[i]}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Linked Invoices
              Text(
                '${'invoices_title'.tr} (${cntInvoices.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final inv in cntInvoices)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => Get.toNamed(
                      AppRoutes.invoiceDetails,
                      arguments: inv.id,
                    ),
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(
                      '${'billing_month'.tr}: ${inv.billingMonth}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${'total_amount'.tr}: ${CurrencyUtils.formatAmount(inv.totalAmount, currency: currency)} • ${'remaining_amount'.tr}: ${CurrencyUtils.formatAmount(inv.remainingAmount, currency: currency)}',
                    ),
                    trailing: StatusBadge(
                      label: inv.status,
                      color: inv.status == 'Paid'
                          ? AppTheme.successColor
                          : inv.status == 'Overdue'
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
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

/// FR-08: Renew Contract Screen (تجديد العقد)
class ContractRenewPage extends StatefulWidget {
  const ContractRenewPage({super.key});

  @override
  State<ContractRenewPage> createState() => _ContractRenewPageState();
}

class _ContractRenewPageState extends State<ContractRenewPage> {
  late int contractId;
  final TextEditingController newStartCtrl =
      TextEditingController(text: '2026-12-01');
  final TextEditingController newEndCtrl =
      TextEditingController(text: '2027-11-30');
  final TextEditingController newRentCtrl = TextEditingController();
  final TextEditingController newServicesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final contracts = Phase1MockData.contracts;
    contractId = Get.arguments is int
        ? Get.arguments as int
        : (contracts.isNotEmpty ? contracts.first.id : 0);
    final old = Phase1MockData.getContract(contractId) ??
        (contracts.isNotEmpty ? contracts.first : null);
    newRentCtrl.text = (old?.price ?? 2500).toString();
    newServicesCtrl.text = (old?.totalServices ?? 200).toString();
  }

  @override
  void dispose() {
    newStartCtrl.dispose();
    newEndCtrl.dispose();
    newRentCtrl.dispose();
    newServicesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contracts = Phase1MockData.contracts;
    if (contracts.isEmpty) {
      return AppScaffold(
        title: 'renew_contract'.tr,
        body: const AppEmptyState(),
      );
    }
    final old = Phase1MockData.getContract(contractId) ?? contracts.first;
    final tenant = Phase1MockData.getTenant(old.tenantId);
    final apt = Phase1MockData.getApartment(old.apartmentId);

    return AppScaffold(
      title: '${'renew_contract'.tr}: ${old.contractNumber}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text(
                        '${'previous_contract'.tr}: ${old.contractNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${tenant?.fullName ?? ''} • ${apt?.apartmentNumber ?? ''} (${old.startedAt} → ${old.endAt})',
                      ),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: newStartCtrl,
                      decoration: InputDecoration(
                        labelText: 'start_date'.tr,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newEndCtrl,
                      decoration: InputDecoration(
                        labelText: 'end_date'.tr,
                        prefixIcon: const Icon(Icons.event_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newRentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'base_rent'.tr,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newServicesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'services_total'.tr,
                        prefixIcon:
                            const Icon(Icons.miscellaneous_services_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await Get.find<ContractsController>()
                              .executeContractRenewal(
                            oldContractId: old.id,
                            newStartDate: newStartCtrl.text.trim(),
                            newEndDate: newEndCtrl.text.trim(),
                            newBaseRent:
                                num.tryParse(newRentCtrl.text.trim()) ??
                                    old.price,
                            newServicesTotal:
                                num.tryParse(newServicesCtrl.text.trim()) ??
                                    old.totalServices,
                          );
                          Get.back();
                        } catch (e) {
                          Get.snackbar(
                            'renew_contract'.tr,
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      icon: const Icon(Icons.autorenew),
                      label: Text('renew_contract'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FR-08: Terminate Contract Screen (إنهاء العقد)
class ContractTerminatePage extends StatefulWidget {
  const ContractTerminatePage({super.key});

  @override
  State<ContractTerminatePage> createState() => _ContractTerminatePageState();
}

class _ContractTerminatePageState extends State<ContractTerminatePage> {
  late int contractId;
  final TextEditingController termDateCtrl =
      TextEditingController(text: '2026-11-20');
  final TextEditingController reasonCtrl = TextEditingController();
  String nextApartmentStatus = 'vacant';

  @override
  void initState() {
    super.initState();
    final contracts = Phase1MockData.contracts;
    contractId = Get.arguments is int
        ? Get.arguments as int
        : (contracts.isNotEmpty ? contracts.first.id : 0);
  }

  @override
  void dispose() {
    termDateCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final contracts = Phase1MockData.contracts;
    if (contracts.isEmpty) {
      return AppScaffold(
        title: 'terminate_contract'.tr,
        body: const AppEmptyState(),
      );
    }
    final cnt = Phase1MockData.getContract(contractId) ?? contracts.first;
    final unpaidInvoices = Phase1MockData.invoices
        .where((i) => i.contractId == cnt.id && i.remainingAmount > 0)
        .toList();
    final remainingSum = unpaidInvoices.fold<num>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );

    return AppScaffold(
      title: '${'terminate_contract'.tr}: ${cnt.contractNumber}',
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'unpaid_invoices_warning'.tr}: ${unpaidInvoices.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${'remaining_balance'.tr}: ${CurrencyUtils.formatAmount(remainingSum, currency: currency)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: termDateCtrl,
                        decoration: InputDecoration(
                          labelText: 'termination_date'.tr,
                          prefixIcon: const Icon(Icons.event_busy_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'termination_reason'.tr,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: nextApartmentStatus,
                        decoration: InputDecoration(
                          labelText: 'apartment_status_after_termination'.tr,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'vacant',
                            child: Text('apt_status_vacant'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('apt_status_maintenance'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'unavailable',
                            child: Text('apt_status_unavailable'.tr),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => nextApartmentStatus = v);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        onPressed: () async {
                          await Get.find<ContractsController>()
                              .executeContractTermination(
                            contractId: cnt.id,
                            terminationDate: termDateCtrl.text.trim(),
                            terminationReason: reasonCtrl.text.trim(),
                            nextApartmentStatus: nextApartmentStatus,
                          );
                          Get.back();
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text('terminate_contract'.tr),
                      ),
                    ],
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
