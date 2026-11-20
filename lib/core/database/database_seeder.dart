import 'package:sqflite/sqflite.dart';
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
import 'database_tables.dart';

/// Manages optional / test-environment seeding according to Section 3 policy:
/// - Production starts with an empty database so the owner enters real data.
/// - Test environment (or explicit user request in Settings/Demo button) can seed
///   realistic interconnected Arabic data.
/// - Never seeds more than once and never overwrites or deletes existing owner data.
class DatabaseSeeder {
  DatabaseSeeder._();

  static const String seedMetadataKey = 'seed_data_loaded';

  static const List<ZoneEntity> seedZones = [
    ZoneEntity(
      id: 1,
      name: 'حي النرجس - شمال الرياض',
      description: 'منطقة سكنية وتجارية حديثة شمال المدينة',
      createdAt: '2026-01-10',
    ),
    ZoneEntity(
      id: 2,
      name: 'حي الملقا - طريق الملك فهد',
      description: 'منطقة أبراج ومجمعات سكنية راقية',
      createdAt: '2026-01-15',
    ),
    ZoneEntity(
      id: 3,
      name: 'حي العليا التجاري',
      description: 'منطقة مكاتب ومعارض تجارية وشقق مكتبية',
      createdAt: '2026-02-01',
    ),
  ];

  static const List<PropertyEntity> seedProperties = [
    PropertyEntity(
      id: 1,
      name: 'مجمع النرجس السكني',
      description: 'عمارة سكنية مكونة من 3 طوابق و6 شقق عائلية مع مواقف خاصة',
      status: 'active',
      type: 'residential',
      zoneId: 1,
      longitude: 46.6753,
      latitude: 24.8136,
      createdAt: '2026-01-12',
    ),
    PropertyEntity(
      id: 2,
      name: 'برج الملقا للأعمال والسكن',
      description: 'مبنى مختلط يحتوي على شقق فاخرة ووحدات تجارية',
      status: 'active',
      type: 'mixed',
      zoneId: 2,
      longitude: 46.6120,
      latitude: 24.7945,
      createdAt: '2026-01-20',
    ),
    PropertyEntity(
      id: 3,
      name: 'مجمع العليا التجاري',
      description: 'مبنى تجاري يخضع حالياً لصيانة الواجهة والمصاعد',
      status: 'maintenance',
      type: 'commercial',
      zoneId: 3,
      longitude: 46.6850,
      latitude: 24.6950,
      createdAt: '2026-02-05',
    ),
  ];

  static const List<ServiceEntity> seedServices = [
    ServiceEntity(
      id: 1,
      name: 'المياه',
      description: 'رسوم استهلاك المياه الشهرية الموحدة للشقة',
      defaultPrice: 100,
      billingType: 'fixed_monthly',
      isActive: true,
      createdAt: '2026-01-01',
    ),
    ServiceEntity(
      id: 2,
      name: 'النظافة والحراسة',
      description: 'نظافة المداخل والدرج والحراسة الأمنية للمبنى',
      defaultPrice: 150,
      billingType: 'fixed_monthly',
      isActive: true,
      createdAt: '2026-01-01',
    ),
    ServiceEntity(
      id: 3,
      name: 'صيانة المصعد',
      description: 'اشتراك صيانة وتشغيل المصاعد',
      defaultPrice: 80,
      billingType: 'fixed_monthly',
      isActive: true,
      createdAt: '2026-01-01',
    ),
    ServiceEntity(
      id: 4,
      name: 'الإنترنت المشترك (فايبر)',
      description: 'خدمة الألياف البصرية عالية السرعة للمبنى',
      defaultPrice: 200,
      billingType: 'fixed_monthly',
      isActive: true,
      createdAt: '2026-01-01',
    ),
    ServiceEntity(
      id: 5,
      name: 'الكهرباء الإضافية / المولد',
      description: 'تُحتسب حسب الاستخدام الفعلي عند الحاجة',
      defaultPrice: 120,
      billingType: 'usage_based',
      isActive: true,
      createdAt: '2026-01-01',
    ),
  ];

