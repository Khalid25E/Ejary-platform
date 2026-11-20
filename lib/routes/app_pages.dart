import 'package:get/get.dart';
import '../features/apartments/presentation/bindings/apartments_binding.dart';
import '../features/apartments/presentation/pages/apartments_page.dart';
import '../features/contracts/presentation/bindings/contracts_binding.dart';
import '../features/contracts/presentation/pages/contract_wizard_page.dart';
import '../features/contracts/presentation/pages/contracts_page.dart';
import '../features/dashboard/presentation/bindings/dashboard_binding.dart';
import '../features/dashboard/presentation/pages/dashboard_shell_page.dart';
import '../features/invoices/presentation/bindings/invoices_binding.dart';
import '../features/invoices/presentation/pages/invoices_page.dart';
import '../features/onboarding/presentation/bindings/onboarding_binding.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/payments/presentation/bindings/payments_binding.dart';
import '../features/payments/presentation/pages/payments_page.dart';
import '../features/properties/presentation/bindings/properties_binding.dart';
import '../features/properties/presentation/pages/properties_page.dart';
import '../features/services/presentation/bindings/services_binding.dart';
import '../features/services/presentation/pages/services_page.dart';
import '../features/settings/presentation/bindings/settings_binding.dart';
import '../features/settings/presentation/pages/more_menu_page.dart';
import '../features/tenants/presentation/bindings/tenants_binding.dart';
import '../features/tenants/presentation/pages/tenants_page.dart';
import '../features/zones/presentation/bindings/zones_binding.dart';
import '../features/zones/presentation/pages/zones_page.dart';
import 'app_routes.dart';
import 'middlewares/entity_guard_middleware.dart';
import 'middlewares/owner_setup_middleware.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardShellPage(),
      binding: DashboardBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.zones,
      page: () => const ZonesPage(),
      binding: ZonesBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.properties,
      page: () => const PropertiesPage(),
      binding: PropertiesBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.propertyForm,
      page: () => const PropertyFormPage(),
      binding: PropertiesBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.propertyDetails,
      page: () => const PropertyDetailsPage(),
      binding: PropertiesBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'property'),
      ],
    ),
    GetPage(
      name: AppRoutes.apartments,
      page: () => const ApartmentsPage(),
      binding: ApartmentsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.apartmentForm,
      page: () => const ApartmentFormPage(),
      binding: ApartmentsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.apartmentDetails,
      page: () => const ApartmentDetailsPage(),
      binding: ApartmentsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'apartment'),
      ],
    ),
    GetPage(
      name: AppRoutes.apartmentServices,
      page: () => const ApartmentServicesPage(),
      binding: ApartmentsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'apartment'),
      ],
    ),
    GetPage(
      name: AppRoutes.services,
      page: () => const ServicesPage(),
      binding: ServicesBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tenants,
      page: () => const TenantsPage(),
      binding: TenantsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tenantForm,
      page: () => const TenantFormPage(),
      binding: TenantsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tenantDetails,
      page: () => const TenantDetailsPage(),
      binding: TenantsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'tenant'),
      ],
    ),
    GetPage(
      name: AppRoutes.tenantStatement,
      page: () => const TenantStatementPage(),
      binding: TenantsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'tenant'),
      ],
    ),
    GetPage(
      name: AppRoutes.contracts,
      page: () => const ContractsPage(),
      binding: ContractsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.contractCreate,
      page: () => const ContractWizardPage(),
      binding: ContractsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.contractDetails,
      page: () => const ContractDetailsPage(),
      binding: ContractsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'contract'),
      ],
    ),
    GetPage(
      name: AppRoutes.contractRenew,
      page: () => const ContractRenewPage(),
      binding: ContractsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'contract'),
      ],
    ),
    GetPage(
      name: AppRoutes.contractTerminate,
      page: () => const ContractTerminatePage(),
      binding: ContractsBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'contract'),
      ],
    ),
    GetPage(
      name: AppRoutes.invoices,
      page: () => const InvoicesPage(),
      binding: InvoicesBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.invoiceDetails,
      page: () => const InvoiceDetailsPage(),
      binding: InvoicesBinding(),
      middlewares: [
        OwnerSetupMiddleware(),
        EntityGuardMiddleware(entityType: 'invoice'),
      ],
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const PaymentsPage(),
      binding: PaymentsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.paymentRecord,
      page: () => const RecordPaymentPage(),
      binding: PaymentsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.paymentReceipt,
      page: () => const PaymentReceiptPage(),
      binding: PaymentsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.backupRestore,
      page: () => const BackupRestorePage(),
      binding: SettingsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsPage(),
      binding: SettingsBinding(),
      middlewares: [OwnerSetupMiddleware()],
    ),
  ];
}
