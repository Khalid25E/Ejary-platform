import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/summary_stat_card.dart';
import '../../../../routes/app_routes.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../properties/presentation/pages/properties_page.dart';
import '../../../settings/presentation/pages/more_menu_page.dart';
import '../../../tenants/presentation/pages/tenants_page.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../controllers/dashboard_controller.dart';

class DashboardShellPage extends GetView<DashboardController> {
  const DashboardShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentTabIndex.value;
      final titles = [
        'dashboard_title'.tr,
        'properties_title'.tr,
        'tenants_title'.tr,
        'invoices_title'.tr,
        'more_title'.tr,
      ];

      return AppScaffold(
        title: titles[index],
        body: IndexedStack(
          index: index,
          children: const [
            _DashboardHomeView(),
            PropertiesListView(isEmbedded: true),
            TenantsListView(isEmbedded: true),
            InvoicesListView(isEmbedded: true),
            MoreMenuView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.changeTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: 'nav_home'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.apartment_outlined),
              selectedIcon: const Icon(Icons.apartment),
              label: 'nav_properties'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: 'nav_tenants'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'nav_dues'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: 'nav_more'.tr,
            ),
          ],
        ),
      );
    });
  }
}

class _DashboardHomeView extends GetView<DashboardController> {
  const _DashboardHomeView();

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (summary) => Obx(() {
        final currency = controller.storage.rxCurrency.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOwnerWelcomeBanner(context, currency),
              const SizedBox(height: 16),
              _buildKpiGrid(context, summary!, currency),
              const SizedBox(height: 20),
              _buildAlertsSection(context, currency),
              const SizedBox(height: 20),
              _buildChartsSection(context, summary, currency),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
      onLoading: const AppLoading(),
      onError: (err) => AppErrorState(
        message: err,
        onRetry: controller.loadDashboardData,
      ),
    );
  }