  static const List<ApartmentEntity> seedApartments = [
    ApartmentEntity(
      id: 101,
      propertyId: 1,
      apartmentNumber: 'A-101',
      floor: 1,
      roomsCount: 4,
      baseRent: 2500,
      status: 'rented',
      notes: 'شقة زاوية مطلة على الشارع الرئيسي - مجددة بالكامل',
      createdAt: '2026-01-12',
    ),
    ApartmentEntity(
      id: 102,
      propertyId: 1,
      apartmentNumber: 'A-102',
      floor: 1,
      roomsCount: 3,
      baseRent: 2200,
      status: 'vacant',
      notes: 'جاهزة للتأجير الفوري مع مطبخ راكب',
      createdAt: '2026-01-12',
    ),
    ApartmentEntity(
      id: 103,
      propertyId: 1,
      apartmentNumber: 'A-201',
      floor: 2,
      roomsCount: 5,
      baseRent: 2800,
      status: 'rented',
      notes: 'شقة عائلية كبيرة مع غرفة خادمة',
      createdAt: '2026-01-12',
    ),
    ApartmentEntity(
      id: 201,
      propertyId: 2,
      apartmentNumber: 'B-101',
      floor: 1,
      roomsCount: 4,
      baseRent: 3500,
      status: 'rented',
      notes: 'وحدة سكنية فاخرة - برج الملقا',
      createdAt: '2026-01-20',
    ),
    ApartmentEntity(
      id: 202,
      propertyId: 2,
      apartmentNumber: 'B-202',
      floor: 2,
      roomsCount: 2,
      baseRent: 2000,
      status: 'vacant',
      notes: 'استوديو تنفيذي شاغر',
      createdAt: '2026-01-20',
    ),
    ApartmentEntity(
      id: 301,
      propertyId: 3,
      apartmentNumber: 'C-01',
      floor: 0,
      roomsCount: 3,
      baseRent: 4500,
      status: 'maintenance',
      notes: 'تحت صيانة التكييف المركزي والدهانات',
      createdAt: '2026-02-05',
    ),
  ];

  static const List<ApartmentServiceEntity> seedApartmentServices = [
    ApartmentServiceEntity(
      id: 1,
      apartmentId: 101,
      serviceId: 1,
      customPrice: 100,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'سعر المياه للشقة A-101',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 2,
      apartmentId: 101,
      serviceId: 2,
      customPrice: 150,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'نظافة وحراسة',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 3,
      apartmentId: 102,
      serviceId: 1,
      customPrice: 90,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'سعر مخصص مخفض للشقة A-102',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 4,
      apartmentId: 102,
      serviceId: 2,
      customPrice: 150,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'نظافة وحراسة',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 5,
      apartmentId: 103,
      serviceId: 1,
      customPrice: 120,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'شقة 5 غرف',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 6,
      apartmentId: 103,
      serviceId: 3,
      customPrice: 80,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'مصعد الطابق الثاني',
      createdAt: '2026-01-12',
    ),
    ApartmentServiceEntity(
      id: 7,
      apartmentId: 201,
      serviceId: 1,
      customPrice: 100,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'مياه',
      createdAt: '2026-01-20',
    ),
    ApartmentServiceEntity(
      id: 8,
      apartmentId: 201,
      serviceId: 4,
      customPrice: 200,
      billingType: 'fixed_monthly',
      isActive: true,
      notes: 'إنترنت فايبر',
      createdAt: '2026-01-20',
    ),
  ];

  static const List<TenantEntity> seedTenants = [
    TenantEntity(
      id: 1,
      fullName: 'خالد بن عبد الله العتيبي',
      phone: '+966 55 234 8899',
      nationalId: '1045892310',
      notes: 'مستأجر منتظم في السداد منذ بداية العقد',
      createdAt: '2026-01-15',
    ),
    TenantEntity(
      id: 2,
      fullName: 'فهد بن سلطان الدوسري',
      phone: '+966 54 987 1122',
      nationalId: '1087654321',
      notes: 'يفضل السداد عبر التحويل البنكي مطلع كل شهر',
      createdAt: '2026-02-01',
    ),
    TenantEntity(
      id: 3,
      fullName: 'عمر بن ياسر الحربي',
      phone: '+966 50 776 3344',
      nationalId: '1099887766',
      notes: 'لديه عقد قريب من الانتهاء ويحتاج تواصل للتجديد',
      createdAt: '2025-12-10',
    ),
    TenantEntity(
      id: 4,
      fullName: 'سعد بن إبراهيم القحطاني',
      phone: '+966 56 111 2233',
      nationalId: '1022334455',
      notes: 'مستأجر سابق تم إنهاء عقده وتسوية حسابه',
      createdAt: '2025-05-01',
    ),
  ];

