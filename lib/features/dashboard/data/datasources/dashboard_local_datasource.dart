import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../apartments/data/models/apartment_model.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../../contracts/data/models/contract_model.dart';
import '../../../contracts/domain/entities/contract_entity.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/domain/entities/invoice_entity.dart';
import '../../domain/entities/dashboard_summary_entity.dart';

class DashboardFullData {
  final DashboardSummaryEntity summary;
  final List<InvoiceEntity> overdueInvoices;
  final List<ContractEntity> expiringContracts;
  final List<InvoiceEntity> upcomingInvoices;
  final List<ApartmentEntity> maintenanceApartments;
  final Map<String, num> monthlyCollectionsLast6M;
  final num totalBilledAllTime;
  final num totalPaidAllTime;

  const DashboardFullData({
    required this.summary,
    required this.overdueInvoices,
    required this.expiringContracts,
    required this.upcomingInvoices,
    required this.maintenanceApartments,
    required this.monthlyCollectionsLast6M,
    required this.totalBilledAllTime,
    required this.totalPaidAllTime,
  });
}

class DashboardLocalDataSource {
  final AppDatabase _appDb;

  const DashboardLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  Future<DashboardFullData> loadDashboardData({String? currentMonth}) async {
    final targetMonth =
        currentMonth ?? DateTime.now().toIso8601String().substring(0, 7);

    final totalProperties = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.properties}',
          ),
        ) ??
        0;

    final aptRows = await _db.query(DatabaseTables.apartments);
    final apartments = aptRows.map(ApartmentModel.fromMap).toList();
    final totalApartments = apartments.length;
    final rentedApartments =
        apartments.where((a) => a.status == 'rented').length;
    final vacantApartments =
        apartments.where((a) => a.status == 'vacant').length;
    final maintenanceAptsList =
        apartments.where((a) => a.status == 'maintenance').toList();

    final totalTenants = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tenants}'),
        ) ??
        0;

    final contractRows = await _db.query(
      DatabaseTables.contracts,
      where: "status IN ('active', 'expiring')",
    );
    final activeContractsList =
        contractRows.map(ContractModel.fromMap).toList();
    final expiringContractsList =
        activeContractsList.where((c) => c.status == 'expiring').toList();

    final expectedMonthlyRent = activeContractsList.fold<num>(
      0,
      (sum, c) => sum + c.monthlyTotal,
    );

    final invoiceRows = await _db.query(
      DatabaseTables.invoices,
      where: "status != 'Cancelled'",
      orderBy: 'due_date ASC',
    );
    final invoices = invoiceRows.map(InvoiceModel.fromMap).toList();

    final totalBilledAllTime =
        invoices.fold<num>(0, (sum, i) => sum + i.totalAmount);
    final totalPaidAllTime =
        invoices.fold<num>(0, (sum, i) => sum + i.paidAmount);
    final totalDues =
        invoices.fold<num>(0, (sum, i) => sum + i.remainingAmount);

    final overdueInvoices =
        invoices.where((i) => i.status == 'Overdue').toList();
    final totalOverdue =
        overdueInvoices.fold<num>(0, (sum, i) => sum + i.remainingAmount);

    final upcomingInvoices = invoices
        .where(
          (i) =>
              (i.status == 'Pending' || i.status == 'Partially Paid') &&
              i.remainingAmount > 0,
        )
        .toList();

    // Monthly collections from non-cancelled payments
    final paySumRows = await _db.rawQuery('''
      SELECT billing_month, COALESCE(SUM(amount), 0) AS collected
      FROM ${DatabaseTables.payments}
      WHERE is_cancelled = 0
      GROUP BY billing_month
      ORDER BY billing_month ASC
    ''');

    final collectionsByMonth = <String, num>{};
    for (final r in paySumRows) {
      final bm = r['billing_month'] as String;
      collectionsByMonth[bm] = (r['collected'] as num?) ?? 0;
    }

    final monthlyCollections = collectionsByMonth[targetMonth] ??
        invoices
            .where((i) => i.billingMonth == targetMonth)
            .fold<num>(0, (sum, i) => sum + i.paidAmount);

    final summary = DashboardSummaryEntity(
      totalProperties: totalProperties,
      totalApartments: totalApartments,
      rentedApartments: rentedApartments,
      vacantApartments: vacantApartments,
      maintenanceApartments: maintenanceAptsList.length,
      totalTenants: totalTenants,
      activeContracts: activeContractsList.length,
      expiringContracts: expiringContractsList.length,
      expectedMonthlyRent: expectedMonthlyRent,
      monthlyCollections: monthlyCollections,
      totalDues: totalDues,
      totalOverdue: totalOverdue,
    );

    return DashboardFullData(
      summary: summary,
      overdueInvoices: overdueInvoices,
      expiringContracts: expiringContractsList,
      upcomingInvoices: upcomingInvoices,
      maintenanceApartments: maintenanceAptsList,
      monthlyCollectionsLast6M: collectionsByMonth,
      totalBilledAllTime: totalBilledAllTime,
      totalPaidAllTime: totalPaidAllTime,
    );
  }
}
