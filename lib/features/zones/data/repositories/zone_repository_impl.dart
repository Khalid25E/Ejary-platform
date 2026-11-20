import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/repositories/zone_repository.dart';
import '../models/zone_model.dart';

class ZoneRepositoryImpl implements ZoneRepository {
  final AppDatabase _appDb;

  ZoneRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<ZoneEntity>> getAllZones({String? searchQuery}) async {
    final q = searchQuery?.trim() ?? '';
    final rows = await _db.query(
      DatabaseTables.zones,
      where: q.isEmpty ? null : 'name LIKE ? OR description LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'id DESC',
    );
    return rows.map(ZoneModel.fromMap).toList();
  }

  @override
  Future<ZoneEntity?> getZoneById(int id) async {
    final rows = await _db.query(
      DatabaseTables.zones,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ZoneModel.fromMap(rows.first);
  }

  @override
  Future<int> getPropertyCountForZone(int zoneId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseTables.properties} WHERE zone_id = ?',
      [zoneId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> addZone(ZoneEntity zone) async {
    final model = ZoneModel(
      id: 0,
      name: zone.name.trim(),
      description: zone.description.trim(),
      createdAt: zone.createdAt,
    );
    return _db.insert(
      DatabaseTables.zones,
      model.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateZone(ZoneEntity zone) async {
    final model = ZoneModel(
      id: zone.id,
      name: zone.name.trim(),
      description: zone.description.trim(),
      createdAt: zone.createdAt,
    );
    await _db.update(
      DatabaseTables.zones,
      model.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [zone.id],
    );
  }

  @override
  Future<void> deleteZone(int zoneId) async {
    final propCount = await getPropertyCountForZone(zoneId);
    if (propCount > 0) {
      throw const DataIntegrityException(
        'Cannot delete zone with linked properties.',
      );
    }
    await _db.delete(
      DatabaseTables.zones,
      where: 'id = ?',
      whereArgs: [zoneId],
    );
  }
}