  static const List<ContractEntity> seedContracts = [
    ContractEntity(
      id: 1,
      contractNumber: 'CNT-2026-001',
      apartmentId: 101,
      tenantId: 1,
      startedAt: '2026-01-01',
      endAt: '2026-12-31',
      createdAt: '2025-12-28',
      price: 2500,
      totalServices: 250,
      conditionsJson:
          '["الالتزام بسداد الإيجار في اليوم الخامس من كل شهر","عدم إجراء تعديلات إنشائية دون موافقة خطية من المالك","المحافظة على المرافق المشتركة"]',
      dueDate: '2026-11-05',
      dueDay: 5,
      rentalAt: '2026-01-01',
      autoRenew: true,
      status: 'active',
      notes: 'عقد سنوي بسداد شهري',
      renewalOfContractId: null,
    ),
    ContractEntity(
      id: 2,
      contractNumber: 'CNT-2026-002',
      apartmentId: 103,
      tenantId: 2,
      startedAt: '2026-03-01',
      endAt: '2027-02-28',
      createdAt: '2026-02-25',
      price: 2800,
      totalServices: 200,
      conditionsJson:
          '["السداد شهرياً عبر الحساب البنكي المعتمد","يتحمل المستأجر فواتير الكهرباء المستقلة"]',
      dueDate: '2026-11-01',
      dueDay: 1,
      rentalAt: '2026-03-01',
      autoRenew: true,
      status: 'active',
      notes: 'شقة الطابق الثاني العائلية',
      renewalOfContractId: null,
    ),
    ContractEntity(
      id: 3,
      contractNumber: 'CNT-2025-019',
      apartmentId: 201,
      tenantId: 3,
      startedAt: '2025-12-01',
      endAt: '2026-11-30',
      createdAt: '2025-11-25',
      price: 3500,
      totalServices: 300,
      conditionsJson:
          '["إشعار المالك قبل 30 يوماً في حال عدم الرغبة في التجديد","الالتزام بلوائح برج الملقا"]',
      dueDate: '2026-11-01',
      dueDay: 1,
      rentalAt: '2025-12-01',
      autoRenew: true,
      status: 'expiring',
      notes: 'ينتهي خلال 10 أيام - مقترح للتجديد',
      renewalOfContractId: null,
    ),
    ContractEntity(
      id: 4,
      contractNumber: 'CNT-2025-004',
      apartmentId: 102,
      tenantId: 4,
      startedAt: '2025-01-01',
      endAt: '2025-12-31',
      createdAt: '2024-12-20',
      price: 2100,
      totalServices: 200,
      conditionsJson: '["عقد سابق منتهي"]',
      dueDate: '2025-12-01',
      dueDay: 1,
      rentalAt: '2025-01-01',
      autoRenew: false,
      status: 'expired',
      notes: 'عقد تاريخي مكتمل',
      renewalOfContractId: null,
    ),
  ];

  static const List<ContractServiceEntity> seedContractServices = [
    ContractServiceEntity(
      id: 1,
      contractId: 1,
      serviceId: 1,
      serviceName: 'المياه',
      price: 100,
      billingType: 'fixed_monthly',
      createdAt: '2025-12-28',
    ),
    ContractServiceEntity(
      id: 2,
      contractId: 1,
      serviceId: 2,
      serviceName: 'النظافة والحراسة',
      price: 150,
      billingType: 'fixed_monthly',
      createdAt: '2025-12-28',
    ),
    ContractServiceEntity(
      id: 3,
      contractId: 2,
      serviceId: 1,
      serviceName: 'المياه',
      price: 120,
      billingType: 'fixed_monthly',
      createdAt: '2026-02-25',
    ),
    ContractServiceEntity(
      id: 4,
      contractId: 2,
      serviceId: 3,
      serviceName: 'صيانة المصعد',
      price: 80,
      billingType: 'fixed_monthly',
      createdAt: '2026-02-25',
    ),
    ContractServiceEntity(
      id: 5,
      contractId: 3,
      serviceId: 1,
      serviceName: 'المياه',
      price: 100,
      billingType: 'fixed_monthly',
      createdAt: '2025-11-25',
    ),
    ContractServiceEntity(
      id: 6,
      contractId: 3,
      serviceId: 4,
      serviceName: 'الإنترنت المشترك (فايبر)',
      price: 200,
      billingType: 'fixed_monthly',
      createdAt: '2025-11-25',
    ),
  ];

