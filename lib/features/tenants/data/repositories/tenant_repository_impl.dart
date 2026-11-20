import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../contracts/data/models/contract_model.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_statement_entity.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../models/tenant_model.dart';

class TenantRepositoryImpl implements TenantRepository {
  final AppDatabase _appDb;

  TenantRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<TenantEntity>> getAllTenants({String? searchQuery}) async {
    final q = searchQuery?.trim() ?? '';
    final rows = await _db.query(
      DatabaseTables.tenants,
      where: q.isEmpty
          ? null
          : 'full_name LIKE ? OR phone LIKE ? OR national_id LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%'],
      orderBy: 'id DESC',
    );
    return rows.map(TenantModel.fromMap).toList();
  }

  @override
  Future<TenantEntity?> getTenantById(int id) async {
    final rows = await _db.query(
      DatabaseTables.tenants,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TenantModel.fromMap(rows.first);
  }

  @override
  Future<int> addTenant(TenantEntity tenant) async {
    final model = TenantModel(
      id: 0,
      fullName: tenant.fullName.trim(),
      phone: tenant.phone.trim(),
      nationalId: tenant.nationalId.trim(),
      notes: tenant.notes.trim(),
      createdAt: tenant.createdAt,
    );
    return _db.insert(
      DatabaseTables.tenants,
      model.toMap(includeId: false),
    );
  }

  @override
  Future<void> updateTenant(TenantEntity tenant) async {
    final model = TenantModel(
      id: tenant.id,
      fullName: tenant.fullName.trim(),
      phone: tenant.phone.trim(),
      nationalId: tenant.nationalId.trim(),
      notes: tenant.notes.trim(),
      createdAt: tenant.createdAt,
    );
    await _db.update(
      DatabaseTables.tenants,
      model.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  @override
  Future<void> deleteTenant(int id) async {
    final cntCount = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.contracts} WHERE tenant_id = ?',
            [id],
          ),
        ) ??
        0;
    if (cntCount > 0) {
      throw const DataIntegrityException(
        'Cannot delete tenant that has linked contracts.',
      );
    }
    await _db.delete(
      DatabaseTables.tenants,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<TenantStatementEntity> getTenantStatement(int tenantId) async {
    final tenant = await getTenantById(tenantId);
    if (tenant == null) {
      throw const NotFoundException('Tenant not found');
    }

    final contractRows = await _db.query(
      DatabaseTables.contracts,
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      orderBy: 'started_at DESC',
    );
    final contracts = contractRows.map(ContractModel.fromMap).toList();

    if (contracts.isEmpty) {
      return TenantStatementEntity(
        tenant: tenant,
        contracts: const [],
        invoices: const [],
        payments: const [],
        totalBilled: 0,
        totalPaid: 0,
        totalOverdue: 0,
        remainingBalance: 0,
        ledger: const [],
      );
    }

    final contractIds = contracts.map((c) => c.id).toList();
    final placeholders = List.filled(contractIds.length, '?').join(',');

    final invoiceRows = await _db.rawQuery(
      'SELECT * FROM ${DatabaseTables.invoices} WHERE contract_id IN ($placeholders) ORDER BY billing_month DESC, id DESC',
      contractIds,
    );
    final invoices = invoiceRows.map(InvoiceModel.fromMap).toList();

    final paymentRows = await _db.rawQuery(
      'SELECT * FROM ${DatabaseTables.payments} WHERE contract_id IN ($placeholders) ORDER BY pay_at DESC, id DESC',
      contractIds,
    );
    final payments = paymentRows.map(PaymentModel.fromMap).toList();

    final activeInvoices =
        invoices.where((i) => i.status != 'Cancelled').toList();
    final totalBilled = activeInvoices.fold<num>(
      0,
      (sum, i) => sum + i.totalAmount,
    );
    final totalPaid = payments
        .where((p) => !p.isCancelled)
        .fold<num>(0, (sum, p) => sum + p.amount);
    final totalOverdue = activeInvoices
        .where((i) => i.status == 'Overdue')
        .fold<num>(0, (sum, i) => sum + i.remainingAmount);
    final remainingBalance = totalBilled - totalPaid;

    final ledger = <TenantLedgerEntry>[
      for (final inv in activeInvoices)
        TenantLedgerEntry(
          date: inv.dueDate,
          type: 'INVOICE',
          title: 'Invoice (${inv.billingMonth})',
          amount: inv.totalAmount,
          status: inv.status,
          isDebit: true,
          referenceId: inv.id,
        ),
      for (final pay in payments)
        TenantLedgerEntry(
          date: pay.payAt,
          type: 'PAYMENT',
          title: 'Payment (${pay.payRef})',
          amount: pay.amount,
          status: pay.payMethod,
          isDebit: false,
          isCancelled: pay.isCancelled,
          referenceId: pay.id,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return TenantStatementEntity(
      tenant: tenant,
      contracts: contracts,
      invoices: invoices,
      payments: payments,
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      totalOverdue: totalOverdue,
      remainingBalance: remainingBalance,
      ledger: ledger,
    );
  }
}
