import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/repositories/property_repository.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final AppDatabase _appDb;

  PropertyRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<PropertyEntity>> getAllProperties({
    String? searchQuery,
    String? status,
    int? zoneId,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    final q = searchQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR description LIKE ?)');
      args.addAll(['%$q%', '%$q%']);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      whereClauses.add('status = ?');
      args.add(status);
    }
    if (zoneId != null && zoneId > 0) {
      whereClauses.add('zone_id = ?');
      args.add(zoneId);
    }

    final rows = await _db.query(
      DatabaseTables.properties,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id DESC',
    );
    return rows.map(PropertyModel.fromMap).toList();
  }

  @override
  Future<PropertyEntity?> getPropertyById(int id) async {
    final rows = await _db.query(
      DatabaseTables.properties,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PropertyModel.fromMap(rows.first);
  }

  @override
  Future<int> addProperty(PropertyEntity property) async {
    final model = PropertyModel(
      id: 0,
      name: property.name.trim(),
      description: property.description.trim(),
      status: property.status,
      type: property.type,
      zoneId: property.zoneId,
      longitude: property.longitude,
      latitude: property.latitude,
      createdAt: property.createdAt,
    );
    return _db.insert(
      DatabaseTables.properties,
      model.toMap(includeId: false),
    );
  }

  @override
  Future<void> updateProperty(PropertyEntity property) async {
    final model = PropertyModel(
      id: property.id,
      name: property.name.trim(),
      description: property.description.trim(),
      status: property.status,
      type: property.type,
      zoneId: property.zoneId,
      longitude: property.longitude,
      latitude: property.latitude,
      createdAt: property.createdAt,
    );
    await _db.update(
      DatabaseTables.properties,
      model.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [property.id],
    );
  }

  @override
  Future<void> deleteProperty(int id) async {
    final aptCount = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.apartments} WHERE property_id = ?',
            [id],
          ),
        ) ??
        0;
    if (aptCount > 0) {
      throw const DataIntegrityException(
        'Cannot delete property that has linked apartments.',
      );
    }
    await _db.delete(
      DatabaseTables.properties,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Map<String, num>> getPropertyFinancialSummary(int propertyId) async {
    final rows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(inv.paid_amount), 0) AS collected_revenues,
        COALESCE(SUM(inv.remaining_amount), 0) AS remaining_dues
      FROM ${DatabaseTables.invoices} inv
      INNER JOIN ${DatabaseTables.contracts} c ON c.id = inv.contract_id
      INNER JOIN ${DatabaseTables.apartments} a ON a.id = c.apartment_id
      WHERE a.property_id = ? AND inv.status != 'Cancelled'
    ''', [propertyId]);

    if (rows.isEmpty) {
      return {'collected': 0, 'dues': 0};
    }
    return {
      'collected': (rows.first['collected_revenues'] as num?) ?? 0,
      'dues': (rows.first['remaining_dues'] as num?) ?? 0,
    };
  }
}
