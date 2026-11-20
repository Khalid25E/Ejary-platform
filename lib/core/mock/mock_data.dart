import 'package:get/get.dart';
import '../../features/apartments/domain/entities/apartment_entity.dart';
import '../../features/apartments/domain/entities/apartment_service_entity.dart';
import '../../features/contracts/domain/entities/contract_entity.dart';
import '../../features/contracts/domain/entities/contract_service_entity.dart';
import '../../features/invoices/domain/entities/invoice_entity.dart';
import '../../features/payments/domain/entities/payment_entity.dart';
import '../../features/properties/domain/entities/property_entity.dart';
import '../../features/services/domain/entities/service_entity.dart';
import '../../features/tenants/domain/entities/tenant_entity.dart';
import '../../features/zones/domain/entities/zone_entity.dart';
import '../database/database_lookup_service.dart';
import '../database/database_seeder.dart';

/// In Phase 2, all lookups read live SQLite records from [DatabaseLookupService].
/// Static seed constants are kept in [DatabaseSeeder] ONLY for test/demo seeding.
class Phase1MockData {
  Phase1MockData._();

  static DatabaseLookupService? get _lookup =>
      Get.isRegistered<DatabaseLookupService>()
          ? Get.find<DatabaseLookupService>()
          : null;

  static List<ZoneEntity> get zones =>
      _lookup?.zones.toList() ?? DatabaseSeeder.seedZones;

  static List<PropertyEntity> get properties =>
      _lookup?.properties.toList() ?? DatabaseSeeder.seedProperties;

  static List<ServiceEntity> get services =>
      _lookup?.services.toList() ?? DatabaseSeeder.seedServices;

  static List<ApartmentEntity> get apartments =>
      _lookup?.apartments.toList() ?? DatabaseSeeder.seedApartments;

  static List<ApartmentServiceEntity> get apartmentServices =>
      _lookup?.apartmentServices.toList() ??
      DatabaseSeeder.seedApartmentServices;

  static List<TenantEntity> get tenants =>
      _lookup?.tenants.toList() ?? DatabaseSeeder.seedTenants;

  static List<ContractEntity> get contracts =>
      _lookup?.contracts.toList() ?? DatabaseSeeder.seedContracts;

  static List<ContractServiceEntity> get contractServices =>
      _lookup?.contractServices.toList() ?? DatabaseSeeder.seedContractServices;

  static List<InvoiceEntity> get invoices =>
      _lookup?.invoices.toList() ?? DatabaseSeeder.seedInvoices;

  static List<PaymentEntity> get payments =>
      _lookup?.payments.toList() ?? DatabaseSeeder.seedPayments;

  static ZoneEntity? getZone(int id) =>
      _lookup != null ? _lookup!.getZone(id) : zones.where((z) => z.id == id).firstOrNull;

  static PropertyEntity? getProperty(int id) =>
      _lookup != null ? _lookup!.getProperty(id) : properties.where((p) => p.id == id).firstOrNull;

  static ApartmentEntity? getApartment(int id) =>
      _lookup != null ? _lookup!.getApartment(id) : apartments.where((a) => a.id == id).firstOrNull;

  static TenantEntity? getTenant(int id) =>
      _lookup != null ? _lookup!.getTenant(id) : tenants.where((t) => t.id == id).firstOrNull;

  static ContractEntity? getContract(int id) =>
      _lookup != null ? _lookup!.getContract(id) : contracts.where((c) => c.id == id).firstOrNull;

  static InvoiceEntity? getInvoice(int id) =>
      _lookup != null ? _lookup!.getInvoice(id) : invoices.where((i) => i.id == id).firstOrNull;

  static ServiceEntity? getService(int id) =>
      _lookup != null ? _lookup!.getService(id) : services.where((s) => s.id == id).firstOrNull;
}
