import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../contracts/data/models/contract_model.dart';
import '../../../contracts/data/repositories/contract_repository_impl.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final AppDatabase _appDb;

  InvoiceRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<InvoiceEntity>> getAllInvoices({
    String? status,
    String? billingMonth,
    int? propertyId,
    int? apartmentId,
    int? tenantId,
    int? contractId,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (status != null && status.isNotEmpty && status != 'all') {
      whereClauses.add('inv.status = ?');
      args.add(status);
    }
    if (billingMonth != null &&
        billingMonth.isNotEmpty &&
        billingMonth != 'all') {
      whereClauses.add('inv.billing_month = ?');
      args.add(billingMonth);
    }
    if (contractId != null && contractId > 0) {
      whereClauses.add('inv.contract_id = ?');
      args.add(contractId);
    }
    if (tenantId != null && tenantId > 0) {
      whereClauses.add('c.tenant_id = ?');
      args.add(tenantId);
    }
    if (apartmentId != null && apartmentId > 0) {
      whereClauses.add('c.apartment_id = ?');
      args.add(apartmentId);
    }
    if (propertyId != null && propertyId > 0) {
      whereClauses.add('a.property_id = ?');
      args.add(propertyId);
    }

    final whereSql =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final rows = await _db.rawQuery('''
      SELECT inv.*
      FROM ${DatabaseTables.invoices} inv
      INNER JOIN ${DatabaseTables.contracts} c ON c.id = inv.contract_id
      INNER JOIN ${DatabaseTables.apartments} a ON a.id = c.apartment_id
      $whereSql
      ORDER BY inv.billing_month DESC, inv.id DESC
    ''', args);

    return rows.map(InvoiceModel.fromMap).toList();
  }

  @override
  Future<InvoiceEntity?> getInvoiceById(int id) async {
    final rows = await _db.query(
      DatabaseTables.invoices,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return InvoiceModel.fromMap(rows.first);
  }

  @override
  Future<int> generateMonthlyInvoices(
    String billingMonth, {
    String? referenceTodayIso,
  }) async {
    final regex = RegExp(r'^\d{4}-\d{2}$');
    if (!regex.hasMatch(billingMonth)) {
      throw const ValidationException(
        'Billing month must be in YYYY-MM format.',
      );
    }

    final todayIso =
        referenceTodayIso ?? DateTime.now().toIso8601String().substring(0, 10);
    final currentMonth = todayIso.substring(0, 7);

    // FR-10 Rule 8: Prevent generating unbounded future invoices (> 1 month ahead)
    final targetParts = billingMonth.split('-');
    final curParts = currentMonth.split('-');
    final targetMonthsTotal =
        int.parse(targetParts[0]) * 12 + int.parse(targetParts[1]);
    final curMonthsTotal =
        int.parse(curParts[0]) * 12 + int.parse(curParts[1]);
    if (targetMonthsTotal > curMonthsTotal + 1) {
      throw const ValidationException(
        'Cannot generate unbounded future invoices beyond next billing month.',
      );
    }

    return _db.transaction<int>((txn) async {
      int createdCount = 0;

      // Get all active or expiring contracts
      final contractRows = await txn.query(
        DatabaseTables.contracts,
        where: "status IN ('active', 'expiring')",
      );

      for (final row in contractRows) {
        final contract = ContractModel.fromMap(row);
        final contractStartMonth = contract.startedAt.substring(0, 7);
        final contractEndMonth = contract.endAt.substring(0, 7);

        // FR-10 Rule 2 & 3: Do not generate invoices outside the contract's start..end period
        if (billingMonth.compareTo(contractStartMonth) < 0 ||
            billingMonth.compareTo(contractEndMonth) > 0) {
          continue;
        }

        // FR-10 Rule 1 & 7: Idempotent check — do not duplicate invoice for same contract and month
        final existing = await txn.query(
          DatabaseTables.invoices,
          where: 'contract_id = ? AND billing_month = ?',
          whereArgs: [contract.id, billingMonth],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        // FR-09: Calculate monthly services total from historical contract_services snapshot
        final srvSumRows = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(price), 0) AS srv_total
          FROM ${DatabaseTables.contractServices}
          WHERE contract_id = ? AND billing_type = 'fixed_monthly'
        ''',
          [contract.id],
        );
        final servicesTotal =
            (srvSumRows.first['srv_total'] as num?)?.round() ??
                contract.totalServices.round();

        final baseRent = contract.price.round();
        final totalAmount = baseRent + servicesTotal;

        // FR-10 Rule 4: Accurate due date in months with 28/29/30/31 days
        final dueDate = ContractRepositoryImpl.calculateAccurateDueDate(
          billingMonth,
          contract.dueDay,
        );

        // FR-10 Rule 5: Set initial status based on dueDate vs today
        final initialStatus =
            dueDate.compareTo(todayIso) < 0 ? 'Overdue' : 'Pending';

        await txn.insert(
          DatabaseTables.invoices,
          {
            'contract_id': contract.id,
            'billing_month': billingMonth,
            'due_date': dueDate,
            'base_rent': baseRent,
            'services_total': servicesTotal,
            'total_amount': totalAmount,
            'paid_amount': 0,
            'remaining_amount': totalAmount,
            'status': initialStatus,
            'created_at': todayIso,
          },
        );
        createdCount++;
      }

      return createdCount;
    });
  }

  @override
  Future<int> refreshOverdueStatuses({String? referenceTodayIso}) async {
    final todayIso =
        referenceTodayIso ?? DateTime.now().toIso8601String().substring(0, 10);
    return _db.rawUpdate('''
      UPDATE ${DatabaseTables.invoices}
      SET status = 'Overdue'
      WHERE status = 'Pending'
        AND remaining_amount > 0
        AND paid_amount = 0
        AND due_date < ?
    ''', [todayIso]);
  }
}
