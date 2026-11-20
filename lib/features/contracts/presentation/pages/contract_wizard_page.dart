import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/contracts_controller.dart';

/// FR-08: 6-Step Contract Creation Wizard
class ContractWizardPage extends GetView<ContractsController> {
  const ContractWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<LocalStorageService>();
    final args = Get.arguments;
    if (args is Map && args['apartmentId'] is int) {
      controller.initWizardDefaults(
        preselectedApartmentId: args['apartmentId'] as int,
      );
    }

    return AppScaffold(
      title: 'create_contract'.tr,
      body: Obx(() {
        final currency = storage.rxCurrency.value;
        return GetBuilder<ContractsController>(
          id: 'wizard',
          builder: (ctrl) {
            final stepTitles = [
              'step_1_title'.tr,
              'step_2_title'.tr,
              'step_3_title'.tr,
              'step_4_title'.tr,
              'step_5_title'.tr,
              'step_6_title'.tr,
            ];

            return Column(
              children: [
                // Step Indicator Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(stepTitles.length, (i) {
                        final isActive = ctrl.currentWizardStep == i;
                        final isDone = ctrl.currentWizardStep > i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: isDone
                                ? const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppTheme.successColor,
                                  )
                                : null,
                            label: Text(stepTitles[i]),
                            selected: isActive,
                            onSelected: (_) => ctrl.setWizardStep(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildCurrentStepContent(
                              context,
                              ctrl,
                              currency,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Wizard Footer Navigation
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (ctrl.currentWizardStep > 0)
                        OutlinedButton.icon(
                          onPressed: () =>
                              ctrl.setWizardStep(ctrl.currentWizardStep - 1),
                          icon: const Icon(Icons.arrow_back),
                          label: Text('previous'.tr),
                        )
                      else
                        const SizedBox.shrink(),
                      if (ctrl.currentWizardStep < 5)
                        ElevatedButton.icon(
                          onPressed: () =>
                              ctrl.setWizardStep(ctrl.currentWizardStep + 1),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text('next'.tr),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                          ),
                          onPressed: () async {
                            try {
                              await ctrl.confirmWizardContractCreation();
                              Get.back();
                            } catch (e) {
                              Get.snackbar(
                                'create_contract'.tr,
                                e.toString(),
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('confirm'.tr),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildCurrentStepContent(
    BuildContext context,
    ContractsController ctrl,
    String currency,
  ) {
    switch (ctrl.currentWizardStep) {
      case 0:
        return _buildStep1PropertyAndApartment(context, ctrl, currency);
      case 1:
        return _buildStep2TenantSelection(context, ctrl);
      case 2:
        return _buildStep3ContractDatesAndRent(context, ctrl);
      case 3:
        return _buildStep4ContractServices(context, ctrl, currency);
      case 4:
        return _buildStep5ContractConditions(context, ctrl);
      case 5:
      default:
        return _buildStep6ReviewAndConfirm(context, ctrl, currency);
    }
  }

  // Step 1: Select Property & Vacant Apartment Only
  Widget _buildStep1PropertyAndApartment(
    BuildContext context,
    ContractsController ctrl,
    String currency,
  ) {
    final props = Phase1MockData.properties;
    final validPropId = props.any((p) => p.id == ctrl.selectedPropertyId)
        ? ctrl.selectedPropertyId
        : (props.isNotEmpty ? props.first.id : null);

    final vacantApts = ctrl.vacantApartmentsForSelectedProperty;
    final validAptId =
        vacantApts.any((a) => a.id == ctrl.selectedVacantApartmentId)
        ? ctrl.selectedVacantApartmentId
        : (vacantApts.isNotEmpty ? vacantApts.first.id : null);

    final selectedApt = validAptId != null
        ? Phase1MockData.getApartment(validAptId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_1_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'select_vacant_apartment_only'.tr,
          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: validPropId,
          decoration: InputDecoration(
            labelText: 'property_name'.tr,
            prefixIcon: const Icon(Icons.domain),
          ),
          items: props
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) ctrl.selectWizardProperty(v);
          },
        ),
        const SizedBox(height: 16),
        if (vacantApts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('no_data'.tr),
          )
        else
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: validAptId,
            decoration: InputDecoration(
              labelText: '${'apartment_number'.tr} (${'apt_status_vacant'.tr})',
              prefixIcon: const Icon(Icons.meeting_room_outlined),
            ),
            items: vacantApts
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      '${a.apartmentNumber} — ${'floor'.tr} ${a.floor} (${CurrencyUtils.formatAmount(a.baseRent, currency: currency)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) ctrl.selectWizardApartment(v);
            },
          ),
        if (selectedApt != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'apartment_details'.tr}: ${selectedApt.apartmentNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${'floor'.tr}: ${selectedApt.floor} | ${'rooms_count'.tr}: ${selectedApt.roomsCount} | ${'base_rent'.tr}: ${CurrencyUtils.formatAmount(selectedApt.baseRent, currency: currency)}',
                ),
                const SizedBox(height: 4),
                Text(selectedApt.notes),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Step 2: Select Existing Tenant or Inline-Add New Tenant
  Widget _buildStep2TenantSelection(
    BuildContext context,
    ContractsController ctrl,
  ) {
    final tenants = Phase1MockData.tenants;
    final validTenantId = tenants.any((t) => t.id == ctrl.selectedTenantId)
        ? ctrl.selectedTenantId
        : (tenants.isNotEmpty ? tenants.first.id : null);
    final selectedTenant = validTenantId != null
        ? Phase1MockData.getTenant(validTenantId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_2_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('select_existing_tenant'.tr),
              selected: !ctrl.isAddingNewTenantInline,
              onSelected: (_) => ctrl.toggleInlineNewTenant(false),
            ),
            ChoiceChip(
              label: Text('add_new_tenant_inline'.tr),
              selected: ctrl.isAddingNewTenantInline,
              onSelected: (_) => ctrl.toggleInlineNewTenant(true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!ctrl.isAddingNewTenantInline) ...[
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: validTenantId,
            decoration: InputDecoration(
              labelText: 'tenant_full_name'.tr,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            items: tenants
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      '${t.fullName} (${t.phone})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) ctrl.selectExistingTenant(v);
            },
          ),
          if (selectedTenant != null) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                selectedTenant.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${selectedTenant.phone} • ${'tenant_national_id'.tr}: ${selectedTenant.nationalId}\n${selectedTenant.notes}',
              ),
            ),
          ],
        ] else ...[
          TextField(
            controller: ctrl.inlineTenantNameCtrl,
            decoration: InputDecoration(
              labelText: 'tenant_full_name'.tr,
              prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl.inlineTenantPhoneCtrl,
            decoration: InputDecoration(
              labelText: 'tenant_phone'.tr,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl.inlineTenantNationalIdCtrl,
            decoration: InputDecoration(
              labelText: 'tenant_national_id'.tr,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
        ],
      ],
    );
  }

  // Step 3: Contract Dates, Due Day, Base Rent, Auto-Renew
  Widget _buildStep3ContractDatesAndRent(
    BuildContext context,
    ContractsController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_3_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl.startDateCtrl,
                decoration: InputDecoration(
                  labelText: 'start_date'.tr,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ctrl.endDateCtrl,
                decoration: InputDecoration(
                  labelText: 'end_date'.tr,
                  prefixIcon: const Icon(Icons.event_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl.rentalDateCtrl,
                decoration: InputDecoration(
                  labelText: 'rental_date'.tr,
                  prefixIcon: const Icon(Icons.key_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ctrl.dueDayCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${'due_day'.tr} (1-28)',
                  prefixIcon: const Icon(Icons.today_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: ctrl.baseRentCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => ctrl.refreshWizardTotals(),
          decoration: InputDecoration(
            labelText: 'base_rent'.tr,
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'auto_renew'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('auto_renew_note'.tr),
          value: ctrl.autoRenew,
          onChanged: ctrl.toggleAutoRenew,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl.notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(labelText: 'notes'.tr),
        ),
      ],
    );
  }

  // Step 4: Contract Services Snapshot
  Widget _buildStep4ContractServices(
    BuildContext context,
    ContractsController ctrl,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_4_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'contract_services_snapshot_note'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        for (final srv in Phase1MockData.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Checkbox(
                  value: ctrl.selectedServices[srv.id] ?? false,
                  onChanged: (v) =>
                      ctrl.toggleWizardService(srv.id, v ?? false),
                ),
                Expanded(
                  child: Text(
                    srv.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: ctrl.servicePriceCtrls[srv.id],
                    enabled: ctrl.selectedServices[srv.id] ?? false,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => ctrl.refreshWizardTotals(),
                    decoration: InputDecoration(labelText: 'custom_price'.tr),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'services_total'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              CurrencyUtils.formatAmount(
                ctrl.wizardServicesTotal,
                currency: currency,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: Contract Conditions JSON
  Widget _buildStep5ContractConditions(
    BuildContext context,
    ContractsController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_5_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            TextField(
              controller: ctrl.newConditionCtrl,
              decoration: InputDecoration(labelText: 'add_condition'.tr),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.addCondition,
                icon: const Icon(Icons.add),
                label: Text('add_condition'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < ctrl.conditionsList.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
            title: Text(ctrl.conditionsList[i]),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              onPressed: () => ctrl.removeCondition(i),
            ),
          ),
      ],
    );
  }

  // Step 6: Full Final Review & Atomic Confirmation
  Widget _buildStep6ReviewAndConfirm(
    BuildContext context,
    ContractsController ctrl,
    String currency,
  ) {
    final prop = Phase1MockData.getProperty(ctrl.selectedPropertyId);
    final apt = ctrl.selectedVacantApartmentId != null
        ? Phase1MockData.getApartment(ctrl.selectedVacantApartmentId!)
        : null;
    final tenantName = ctrl.isAddingNewTenantInline
        ? ctrl.inlineTenantNameCtrl.text
        : (Phase1MockData.getTenant(ctrl.selectedTenantId)?.fullName ?? '-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'step_6_title'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'atomic_save_note'.tr,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        _reviewRow('property_name'.tr, prop?.name ?? '-'),
        _reviewRow('apartment_number'.tr, apt?.apartmentNumber ?? '-'),
        _reviewRow('tenant_full_name'.tr, tenantName),
        _reviewRow('start_date'.tr, ctrl.startDateCtrl.text),
        _reviewRow('end_date'.tr, ctrl.endDateCtrl.text),
        _reviewRow('rental_date'.tr, ctrl.rentalDateCtrl.text),
        _reviewRow('due_day'.tr, ctrl.dueDayCtrl.text),
        _reviewRow(
          'base_rent'.tr,
          CurrencyUtils.formatAmount(ctrl.wizardBaseRent, currency: currency),
        ),
        _reviewRow(
          'services_total'.tr,
          CurrencyUtils.formatAmount(
            ctrl.wizardServicesTotal,
            currency: currency,
          ),
        ),
        const Divider(height: 20),
        _reviewRow(
          'total_monthly_rent'.tr,
          CurrencyUtils.formatAmount(
            ctrl.wizardMonthlyTotal,
            currency: currency,
          ),
          isBold: true,
        ),
        const Divider(height: 20),
        Text(
          '${'contract_conditions'.tr} (${ctrl.conditionsList.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final c in ctrl.conditionsList) Text('• $c'),
      ],
    );
  }

  Widget _reviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                fontSize: isBold ? 17 : 14,
                color: isBold ? AppTheme.primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
