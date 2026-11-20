import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final AppDatabase _appDb;

  ServiceRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<ServiceEntity>> getAllServices({String? searchQuery}) async {
    final q = searchQuery?.trim() ?? '';
    final rows = await _db.query(
      DatabaseTables.services,
      where: q.isEmpty ? null : 'name LIKE ? OR description LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'id ASC',
    );
    return rows.map(ServiceModel.fromMap).toList();
  }

  @override
  Future<ServiceEntity?> getServiceById(int id) async {
    final rows = await _db.query(
      DatabaseTables.services,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceModel.fromMap(rows.first);
  }

  @override
  Future<int> addService(ServiceEntity service) async {
    final model = ServiceModel(
      id: 0,
      name: service.name.trim(),
      description: service.description.trim(),
      defaultPrice: service.defaultPrice,
      billingType: service.billingType,
      isActive: service.isActive,
      createdAt: service.createdAt,
    );
    return _db.insert(
      DatabaseTables.services,
      model.toMap(includeId: false),
    );
  }

  @override
  Future<void> updateService(ServiceEntity service) async {
    // FR-06 Rule 2: Updating a service's default price NEVER modifies existing
    // apartment_services custom prices or historical contract_services snapshots.
    final model = ServiceModel(
      id: service.id,
      name: service.name.trim(),
      description: service.description.trim(),
      defaultPrice: service.defaultPrice,
      billingType: service.billingType,
      isActive: service.isActive,
      createdAt: service.createdAt,
    );
    await _db.update(
      DatabaseTables.services,
      model.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  @override
  Future<void> deleteService(int id) async {
    final contractUsageCount = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.contractServices} WHERE service_id = ?',
            [id],
          ),
        ) ??
        0;
    final aptUsageCount = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.apartmentServices} WHERE service_id = ?',
            [id],
          ),
        ) ??
        0;

    if (contractUsageCount > 0 || aptUsageCount > 0) {
      throw const DataIntegrityException(
        'Cannot delete service with historical contract or apartment links. Disable it instead.',
      );
    }

    await _db.delete(
      DatabaseTables.services,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