  Widget _buildOwnerWelcomeBanner(BuildContext context, String currency) {
    final scheme = Theme.of(context).colorScheme;
    final ownerName = controller.storage.rxOwnerName.value;
    final ownerPhone = controller.storage.rxOwnerPhone.value;
    final currencySymbol = CurrencyUtils.displaySymbol(currency);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  child: Icon(Icons.verified_user, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'welcome_owner'.tr} $ownerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$ownerPhone • ${'currency'.tr}: $currencySymbol',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 310) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.contractCreate),
                        icon: const Icon(Icons.note_add_outlined, size: 18),
                        label: Text(
                          'create_contract'.tr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.paymentRecord),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(
                          'record_payment'.tr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.contractCreate),
                        icon: const Icon(Icons.note_add_outlined, size: 18),
                        label: Flexible(
                          child: Text(
                            'create_contract'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.paymentRecord),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Flexible(
                          child: Text(
                            'record_payment'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    DashboardSummaryEntity s,
    String currency,
  ) {
    final cards = [
      SummaryStatCard(
        title: 'total_properties'.tr,
        value: '${s.totalProperties}',
        icon: Icons.domain,
        color: AppTheme.primaryColor,
        onTap: () => controller.changeTab(1),
      ),
      SummaryStatCard(
        title: 'total_apartments'.tr,
        value: '${s.totalApartments}',
        subtitle:
            '${'rented_apartments'.tr}: ${s.rentedApartments} | ${'vacant_apartments'.tr}: ${s.vacantApartments}',
        icon: Icons.meeting_room_outlined,
        color: AppTheme.secondaryColor,
        onTap: () => Get.toNamed(AppRoutes.apartments),
      ),
      SummaryStatCard(
        title: 'maintenance_apartments'.tr,
        value: '${s.maintenanceApartments}',
        icon: Icons.build_circle_outlined,
        color: AppTheme.warningColor,
        onTap: () => Get.toNamed(AppRoutes.apartments),
      ),
      SummaryStatCard(
        title: 'total_tenants'.tr,
        value: '${s.totalTenants}',
        icon: Icons.people_alt_outlined,
        color: AppTheme.primaryColor,
        onTap: () => controller.changeTab(2),
      ),
      SummaryStatCard(
        title: 'active_contracts'.tr,
        value: '${s.activeContracts}',
        subtitle: '${'expiring_contracts'.tr}: ${s.expiringContracts}',
        icon: Icons.description_outlined,
        color: AppTheme.successColor,
        onTap: () => Get.toNamed(AppRoutes.contracts),
      ),
      SummaryStatCard(
        title: 'expected_monthly_rent'.tr,
        value: CurrencyUtils.formatAmount(
          s.expectedMonthlyRent,
          currency: currency,
        ),
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.primaryColor,
      ),
      SummaryStatCard(
        title: 'monthly_collections'.tr,
        value: CurrencyUtils.formatAmount(
          s.monthlyCollections,
          currency: currency,
        ),
        icon: Icons.trending_up,
        color: AppTheme.successColor,
        onTap: () => Get.toNamed(AppRoutes.payments),
      ),
      SummaryStatCard(
        title: 'total_dues'.tr,
        value: CurrencyUtils.formatAmount(
          s.totalDues,
          currency: currency,
        ),
        subtitle:
            '${'total_overdue'.tr}: ${CurrencyUtils.formatAmount(s.totalOverdue, currency: currency)}',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.errorColor,
        onTap: () => controller.changeTab(3),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : constraints.maxWidth < 280
                    ? 1
                    : 2;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 128,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildAlertsSection(BuildContext context, String currency) {
    final overdueInvoices = Phase1MockData.invoices
        .where((i) => i.status == 'Overdue')
        .toList();
    final expiringContracts = Phase1MockData.contracts
        .where((c) => c.status == 'expiring')
        .toList();
    final upcomingInvoices = Phase1MockData.invoices
        .where((i) => i.status == 'Pending' || i.status == 'Partially Paid')
        .toList();
    final maintApartments = Phase1MockData.apartments
        .where((a) => a.status == 'maintenance')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'alerts_section'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              // 1. Overdue Invoices Alert
              for (final inv in overdueInvoices)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.error_outline, color: AppTheme.errorColor),
                  ),
                  title: Text(
                    '${'alert_overdue'.tr} (${inv.billingMonth})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${Phase1MockData.getTenant(Phase1MockData.getContract(inv.contractId)?.tenantId ?? 0)?.fullName ?? ''} • ${CurrencyUtils.formatAmount(inv.remainingAmount, currency: currency)}',
                  ),
                  trailing: StatusBadge(
                    label: 'inv_status_overdue'.tr,
                    color: AppTheme.errorColor,
                  ),
                  onTap: () =>
                      Get.toNamed(AppRoutes.invoiceDetails, arguments: inv.id),
                ),
              const Divider(height: 1),
              // 2. Expiring Contracts Alert
              for (final cnt in expiringContracts)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(
                      Icons.event_busy_outlined,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  title: Text(
                    '${'alert_expiring'.tr}: ${cnt.contractNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${Phase1MockData.getTenant(cnt.tenantId)?.fullName ?? ''} • ${'end_date'.tr}: ${cnt.endAt}',
                  ),
                  trailing: TextButton(
                    onPressed: () => Get.toNamed(
                      AppRoutes.contractRenew,
                      arguments: cnt.id,
                    ),
                    child: Text('renew_contract'.tr),
                  ),
                  onTap: () => Get.toNamed(
                    AppRoutes.contractDetails,
                    arguments: cnt.id,
                  ),
                ),
              const Divider(height: 1),
              // 3. Upcoming Invoices Alert
              for (final inv in upcomingInvoices)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(
                      Icons.schedule_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    '${'alert_upcoming_invoices'.tr} (${inv.billingMonth})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${'due_date'.tr}: ${inv.dueDate} • ${'remaining_amount'.tr}: ${CurrencyUtils.formatAmount(inv.remainingAmount, currency: currency)}',
                  ),
                  onTap: () =>
                      Get.toNamed(AppRoutes.invoiceDetails, arguments: inv.id),
                ),
              const Divider(height: 1),
              // 4. Maintenance Apartments needing follow-up
              for (final apt in maintApartments)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(
                      Icons.handyman_outlined,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  title: Text(
                    '${'alert_apartments_followup'.tr}: ${apt.apartmentNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(apt.notes),
                  onTap: () => Get.toNamed(
                    AppRoutes.apartmentDetails,
                    arguments: apt.id,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    DashboardSummaryEntity s,
    String currency,
  ) {
    final totalBilledAll = Phase1MockData.invoices.fold<num>(
      0,
      (sum, i) => sum + i.totalAmount,
    );
    final totalPaidAll = Phase1MockData.invoices.fold<num>(
      0,
      (sum, i) => sum + i.paidAmount,
    );

    final aptStatusCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'chart_apartments_status'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            _buildHorizontalDistributionRow(
              label: 'apt_status_rented'.tr,
              count: s.rentedApartments,
              total: s.totalApartments,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 10),
            _buildHorizontalDistributionRow(
              label: 'apt_status_vacant'.tr,
              count: s.vacantApartments,
              total: s.totalApartments,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildHorizontalDistributionRow(
              label: 'apt_status_maintenance'.tr,
              count: s.maintenanceApartments,
              total: s.totalApartments,
              color: AppTheme.warningColor,
            ),
          ],
        ),
      ),
    );

    final duesVsPaidCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'chart_dues_vs_paid'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            _buildHorizontalAmountRow(
              label: 'total_billed'.tr,
              amount: totalBilledAll,
              maxAmount: totalBilledAll,
              currency: currency,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildHorizontalAmountRow(
              label: 'total_paid'.tr,
              amount: totalPaidAll,
              maxAmount: totalBilledAll,
              currency: currency,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 10),
            _buildHorizontalAmountRow(
              label: 'remaining_balance'.tr,
              amount: s.totalDues,
              maxAmount: totalBilledAll,
              currency: currency,
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Monthly Collections Comparison Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chart_monthly_collections'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildBarItem(context, '06', 0.65, '6,200'),
                      ),
                      Expanded(
                        child: _buildBarItem(context, '07', 0.75, '7,100'),
                      ),
                      Expanded(
                        child: _buildBarItem(context, '08', 0.80, '7,550'),
                      ),
                      Expanded(
                        child: _buildBarItem(context, '09', 0.85, '8,000'),
                      ),
                      Expanded(
                        child: _buildBarItem(context, '10', 0.55, '2,750'),
                      ),
                      Expanded(
                        child: _buildBarItem(context, '11', 0.70, '4,250'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // 2. Apartment Status Distribution & 3. Dues vs Paid Comparison
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  aptStatusCard,
                  const SizedBox(height: 14),
                  duesVsPaidCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: aptStatusCard),
                const SizedBox(width: 14),
                Expanded(child: duesVsPaidCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBarItem(
    BuildContext context,
    String monthLabel,
    double ratio,
    String amountLabel,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amountLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 24,
            height: 85 * ratio,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '2026-$monthLabel',
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDistributionRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count / $total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalAmountRow({
    required String label,
    required num amount,
    required num maxAmount,
    required String currency,
    required Color color,
  }) {
    final ratio = maxAmount > 0 ? (amount / maxAmount).toDouble() : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                CurrencyUtils.formatAmount(amount, currency: currency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
