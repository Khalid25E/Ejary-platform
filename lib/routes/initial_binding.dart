import 'package:get/get.dart';
import '../core/database/app_database.dart';
import '../core/database/database_lookup_service.dart';
import '../core/localization/locale_service.dart';
import '../core/storage/local_storage_service.dart';
import '../core/theme/theme_service.dart';
import '../features/apartments/data/repositories/apartment_repository_impl.dart';
import '../features/apartments/domain/repositories/apartment_repository.dart';
import '../features/apartments/domain/usecases/manage_apartments_usecase.dart';
import '../features/contracts/data/repositories/contract_repository_impl.dart';
import '../features/contracts/domain/repositories/contract_repository.dart';
import '../features/contracts/domain/usecases/manage_contracts_usecase.dart';
import '../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../features/invoices/data/repositories/invoice_repository_impl.dart';
import '../features/invoices/domain/repositories/invoice_repository.dart';
import '../features/invoices/domain/usecases/manage_invoices_usecase.dart';
import '../features/payments/data/datasources/receipt_pdf_service.dart';
import '../features/payments/data/repositories/payment_repository_impl.dart';
import '../features/payments/domain/repositories/payment_repository.dart';
import '../features/payments/domain/usecases/manage_payments_usecase.dart';
import '../features/properties/data/repositories/property_repository_impl.dart';
import '../features/properties/domain/repositories/property_repository.dart';
import '../features/properties/domain/usecases/manage_properties_usecase.dart';
import '../features/services/data/repositories/service_repository_impl.dart';
import '../features/services/domain/repositories/service_repository.dart';
import '../features/services/domain/usecases/manage_services_usecase.dart';
import '../features/settings/data/datasources/backup_local_datasource.dart';
import '../features/tenants/data/repositories/tenant_repository_impl.dart';
import '../features/tenants/domain/repositories/tenant_repository.dart';
import '../features/tenants/domain/usecases/manage_tenants_usecase.dart';
import '../features/zones/data/repositories/zone_repository_impl.dart';
import '../features/zones/domain/repositories/zone_repository.dart';
import '../features/zones/domain/usecases/manage_zones_usecase.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalStorageService>()) {
      Get.put<LocalStorageService>(LocalStorageService(), permanent: true);
    }
    if (!Get.isRegistered<ThemeService>()) {
      Get.put<ThemeService>(ThemeService(), permanent: true);
    }
    if (!Get.isRegistered<LocaleService>()) {
      Get.put<LocaleService>(LocaleService(), permanent: true);
    }

    if (Get.isRegistered<AppDatabase>()) {
      final appDb = Get.find<AppDatabase>();

      if (!Get.isRegistered<DatabaseLookupService>()) {
        Get.put<DatabaseLookupService>(
          DatabaseLookupService(appDb),
          permanent: true,
        );
      }

      // Repositories
      if (!Get.isRegistered<ZoneRepository>()) {
        Get.lazyPut<ZoneRepository>(
          () => ZoneRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<PropertyRepository>()) {
        Get.lazyPut<PropertyRepository>(
          () => PropertyRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ApartmentRepository>()) {
        Get.lazyPut<ApartmentRepository>(
          () => ApartmentRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ServiceRepository>()) {
        Get.lazyPut<ServiceRepository>(
          () => ServiceRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<TenantRepository>()) {
        Get.lazyPut<TenantRepository>(
          () => TenantRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ContractRepository>()) {
        Get.lazyPut<ContractRepository>(
          () => ContractRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<InvoiceRepository>()) {
        Get.lazyPut<InvoiceRepository>(
          () => InvoiceRepositoryImpl(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<PaymentRepository>()) {
        Get.lazyPut<PaymentRepository>(
          () => PaymentRepositoryImpl(appDb),
          fenix: true,
        );
      }

      // Use Cases & Services
      if (!Get.isRegistered<ManageZonesUseCase>()) {
        Get.lazyPut<ManageZonesUseCase>(
          () => ManageZonesUseCase(Get.find<ZoneRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManagePropertiesUseCase>()) {
        Get.lazyPut<ManagePropertiesUseCase>(
          () => ManagePropertiesUseCase(Get.find<PropertyRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManageApartmentsUseCase>()) {
        Get.lazyPut<ManageApartmentsUseCase>(
          () => ManageApartmentsUseCase(Get.find<ApartmentRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManageServicesUseCase>()) {
        Get.lazyPut<ManageServicesUseCase>(
          () => ManageServicesUseCase(Get.find<ServiceRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManageTenantsUseCase>()) {
        Get.lazyPut<ManageTenantsUseCase>(
          () => ManageTenantsUseCase(Get.find<TenantRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManageContractsUseCase>()) {
        Get.lazyPut<ManageContractsUseCase>(
          () => ManageContractsUseCase(Get.find<ContractRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManageInvoicesUseCase>()) {
        Get.lazyPut<ManageInvoicesUseCase>(
          () => ManageInvoicesUseCase(Get.find<InvoiceRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ManagePaymentsUseCase>()) {
        Get.lazyPut<ManagePaymentsUseCase>(
          () => ManagePaymentsUseCase(Get.find<PaymentRepository>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<DashboardLocalDataSource>()) {
        Get.lazyPut<DashboardLocalDataSource>(
          () => DashboardLocalDataSource(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<BackupLocalDataSource>()) {
        Get.lazyPut<BackupLocalDataSource>(
          () => BackupLocalDataSource(appDb),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ReceiptPdfService>()) {
        Get.lazyPut<ReceiptPdfService>(
          () => const ReceiptPdfService(),
          fenix: true,
        );
      }
    }
  }
}
