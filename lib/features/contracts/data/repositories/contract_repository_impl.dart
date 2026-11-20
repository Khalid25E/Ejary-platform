import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../tenants/domain/entities/tenant_entity.dart';
import '../../domain/entities/contract_entity.dart';
import '../../domain/entities/contract_service_entity.dart';
import '../../domain/repositories/contract_repository.dart';
import '../models/contract_model.dart';
import '../models/contract_service_model.dart';

class ContractRepositoryImpl implements ContractRepository {
  final AppDatabase _appDb;

  ContractRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<ContractEntity>> getAllContracts({
    String? searchQuery,
    String? status,
    int? tenantId,
    int? apartmentId,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (status != null && status.isNotEmpty && status != 'all') {
      whereClauses.add('c.status = ?');
      args.add(status);
    }
    if (tenantId != null && tenantId > 0) {
      whereClauses.add('c.tenant_id = ?');
      args.add(tenantId);
    }
    if (apartmentId != null && apartmentId > 0) {
      whereClauses.add('c.apartment_id = ?');
      args.add(apartmentId);
    }

    final q = searchQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      whereClauses.add(
        '(c.contract_number LIKE ? OR t.full_name LIKE ? OR a.apartment_number LIKE ?)',
      );
      args.addAll(['%$q%', '%$q%', '%$q%']);
    }

    final whereSql =
        whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final rows = await _db.rawQuery('''
      SELECT c.*
      FROM ${DatabaseTables.contracts} c
      LEFT JOIN ${DatabaseTables.tenants} t ON t.id = c.tenant_id
      LEFT JOIN ${DatabaseTables.apartments} a ON a.id = c.apartment_id
      $whereSql
      ORDER BY c.id DESC
    ''', args);

    return rows.map(ContractModel.fromMap).toList();
  }

