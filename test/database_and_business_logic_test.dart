import 'dart:io';
import 'package:ejary/core/database/app_database.dart';
import 'package:ejary/core/database/database_seeder.dart';
import 'package:ejary/core/errors/app_exceptions.dart';
import 'package:ejary/features/apartments/data/repositories/apartment_repository_impl.dart';
import 'package:ejary/features/apartments/domain/entities/apartment_service_entity.dart';
import 'package:ejary/features/apartments/domain/usecases/manage_apartments_usecase.dart';
import 'package:ejary/features/contracts/data/repositories/contract_repository_impl.dart';
import 'package:ejary/features/contracts/domain/entities/contract_entity.dart';
import 'package:ejary/features/contracts/domain/entities/contract_service_entity.dart';
import 'package:ejary/features/contracts/domain/usecases/manage_contracts_usecase.dart';
import 'package:ejary/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:ejary/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:ejary/features/invoices/domain/usecases/manage_invoices_usecase.dart';
import 'package:ejary/features/payments/data/datasources/receipt_pdf_service.dart';
import 'package:ejary/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:ejary/features/payments/domain/entities/payment_entity.dart';
import 'package:ejary/features/payments/domain/usecases/manage_payments_usecase.dart';
import 'package:ejary/features/properties/data/repositories/property_repository_impl.dart';
import 'package:ejary/features/properties/domain/usecases/manage_properties_usecase.dart';
import 'package:ejary/features/services/data/repositories/service_repository_impl.dart';
import 'package:ejary/features/services/domain/entities/service_entity.dart';
import 'package:ejary/features/services/domain/usecases/manage_services_usecase.dart';
import 'package:ejary/features/settings/data/datasources/backup_local_datasource.dart';
import 'package:ejary/features/tenants/data/repositories/tenant_repository_impl.dart';
import 'package:ejary/features/tenants/domain/entities/tenant_entity.dart';
import 'package:ejary/features/tenants/domain/usecases/manage_tenants_usecase.dart';
import 'package:ejary/features/zones/data/repositories/zone_repository_impl.dart';
import 'package:ejary/features/zones/domain/entities/zone_entity.dart';
import 'package:ejary/features/zones/domain/usecases/manage_zones_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppDatabase appDb;
  late ManageZonesUseCase zonesUseCase;
  late ManagePropertiesUseCase propertiesUseCase;
  late ManageApartmentsUseCase apartmentsUseCase;
  late ManageServicesUseCase servicesUseCase;
  late ManageTenantsUseCase tenantsUseCase;
  late ManageContractsUseCase contractsUseCase;
  late ManageInvoicesUseCase invoicesUseCase;
  late ManagePaymentsUseCase paymentsUseCase;
  late DashboardLocalDataSource dashboardDataSource;
  late BackupLocalDataSource backupDataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ejary_db_test_');
    final dbFilePath = p.join(tempDir.path, 'ejary_test.db');

    appDb = await AppDatabase(
      isTestEnvironment: true,
      autoSeedInTest: false,
    ).init(customPath: dbFilePath);

    zonesUseCase = ManageZonesUseCase(ZoneRepositoryImpl(appDb));
    propertiesUseCase = ManagePropertiesUseCase(PropertyRepositoryImpl(appDb));
    apartmentsUseCase = ManageApartmentsUseCase(ApartmentRepositoryImpl(appDb));
    servicesUseCase = ManageServicesUseCase(ServiceRepositoryImpl(appDb));
    tenantsUseCase = ManageTenantsUseCase(TenantRepositoryImpl(appDb));
    contractsUseCase = ManageContractsUseCase(ContractRepositoryImpl(appDb));
    invoicesUseCase = ManageInvoicesUseCase(InvoiceRepositoryImpl(appDb));
    paymentsUseCase = ManagePaymentsUseCase(PaymentRepositoryImpl(appDb));
    dashboardDataSource = DashboardLocalDataSource(appDb);
    backupDataSource = BackupLocalDataSource(appDb);
  });

  tearDown(() async {
    await appDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
      '1. Production Policy: First run starts completely empty; Optional seeding runs once & persists across restart',
      () async {
    // Starts empty when autoSeedInTest is false (Production default)
    expect(await zonesUseCase.getZones(), isEmpty);
    expect(await propertiesUseCase.getProperties(), isEmpty);
    expect(await tenantsUseCase.getTenants(), isEmpty);

    // Optional seed data loads when DB is empty
    final seeded1 = await appDb.loadOptionalDemoSeedData();
    expect(seeded1, isTrue);
    expect((await zonesUseCase.getZones()).length, equals(3));
    expect((await propertiesUseCase.getProperties()).length, equals(3));
    expect((await apartmentsUseCase.getApartments()).length, equals(6));

    // Calling seed again NEVER duplicates records
    final seeded2 = await appDb.loadOptionalDemoSeedData();
    expect(seeded2, isFalse);
    expect((await zonesUseCase.getZones()).length, equals(3));

    // Close and reopen database to verify persistence across app restarts
    await appDb.reopen();
    expect((await zonesUseCase.getZones()).length, equals(3));
    expect((await contractsUseCase.getContracts()).length, equals(4));
  });

  test(
      '2. Referential Integrity & Foreign Key Constraints: Prevents deleting linked Zones, Properties, Apartments, Services, Tenants',
      () async {
    await DatabaseSeeder.seedIfEmpty(appDb.db);

    // Cannot delete Zone 1 because Property 1 is linked to it
    expect(
      () => zonesUseCase.deleteZone(1),
      throwsA(isA<DataIntegrityException>()),
    );

    // Cannot delete Property 1 because Apartments 101..103 are linked to it
    expect(
      () => propertiesUseCase.deleteProperty(1),
      throwsA(isA<DataIntegrityException>()),
    );

    // Cannot delete Apartment 101 because Contract 1 is linked to it
    expect(
      () => apartmentsUseCase.deleteApartment(101),
      throwsA(isA<DataIntegrityException>()),
    );

    // Cannot delete Service 1 because it has historical contract_services & apartment_services
    expect(
      () => servicesUseCase.deleteService(1),
      throwsA(isA<DataIntegrityException>()),
    );

    // Cannot delete Tenant 1 because Contract 1 is linked to them
    expect(
      () => tenantsUseCase.deleteTenant(1),
      throwsA(isA<DataIntegrityException>()),
    );

    // Can add and delete a new unlinked Zone cleanly
    final newZoneId = await zonesUseCase.addZone(
      const ZoneEntity(
        id: 0,
        name: 'حي الياسمين',
        description: 'منطقة جديدة',
        createdAt: '2026-11-20',
      ),
    );
    expect(newZoneId, greaterThan(0));
    await zonesUseCase.deleteZone(newZoneId);
  });

  test(
      '3. Custom Apartment Services & Historical Contract Services Snapshot Isolation (FR-06 & FR-09)',
      () async {
    await DatabaseSeeder.seedIfEmpty(appDb.db);

    // Update default price of Service 1 (Water) from 100 to 999
    await servicesUseCase.updateService(
      const ServiceEntity(
        id: 1,
        name: 'المياه',
        description: 'تعديل السعر الافتراضي',
        defaultPrice: 999,
        billingType: 'fixed_monthly',
        isActive: true,
        createdAt: '2026-01-01',
      ),
    );

    // Verify Apartment 102 custom price for Service 1 is STILL 90 (FR-06 Rule 2)
    final apt102Services = await apartmentsUseCase.getApartmentServices(102);
    final apt102Water =
        apt102Services.firstWhere((s) => s.serviceId == 1);
    expect(apt102Water.customPrice, equals(90));

    // Verify Contract 1 historical snapshot for Service 1 is STILL 100 (FR-06 Rule 3 & FR-09)
    final cnt1Services = await contractsUseCase.getContractServices(1);
    final cnt1Water = cnt1Services.firstWhere((s) => s.serviceId == 1);
    expect(cnt1Water.price, equals(100));

    // Customize Apartment 102 services to 140 and verify Contract 1 is still untouched
    await apartmentsUseCase.saveApartmentServices(
      102,
      const [
        ApartmentServiceEntity(
          id: 0,
          apartmentId: 102,
          serviceId: 1,
          customPrice: 140,
          billingType: 'fixed_monthly',
          isActive: true,
          notes: 'تحديث مخصص',
          createdAt: '2026-11-20',
        ),
      ],
    );
    final updatedApt102 = await apartmentsUseCase.getApartmentServices(102);
    expect(updatedApt102.first.customPrice, equals(140));
    final cnt1ServicesAfter = await contractsUseCase.getContractServices(1);
    expect(
      cnt1ServicesAfter.firstWhere((s) => s.serviceId == 1).price,
      equals(100),
    );
  });

  test(
      '4. Contracts Lifecycle: Atomic Creation, Conflict Prevention, Renewal, and Termination (FR-08)',
      () async {
    await DatabaseSeeder.seedIfEmpty(appDb.db);

    // 4.1 Prevent creating conflicting active contract on already rented Apartment 101
    expect(
      () => contractsUseCase.createContract(
        contract: const ContractEntity(
          id: 0,
          contractNumber: 'CNT-CONFLICT-01',
          apartmentId: 101, // already rented in 2026-01-01..2026-12-31
          tenantId: 1,
          startedAt: '2026-06-01',
          endAt: '2027-05-31',
          createdAt: '2026-06-01',
          price: 2500,
          totalServices: 250,
          conditionsJson: '[]',
          dueDate: '2026-06-05',
          dueDay: 5,
          rentalAt: '2026-06-01',
          autoRenew: true,
          status: 'active',
          notes: '',
        ),
        servicesSnapshot: const [],
      ),
      throwsA(isA<DataIntegrityException>()),
    );

    // 4.2 Create new contract atomically on vacant Apartment 102 with inline new tenant
    final newCntId = await contractsUseCase.createContract(
      contract: const ContractEntity(
        id: 0,
        contractNumber: 'CNT-2026-NEW',
        apartmentId: 102,
        tenantId: 0,
        startedAt: '2026-11-01',
        endAt: '2027-10-31',
        createdAt: '2026-11-01',
        price: 2200,
        totalServices: 240,
        conditionsJson: '["شرط 1"]',
        dueDate: '2026-11-31',
        dueDay: 31, // Should clamp to 2026-11-30!
        rentalAt: '2026-11-01',
        autoRenew: true,
        status: 'active',
        notes: 'عقد جديد ذري',
      ),
      servicesSnapshot: const [
        ContractServiceEntity(
          id: 0,
          contractId: 0,
          serviceId: 1,
          serviceName: 'المياه',
          price: 90,
          billingType: 'fixed_monthly',
          createdAt: '2026-11-01',
        ),
        ContractServiceEntity(
          id: 0,
          contractId: 0,
          serviceId: 2,
          serviceName: 'النظافة والحراسة',
          price: 150,
          billingType: 'fixed_monthly',
          createdAt: '2026-11-01',
        ),
      ],
      inlineNewTenant: const TenantEntity(
        id: 0,
        fullName: 'ماجد بن نايف السبيعي',
        phone: '+966 59 000 1111',
        nationalId: '1077778888',
        notes: 'مستأجر مضاف داخل تدفق العقد',
        createdAt: '2026-11-01',
      ),
    );

    // Verify Apartment 102 status became 'rented' and due date clamped to 2026-11-30
    final apt102 = await apartmentsUseCase.getApartmentById(102);
    expect(apt102?.status, equals('rented'));
    final createdCnt = await contractsUseCase.getContractById(newCntId);
    expect(createdCnt?.dueDate, equals('2026-11-30'));
    expect(createdCnt?.monthlyTotal, equals(2440));

    // 4.3 Renew Contract 3 (expiring on 2026-11-30)
    final renewedCntId = await contractsUseCase.renewContract(
      oldContractId: 3,
      newContractNumber: 'CNT-2026-RNW3',
      newStartDate: '2026-12-01',
      newEndDate: '2027-11-30',
      newBaseRent: 3700,
      newServicesSnapshot: await contractsUseCase.getContractServices(3),
    );
    final oldCnt3 = await contractsUseCase.getContractById(3);
    final newCnt3 = await contractsUseCase.getContractById(renewedCntId);
    expect(oldCnt3?.status, equals('expired'));
    expect(newCnt3?.renewalOfContractId, equals(3));
    expect(newCnt3?.price, equals(3700));

    // 4.4 Terminate Contract 2 and set Apartment 103 to 'maintenance'
    await contractsUseCase.terminateContract(
      contractId: 2,
      terminationDate: '2026-11-20',
      terminationReason: 'انتقال المستأجر لمدينة أخرى',
      nextApartmentStatus: 'maintenance',
    );
    final terminatedCnt2 = await contractsUseCase.getContractById(2);
    final apt103 = await apartmentsUseCase.getApartmentById(103);
    expect(terminatedCnt2?.status, equals('terminated'));
    expect(apt103?.status, equals('maintenance'));

    // Historical invoice 1003 of Contract 2 is preserved!
    final inv1003 = await invoicesUseCase.getInvoiceById(1003);
    expect(inv1003, isNotNull);
  });

  test(
      '5. Monthly Invoices Generation, Partial & Full Payments, Cancellation, and Statement of Account (FR-10, FR-11, FR-14)',
      () async {
    await DatabaseSeeder.seedIfEmpty(appDb.db);

    // 5.1 Idempotent generation: 2026-11 already has invoices for active contracts 1, 2, 3
    final duplicateCount = await invoicesUseCase.generateMonthlyInvoices(
      '2026-11',
      referenceTodayIso: '2026-11-20',
    );
    expect(duplicateCount, equals(0));

    // Generate for next month 2026-12 (Contract 1 and 2 cover 2026-12; Contract 3 ends 2026-11-30)
    final decCount = await invoicesUseCase.generateMonthlyInvoices(
      '2026-12',
      referenceTodayIso: '2026-11-20',
    );
    expect(decCount, equals(2));

    // Reject unbounded future month (e.g. 2028-05)
    expect(
      () => invoicesUseCase.generateMonthlyInvoices(
        '2028-05',
        referenceTodayIso: '2026-11-20',
      ),
      throwsA(isA<ValidationException>()),
    );

    // 5.2 Payments on Invoice 1004 (Overdue, Total: 3800, Paid: 0, Remaining: 3800)
    // Reject 0 or negative payment
    expect(
      () => paymentsUseCase.recordPayment(
        const PaymentEntity(
          id: 0,
          contractId: 3,
          invoiceId: 1004,
          type: 'partial',
          payAt: '2026-11-20',
          amount: 0,
          payMethod: 'cash',
          payRef: 'ZERO',
          billingMonth: '2026-10',
          notes: '',
          createdAt: '2026-11-20',
        ),
      ),
      throwsA(isA<ValidationException>()),
    );

    // Reject overpayment (> 3800)
    expect(
      () => paymentsUseCase.recordPayment(
        const PaymentEntity(
          id: 0,
          contractId: 3,
          invoiceId: 1004,
          type: 'full',
          payAt: '2026-11-20',
          amount: 4000,
          payMethod: 'cash',
          payRef: 'OVER',
          billingMonth: '2026-10',
          notes: '',
          createdAt: '2026-11-20',
        ),
      ),
      throwsA(isA<ValidationException>()),
    );

    // Record partial payment of 1800 on Invoice 1004
    final p1Id = await paymentsUseCase.recordPayment(
      const PaymentEntity(
        id: 0,
        contractId: 3,
        invoiceId: 1004,
        type: 'partial',
        payAt: '2026-11-20',
        amount: 1800,
        payMethod: 'bank',
        payRef: 'PART-1',
        billingMonth: '2026-10',
        notes: 'دفعة جزئية أولى',
        createdAt: '2026-11-20',
      ),
      referenceTodayIso: '2026-11-20',
    );
    expect(p1Id, greaterThan(0));

    var inv1004 = await invoicesUseCase.getInvoiceById(1004);
    expect(inv1004?.paidAmount, equals(1800));
    expect(inv1004?.remainingAmount, equals(2000));
    expect(inv1004?.status, equals('Partially Paid'));

    // Record second payment of 2000 completing Invoice 1004
    final p2Id = await paymentsUseCase.recordPayment(
      const PaymentEntity(
        id: 0,
        contractId: 3,
        invoiceId: 1004,
        type: 'full',
        payAt: '2026-11-20',
        amount: 2000,
        payMethod: 'cash',
        payRef: 'PART-2',
        billingMonth: '2026-10',
        notes: 'سداد المتبقي',
        createdAt: '2026-11-20',
      ),
      referenceTodayIso: '2026-11-20',
    );

    inv1004 = await invoicesUseCase.getInvoiceById(1004);
    expect(inv1004?.paidAmount, equals(3800));
    expect(inv1004?.remainingAmount, equals(0));
    expect(inv1004?.status, equals('Paid'));

    // Cancel second payment (p2Id) and verify invoice reverts to Partially Paid (1800 paid, 2000 remaining)
    await paymentsUseCase.cancelPayment(
      p2Id,
      referenceTodayIso: '2026-11-20',
    );
    inv1004 = await invoicesUseCase.getInvoiceById(1004);
    expect(inv1004?.paidAmount, equals(1800));
    expect(inv1004?.remainingAmount, equals(2000));
    expect(inv1004?.status, equals('Partially Paid'));

    // Cancelled payment record still exists in audit history with isCancelled = true
    final cancelledPay = await paymentsUseCase.getPaymentById(p2Id);
    expect(cancelledPay?.isCancelled, isTrue);

    // 5.3 Verify Tenant 3 Statement of Account (FR-14)
    // Tenant 3 has Invoices 1004 (3800) and 1005 (3800) = 7600 totalBilled,
    // and active payment p1Id (1800) (plus cancelled payments 5004 & p2Id which are excluded)
    final statement = await tenantsUseCase.getStatement(3);
    expect(statement.totalBilled, equals(7600));
    expect(statement.totalPaid, equals(1800));
    expect(statement.remainingBalance, equals(5800));
    expect(statement.ledger.length, greaterThanOrEqualTo(4));
  });

  test(
      '6. Local Backup & Restore and PDF Receipt Generation (FR-13 & Section 17)',
      () async {
    await DatabaseSeeder.seedIfEmpty(appDb.db);

    // 6.1 Export backup to local file
    final backupFile = await backupDataSource.exportBackupToFile(
      customDirectoryPath: tempDir.path,
      customFileName: 'ejary_backup_test.json',
    );
    expect(await backupFile.exists(), isTrue);

    // Modify database (add a new zone)
    await zonesUseCase.addZone(
      const ZoneEntity(
        id: 0,
        name: 'منطقة مؤقتة قبل الاستعادة',
        description: '',
        createdAt: '2026-11-20',
      ),
    );
    expect((await zonesUseCase.getZones()).length, equals(4));

    // Restore from backupFile and verify automatic safety backup was created
    // and database state returned to exact snapshot (3 zones)
    final safetyFile = await backupDataSource.restoreFromBackupFile(
      backupFile,
      safetyBackupDirectoryPath: tempDir.path,
    );
    expect(await safetyFile.exists(), isTrue);
    expect((await zonesUseCase.getZones()).length, equals(3));

    // Verify Dashboard summary works after restore
    final dash = await dashboardDataSource.loadDashboardData(
      currentMonth: '2026-11',
    );
    expect(dash.summary.totalProperties, equals(3));
    expect(dash.summary.totalApartments, equals(6));

    // 6.2 Generate local PDF receipt file (FR-13)
    const pdfService = ReceiptPdfService();
    final pdfFile = await pdfService.exportReceiptPdfToFile(
      const ReceiptPdfData(
        paymentId: 5001,
        receiptNumber: 'RCP-5001',
        ownerName: 'Ahmad Al-Mansour',
        ownerPhone: '+966501234567',
        tenantName: 'Khalid Al-Otaibi',
        propertyName: 'Al-Narjis Complex',
        apartmentNumber: 'A-101',
        contractNumber: 'CNT-2026-001',
        billingMonth: '2026-10',
        paymentDate: '2026-10-04',
        paidAmount: 2750,
        invoiceTotalAmount: 2750,
        remainingAmount: 0,
        paymentMethod: 'Bank Transfer',
        paymentRef: 'TRX-998811',
        notes: 'October Rent',
        currency: 'YER',
      ),
      customDirectoryPath: tempDir.path,
    );
    expect(await pdfFile.exists(), isTrue);
    final pdfBytes = await pdfFile.readAsBytes();
    expect(pdfBytes.length, greaterThan(500));
    expect(String.fromCharCodes(pdfBytes.take(4)), equals('%PDF'));
  });
}
