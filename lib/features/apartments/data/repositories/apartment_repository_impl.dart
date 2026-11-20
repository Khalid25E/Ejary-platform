import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/apartment_entity.dart';
import '../../domain/entities/apartment_service_entity.dart';
import '../../domain/repositories/apartment_repository.dart';
import '../models/apartment_model.dart';
import '../models/apartment_service_model.dart';

class ApartmentRepositoryImpl implements ApartmentRepository {
  final AppDatabase _appDb;

  ApartmentRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<ApartmentEntity>> getAllApartments({
    String? searchQuery,
    int? propertyId,
    int? floor,
    String? status,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    final q = searchQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      whereClauses.add('(apartment_number LIKE ? OR notes LIKE ?)');
      args.addAll(['%$q%', '%$q%']);
    }
    if (propertyId != null && propertyId > 0) {
      whereClauses.add('property_id = ?');
      args.add(propertyId);
    }
    if (floor != null) {
      whereClauses.add('floor = ?');
      args.add(floor);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      whereClauses.add('status = ?');
      args.add(status);
    }

    final rows = await _db.query(
      DatabaseTables.apartments,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'property_id ASC, floor ASC, apartment_number ASC',
    );
    return rows.map(ApartmentModel.fromMap).toList();
  }

  @override
  Future<ApartmentEntity?> getApartmentById(int id) async {
    final rows = await _db.query(
      DatabaseTables.apartments,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ApartmentModel.fromMap(rows.first);
  }

  @override
  Future<int> addApartment(ApartmentEntity apartment) async {
    final model = ApartmentModel(
      id: 0,
      propertyId: apartment.propertyId,
      apartmentNumber: apartment.apartmentNumber.trim(),
      floor: apartment.floor,
      roomsCount: apartment.roomsCount,
      baseRent: apartment.baseRent,
      status: apartment.status,
      notes: apartment.notes.trim(),
      createdAt: apartment.createdAt,
    );
    return _db.insert(
      DatabaseTables.apartments,
      model.toMap(includeId: false),
    );
  }

  @override
  Future<void> updateApartment(ApartmentEntity apartment) async {
    final model = ApartmentModel(
      id: apartment.id,
      propertyId: apartment.propertyId,
      apartmentNumber: apartment.apartmentNumber.trim(),
      floor: apartment.floor,
      roomsCount: apartment.roomsCount,
      baseRent: apartment.baseRent,
      status: apartment.status,
      notes: apartment.notes.trim(),
      createdAt: apartment.createdAt,
    );
    await _db.update(
      DatabaseTables.apartments,
      model.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [apartment.id],
    );
  }

  @override
  Future<void> deleteApartment(int id) async {
    final contractCount = Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.contracts} WHERE apartment_id = ?',
            [id],
          ),
        ) ??
        0;
    if (contractCount > 0) {
      throw const DataIntegrityException(
        'Cannot delete apartment that has linked contracts.',
      );
    }
    await _db.delete(
      DatabaseTables.apartments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ApartmentServiceEntity>> getApartmentServices(
    int apartmentId,
  ) async {
    final rows = await _db.query(
      DatabaseTables.apartmentServices,
      where: 'apartment_id = ?',
      whereArgs: [apartmentId],
      orderBy: 'service_id ASC',
    );
    return rows.map(ApartmentServiceModel.fromMap).toList();
  }

  @override
  Future<List<ApartmentServiceEntity>> getAllApartmentServices() async {
    final rows = await _db.query(
      DatabaseTables.apartmentServices,
      orderBy: 'apartment_id ASC, service_id ASC',
    );
    return rows.map(ApartmentServiceModel.fromMap).toList();
  }

  @override
  Future<void> saveApartmentServices(
    int apartmentId,
    List<ApartmentServiceEntity> services,
  ) async {
    // FR-06: Custom apartment service prices are stored independently in apartment_services
    // and never alter historical contract_services snapshots.
    await _db.transaction((txn) async {
      await txn.delete(
        DatabaseTables.apartmentServices,
        where: 'apartment_id = ?',
        whereArgs: [apartmentId],
      );
      for (final srv in services) {
        final model = ApartmentServiceModel(
          id: 0,
          apartmentId: apartmentId,
          serviceId: srv.serviceId,
          customPrice: srv.customPrice,
          billingType: srv.billingType,
          isActive: srv.isActive,
          notes: srv.notes,
          createdAt: srv.createdAt,
        );
        await txn.insert(
          DatabaseTables.apartmentServices,
          model.toMap(includeId: false),
        );
      }
    });
  }
}