  @override
  Future<ContractEntity?> getContractById(int id) async {
    final rows = await _db.query(
      DatabaseTables.contracts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ContractModel.fromMap(rows.first);
  }

  @override
  Future<List<ContractServiceEntity>> getContractServices(
    int contractId,
  ) async {
    final rows = await _db.query(
      DatabaseTables.contractServices,
      where: 'contract_id = ?',
      whereArgs: [contractId],
      orderBy: 'id ASC',
    );
    return rows.map(ContractServiceModel.fromMap).toList();
  }

  @override
  Future<List<ContractServiceEntity>> getAllContractServices() async {
    final rows = await _db.query(
      DatabaseTables.contractServices,
      orderBy: 'contract_id ASC, id ASC',
    );
    return rows.map(ContractServiceModel.fromMap).toList();
  }

  /// Calculates accurate due date for a YYYY-MM billing month and dueDay (1..31).
  static String calculateAccurateDueDate(String billingMonth, int dueDay) {
    final parts = billingMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = dueDay.clamp(1, lastDayOfMonth);
    final mm = month.toString().padLeft(2, '0');
    final dd = clampedDay.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  @override
  Future<int> createContractAtomically({
    required ContractEntity contract,
    required List<ContractServiceEntity> servicesSnapshot,
    TenantEntity? inlineNewTenant,
  }) async {
    if (contract.endAt.compareTo(contract.startedAt) < 0) {
      throw const ValidationException(
        'Contract end date cannot be before start date.',
      );
    }

    return _db.transaction<int>((txn) async {
      // 1. Check for overlapping active/expiring contracts on the same apartment (FR-04 & Section 15)
      final conflictRows = await txn.rawQuery('''
        SELECT id, contract_number FROM ${DatabaseTables.contracts}
        WHERE apartment_id = ?
          AND status IN ('active', 'expiring')
          AND started_at <= ?
          AND end_at >= ?
      ''', [contract.apartmentId, contract.endAt, contract.startedAt]);

      if (conflictRows.isNotEmpty) {
        throw const DataIntegrityException(
          'Conflicting active contract exists for this apartment in the specified period.',
        );
      }

      // 2. If inline new tenant is provided, insert tenant inside the same transaction
      int targetTenantId = contract.tenantId;
      if (inlineNewTenant != null) {
        final tenantModel = TenantModel(
          id: 0,
          fullName: inlineNewTenant.fullName.trim(),
          phone: inlineNewTenant.phone.trim(),
          nationalId: inlineNewTenant.nationalId.trim(),
          notes: inlineNewTenant.notes.trim(),
          createdAt: inlineNewTenant.createdAt,
        );
        targetTenantId = await txn.insert(
          DatabaseTables.tenants,
          tenantModel.toMap(includeId: false),
        );
      }

      // 3. Calculate total fixed monthly services from snapshot
      final fixedServicesSum = servicesSnapshot
          .where((s) => s.billingType == 'fixed_monthly')
          .fold<num>(0, (sum, s) => sum + s.price);

      final startMonth = contract.startedAt.substring(0, 7);
      final computedDueDate =
          calculateAccurateDueDate(startMonth, contract.dueDay);

      final contractModel = ContractModel(
        id: 0,
        contractNumber: contract.contractNumber.trim(),
        apartmentId: contract.apartmentId,
        tenantId: targetTenantId,
        startedAt: contract.startedAt,
        endAt: contract.endAt,
        createdAt: contract.createdAt,
        price: contract.price,
        totalServices: fixedServicesSum,
        conditionsJson: contract.conditionsJson,
        dueDate: computedDueDate,
        dueDay: contract.dueDay,
        rentalAt: contract.rentalAt,
        autoRenew: contract.autoRenew,
        status: contract.status,
        notes: contract.notes,
        renewalOfContractId: contract.renewalOfContractId,
      );

      final newContractId = await txn.insert(
        DatabaseTables.contracts,
        contractModel.toMap(includeId: false),
      );

      // 4. Save historical contract_services snapshot (FR-09)
      for (final srv in servicesSnapshot) {
        final srvModel = ContractServiceModel(
          id: 0,
          contractId: newContractId,
          serviceId: srv.serviceId,
          serviceName: srv.serviceName,
          price: srv.price,
          billingType: srv.billingType,
          createdAt: contract.createdAt,
        );
        await txn.insert(
          DatabaseTables.contractServices,
          srvModel.toMap(includeId: false),
        );
      }

      // 5. Update Apartment status to 'rented'
      await txn.update(
        DatabaseTables.apartments,
        {'status': 'rented'},
        where: 'id = ?',
        whereArgs: [contract.apartmentId],
      );

      // 6. Prepare initial monthly invoice for the start month (FR-08 & FR-10)
      final totalAmount = contract.price.round() + fixedServicesSum.round();
      await txn.insert(
        DatabaseTables.invoices,
        {
          'contract_id': newContractId,
          'billing_month': startMonth,
          'due_date': computedDueDate,
          'base_rent': contract.price.round(),
          'services_total': fixedServicesSum.round(),
          'total_amount': totalAmount,
          'paid_amount': 0,
          'remaining_amount': totalAmount,
          'status': 'Pending',
          'created_at': contract.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return newContractId;
    });
  }

  @override
  Future<int> renewContractAtomically({
    required int oldContractId,
    required String newContractNumber,
    required String newStartDate,
    required String newEndDate,
    required num newBaseRent,
    required List<ContractServiceEntity> newServicesSnapshot,
    String? notes,
  }) async {
    if (newEndDate.compareTo(newStartDate) < 0) {
      throw const ValidationException(
        'Renewal end date cannot be before start date.',
      );
    }

    return _db.transaction<int>((txn) async {
      final oldRows = await txn.query(
        DatabaseTables.contracts,
        where: 'id = ?',
        whereArgs: [oldContractId],
        limit: 1,
      );
      if (oldRows.isEmpty) {
        throw const NotFoundException('Previous contract not found.');
      }
      final oldContract = ContractModel.fromMap(oldRows.first);

      // 1. Mark previous contract as 'expired' (keeping its history, invoices & payments intact)
      await txn.update(
        DatabaseTables.contracts,
        {'status': 'expired'},
        where: 'id = ?',
        whereArgs: [oldContractId],
      );

      // 2. Verify no other conflicting active contract exists on the apartment
      final conflicts = await txn.rawQuery('''
        SELECT id FROM ${DatabaseTables.contracts}
        WHERE apartment_id = ?
          AND id != ?
          AND status IN ('active', 'expiring')
          AND started_at <= ?
          AND end_at >= ?
      ''', [oldContract.apartmentId, oldContractId, newEndDate, newStartDate]);

      if (conflicts.isNotEmpty) {
        throw const DataIntegrityException(
          'Conflicting active contract exists on this apartment for the renewal period.',
        );
      }

      final fixedServicesSum = newServicesSnapshot
          .where((s) => s.billingType == 'fixed_monthly')
          .fold<num>(0, (sum, s) => sum + s.price);

      final startMonth = newStartDate.substring(0, 7);
      final dueDate =
          calculateAccurateDueDate(startMonth, oldContract.dueDay);
      final nowIso = DateTime.now().toIso8601String().substring(0, 10);

      final renewedModel = ContractModel(
        id: 0,
        contractNumber: newContractNumber.trim(),
        apartmentId: oldContract.apartmentId,
        tenantId: oldContract.tenantId,
        startedAt: newStartDate,
        endAt: newEndDate,
        createdAt: nowIso,
        price: newBaseRent,
        totalServices: fixedServicesSum,
        conditionsJson: oldContract.conditionsJson,
        dueDate: dueDate,
        dueDay: oldContract.dueDay,
        rentalAt: newStartDate,
        autoRenew: oldContract.autoRenew,
        status: 'active',
        notes: notes ?? 'Renewed from ${oldContract.contractNumber}',
        renewalOfContractId: oldContractId,
      );

      final newId = await txn.insert(
        DatabaseTables.contracts,
        renewedModel.toMap(includeId: false),
      );

      for (final srv in newServicesSnapshot) {
        final srvModel = ContractServiceModel(
          id: 0,
          contractId: newId,
          serviceId: srv.serviceId,
          serviceName: srv.serviceName,
          price: srv.price,
          billingType: srv.billingType,
          createdAt: nowIso,
        );
        await txn.insert(
          DatabaseTables.contractServices,
          srvModel.toMap(includeId: false),
        );
      }

      await txn.update(
        DatabaseTables.apartments,
        {'status': 'rented'},
        where: 'id = ?',
        whereArgs: [oldContract.apartmentId],
      );

      return newId;
    });
  }

  @override
  Future<void> terminateContractAtomically({
    required int contractId,
    required String terminationDate,
    required String terminationReason,
    required String nextApartmentStatus,
  }) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseTables.contracts,
        where: 'id = ?',
        whereArgs: [contractId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const NotFoundException('Contract not found.');
      }
      final cnt = ContractModel.fromMap(rows.first);

      // 1. Update contract status and record termination metadata (keeping all historical invoices & payments!)
      await txn.update(
        DatabaseTables.contracts,
        {
          'status': 'terminated',
          'termination_date': terminationDate,
          'termination_reason': terminationReason.trim(),
        },
        where: 'id = ?',
        whereArgs: [contractId],
      );

      // 2. Update apartment status after termination
      await txn.update(
        DatabaseTables.apartments,
        {'status': nextApartmentStatus},
        where: 'id = ?',
        whereArgs: [cnt.apartmentId],
      );
    });
  }
}
