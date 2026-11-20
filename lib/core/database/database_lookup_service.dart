import 'package:get/get.dart';
import '../../features/apartments/data/models/apartment_model.dart';
import '../../features/apartments/data/models/apartment_service_model.dart';
import '../../features/apartments/domain/entities/apartment_entity.dart';
import '../../features/apartments/domain/entities/apartment_service_entity.dart';
import '../../features/contracts/data/models/contract_model.dart';
import '../../features/contracts/data/models/contract_service_model.dart';
import '../../features/contracts/domain/entities/contract_entity.dart';
import '../../features/contracts/domain/entities/contract_service_entity.dart';
import '../../features/invoices/data/models/invoice_model.dart';
import '../../features/invoices/domain/entities/invoice_entity.dart';
import '../../features/payments/data/models/payment_model.dart';
import '../../features/payments/domain/entities/payment_entity.dart';
import '../../features/properties/data/models/property_model.dart';
import '../../features/properties/domain/entities/property_entity.dart';
import '../../features/services/data/models/service_model.dart';
import '../../features/services/domain/entities/service_entity.dart';
import '../../features/tenants/data/models/tenant_model.dart';
import '../../features/tenants/domain/entities/tenant_entity.dart';
import '../../features/zones/data/models/zone_model.dart';
import '../../features/zones/domain/entities/zone_entity.dart';
import 'app_database.dart';
import 'database_tables.dart';

/// Reactive SQLite cache & lookup service that keeps all screens, detail views,
/// and route middlewares synchronized with the actual SQLite database in real time.
class DatabaseLookupService extends GetxService {
  final AppDatabase _appDb;

  DatabaseLookupService(this._appDb);

  final RxList<ZoneEntity> zones = <ZoneEntity>[].obs;
  final RxList<PropertyEntity> properties = <PropertyEntity>[].obs;
  final RxList<ApartmentEntity> apartments = <ApartmentEntity>[].obs;
  final RxList<ServiceEntity> services = <ServiceEntity>[].obs;
  final RxList<ApartmentServiceEntity> apartmentServices =
      <ApartmentServiceEntity>[].obs;
  final RxList<TenantEntity> tenants = <TenantEntity>[].obs;
  final RxList<ContractEntity> contracts = <ContractEntity>[].obs;
  final RxList<ContractServiceEntity> contractServices =
      <ContractServiceEntity>[].obs;
  final RxList<InvoiceEntity> invoices = <InvoiceEntity>[].obs;
  final RxList<PaymentEntity> payments = <PaymentEntity>[].obs;

  Future<DatabaseLookupService> refreshAll() async {
    final db = _appDb.db;

    final zRows = await db.query(DatabaseTables.zones, orderBy: 'id ASC');
    zones.assignAll(zRows.map(ZoneModel.fromMap));

    final pRows = await db.query(DatabaseTables.properties, orderBy: 'id ASC');
    properties.assignAll(pRows.map(PropertyModel.fromMap));

    final aRows = await db.query(DatabaseTables.apartments, orderBy: 'id ASC');
    apartments.assignAll(aRows.map(ApartmentModel.fromMap));

    final sRows = await db.query(DatabaseTables.services, orderBy: 'id ASC');
    services.assignAll(sRows.map(ServiceModel.fromMap));

    final asRows = await db.query(
      DatabaseTables.apartmentServices,
      orderBy: 'id ASC',
    );
    apartmentServices.assignAll(asRows.map(ApartmentServiceModel.fromMap));

    final tRows = await db.query(DatabaseTables.tenants, orderBy: 'id ASC');
    tenants.assignAll(tRows.map(TenantModel.fromMap));

    final cRows = await db.query(DatabaseTables.contracts, orderBy: 'id DESC');
    contracts.assignAll(cRows.map(ContractModel.fromMap));

    final csRows = await db.query(
      DatabaseTables.contractServices,
      orderBy: 'id ASC',
    );
    contractServices.assignAll(csRows.map(ContractServiceModel.fromMap));

    final iRows = await db.query(
      DatabaseTables.invoices,
      orderBy: 'billing_month DESC, id DESC',
    );
    invoices.assignAll(iRows.map(InvoiceModel.fromMap));

    final payRows = await db.query(
      DatabaseTables.payments,
      orderBy: 'pay_at DESC, id DESC',
    );
    payments.assignAll(payRows.map(PaymentModel.fromMap));

    return this;
  }

  ZoneEntity? getZone(int id) => zones.where((z) => z.id == id).firstOrNull;

  PropertyEntity? getProperty(int id) =>
      properties.where((p) => p.id == id).firstOrNull;

  ApartmentEntity? getApartment(int id) =>
      apartments.where((a) => a.id == id).firstOrNull;

  ServiceEntity? getService(int id) =>
      services.where((s) => s.id == id).firstOrNull;

  TenantEntity? getTenant(int id) =>
      tenants.where((t) => t.id == id).firstOrNull;

  ContractEntity? getContract(int id) =>
      contracts.where((c) => c.id == id).firstOrNull;

  InvoiceEntity? getInvoice(int id) =>
      invoices.where((i) => i.id == id).firstOrNull;

  PaymentEntity? getPayment(int id) =>
      payments.where((p) => p.id == id).firstOrNull;
}