  static const List<InvoiceEntity> seedInvoices = [
    InvoiceEntity(
      id: 1001,
      contractId: 1,
      billingMonth: '2026-10',
      dueDate: '2026-10-05',
      baseRent: 2500,
      servicesTotal: 250,
      totalAmount: 2750,
      paidAmount: 2750,
      remainingAmount: 0,
      status: 'Paid',
      createdAt: '2026-10-01',
    ),
    InvoiceEntity(
      id: 1002,
      contractId: 1,
      billingMonth: '2026-11',
      dueDate: '2026-11-05',
      baseRent: 2500,
      servicesTotal: 250,
      totalAmount: 2750,
      paidAmount: 2750,
      remainingAmount: 0,
      status: 'Paid',
      createdAt: '2026-11-01',
    ),
    InvoiceEntity(
      id: 1003,
      contractId: 2,
      billingMonth: '2026-11',
      dueDate: '2026-11-01',
      baseRent: 2800,
      servicesTotal: 200,
      totalAmount: 3000,
      paidAmount: 1500,
      remainingAmount: 1500,
      status: 'Partially Paid',
      createdAt: '2026-11-01',
    ),
    InvoiceEntity(
      id: 1004,
      contractId: 3,
      billingMonth: '2026-10',
      dueDate: '2026-10-01',
      baseRent: 3500,
      servicesTotal: 300,
      totalAmount: 3800,
      paidAmount: 0,
      remainingAmount: 3800,
      status: 'Overdue',
      createdAt: '2026-10-01',
    ),
    InvoiceEntity(
      id: 1005,
      contractId: 3,
      billingMonth: '2026-11',
      dueDate: '2026-11-25',
      baseRent: 3500,
      servicesTotal: 300,
      totalAmount: 3800,
      paidAmount: 0,
      remainingAmount: 3800,
      status: 'Pending',
      createdAt: '2026-11-01',
    ),
  ];

  static const List<PaymentEntity> seedPayments = [
    PaymentEntity(
      id: 5001,
      contractId: 1,
      invoiceId: 1001,
      type: 'full',
      payAt: '2026-10-04',
      amount: 2750,
      payMethod: 'bank',
      payRef: 'TRX-998811',
      billingMonth: '2026-10',
      notes: 'تحويل بنكي كامل عن شهر أكتوبر',
      createdAt: '2026-10-04',
    ),
    PaymentEntity(
      id: 5002,
      contractId: 1,
      invoiceId: 1002,
      type: 'full',
      payAt: '2026-11-04',
      amount: 2750,
      payMethod: 'bank',
      payRef: 'TRX-998950',
      billingMonth: '2026-11',
      notes: 'تحويل بنكي كامل عن شهر نوفمبر',
      createdAt: '2026-11-04',
    ),
    PaymentEntity(
      id: 5003,
      contractId: 2,
      invoiceId: 1003,
      type: 'partial',
      payAt: '2026-11-03',
      amount: 1500,
      payMethod: 'cash',
      payRef: 'CSH-2026-11',
      billingMonth: '2026-11',
      notes: 'دفعة أولى نقدية والباقي منتصف الشهر',
      createdAt: '2026-11-03',
    ),
    PaymentEntity(
      id: 5004,
      contractId: 3,
      invoiceId: 1004,
      type: 'partial',
      payAt: '2026-10-10',
      amount: 1000,
      payMethod: 'remittance',
      payRef: 'ERR-VOID-01',
      billingMonth: '2026-10',
      notes: 'دفعة ملغاة بسبب خطأ في رقم الحوالة - محفوظة كسجل تدقيق فقط',
      createdAt: '2026-10-10',
      isCancelled: true,
    ),
  ];

  static Future<bool> isSeeded(DatabaseExecutor db) async {
    final rows = await db.query(
      DatabaseTables.appMetadata,
      where: 'key = ?',
      whereArgs: [seedMetadataKey],
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  static Future<bool> hasAnyOperationalData(DatabaseExecutor db) async {
    final propCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.properties}',
          ),
        ) ??
        0;
    final tenantCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tenants}'),
        ) ??
        0;
    final zoneCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.zones}'),
        ) ??
        0;
    return propCount > 0 || tenantCount > 0 || zoneCount > 0;
  }

  /// Seeds the database atomically inside a transaction ONLY if not already seeded
  /// and if no operational records exist. Returns true if seed data was inserted.
  static Future<bool> seedIfEmpty(
    Database db, {
    bool forceIfFlagUnset = false,
  }) async {
    if (!forceIfFlagUnset && await isSeeded(db)) {
      return false;
    }
    if (await hasAnyOperationalData(db)) {
      return false;
    }

    await db.transaction((txn) async {
      for (final z in seedZones) {
        await txn.insert(DatabaseTables.zones, {
          'id': z.id,
          'name': z.name,
          'description': z.description,
          'created_at': z.createdAt,
        });
      }

      for (final p in seedProperties) {
        await txn.insert(DatabaseTables.properties, {
          'id': p.id,
          'name': p.name,
          'description': p.description,
          'status': p.status,
          'type': p.type,
          'zone_id': p.zoneId,
          'longitude': p.longitude,
          'latitude': p.latitude,
          'created_at': p.createdAt,
        });
      }

      for (final s in seedServices) {
        await txn.insert(DatabaseTables.services, {
          'id': s.id,
          'name': s.name,
          'description': s.description,
          'default_price': s.defaultPrice.round(),
          'billing_type': s.billingType,
          'is_active': s.isActive ? 1 : 0,
          'created_at': s.createdAt,
        });
      }

      for (final a in seedApartments) {
        await txn.insert(DatabaseTables.apartments, {
          'id': a.id,
          'property_id': a.propertyId,
          'apartment_number': a.apartmentNumber,
          'floor': a.floor,
          'rooms_count': a.roomsCount,
          'base_rent': a.baseRent.round(),
          'status': a.status,
          'notes': a.notes,
          'created_at': a.createdAt,
        });
      }

      for (final asrv in seedApartmentServices) {
        await txn.insert(DatabaseTables.apartmentServices, {
          'id': asrv.id,
          'apartment_id': asrv.apartmentId,
          'service_id': asrv.serviceId,
          'custom_price': asrv.customPrice.round(),
          'billing_type': asrv.billingType,
          'is_active': asrv.isActive ? 1 : 0,
          'notes': asrv.notes,
          'created_at': asrv.createdAt,
        });
      }

      for (final t in seedTenants) {
        await txn.insert(DatabaseTables.tenants, {
          'id': t.id,
          'full_name': t.fullName,
          'phone': t.phone,
          'national_id': t.nationalId,
          'notes': t.notes,
          'created_at': t.createdAt,
        });
      }

      for (final c in seedContracts) {
        await txn.insert(DatabaseTables.contracts, {
          'id': c.id,
          'contract_number': c.contractNumber,
          'apartment_id': c.apartmentId,
          'tenant_id': c.tenantId,
          'started_at': c.startedAt,
          'end_at': c.endAt,
          'created_at': c.createdAt,
          'price': c.price.round(),
          'total_services': c.totalServices.round(),
          'conditions_json': c.conditionsJson,
          'due_date': c.dueDate,
          'due_day': c.dueDay,
          'rental_at': c.rentalAt,
          'auto_renew': c.autoRenew ? 1 : 0,
          'status': c.status,
          'notes': c.notes,
          'renewal_of_contract_id': c.renewalOfContractId,
        });
      }

      for (final cs in seedContractServices) {
        await txn.insert(DatabaseTables.contractServices, {
          'id': cs.id,
          'contract_id': cs.contractId,
          'service_id': cs.serviceId,
          'service_name': cs.serviceName,
          'price': cs.price.round(),
          'billing_type': cs.billingType,
          'created_at': cs.createdAt,
        });
      }

      for (final inv in seedInvoices) {
        await txn.insert(DatabaseTables.invoices, {
          'id': inv.id,
          'contract_id': inv.contractId,
          'billing_month': inv.billingMonth,
          'due_date': inv.dueDate,
          'base_rent': inv.baseRent.round(),
          'services_total': inv.servicesTotal.round(),
          'total_amount': inv.totalAmount.round(),
          'paid_amount': inv.paidAmount.round(),
          'remaining_amount': inv.remainingAmount.round(),
          'status': inv.status,
          'created_at': inv.createdAt,
        });
      }

      for (final pay in seedPayments) {
        await txn.insert(DatabaseTables.payments, {
          'id': pay.id,
          'contract_id': pay.contractId,
          'invoice_id': pay.invoiceId,
          'type': pay.type,
          'pay_at': pay.payAt,
          'amount': pay.amount.round(),
          'pay_method': pay.payMethod,
          'pay_ref': pay.payRef,
          'billing_month': pay.billingMonth,
          'notes': pay.notes,
          'is_cancelled': pay.isCancelled ? 1 : 0,
          'created_at': pay.createdAt,
        });
      }

      await txn.insert(
        DatabaseTables.appMetadata,
        {
          'key': seedMetadataKey,
          'value': '1',
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return true;
  }
}
