import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_migrations.dart';
import 'database_seeder.dart';
import 'database_tables.dart';

/// Singleton GetxService managing the local SQLite database.
/// Clearly distinguishes between Production Environment (`isTestEnvironment = false`,
/// where the database starts empty for the real owner) and Test Environment
/// (`isTestEnvironment = true`, supporting in-memory or temporary DBs and optional seeding).
class AppDatabase extends GetxService {
  static bool _ffiInitialized = false;
  Database? _db;
  String? _dbPath;
  final bool isTestEnvironment;
  final bool autoSeedInTest;

  AppDatabase({
    this.isTestEnvironment = false,
    this.autoSeedInTest = false,
  });

  Database get db {
    if (_db == null) {
      throw StateError('AppDatabase has not been initialized yet.');
    }
    return _db!;
  }

  String get dbPath => _dbPath ?? '';

  Future<AppDatabase> init({String? customPath}) async {
    if (_db != null && _db!.isOpen) {
      return this;
    }

    if ((Platform.isWindows || Platform.isLinux || isTestEnvironment) &&
        !_ffiInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }

    if (customPath != null) {
      _dbPath = customPath;
    } else if (isTestEnvironment) {
      _dbPath = inMemoryDatabasePath;
    } else {
      final dbDir = await getDatabasesPath();
      _dbPath = p.join(dbDir, DatabaseTables.databaseName);
    }

    _db = await openDatabase(
      _dbPath!,
      version: DatabaseTables.currentSchemaVersion,
      onConfigure: (Database db) async {
        // Section 10 & 15: Enable Foreign Keys enforcement
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
    );

    // Only auto-seed when explicitly requested in a test environment.
    // Production mode ALWAYS starts empty on first run per Section 3 policy.
    if (isTestEnvironment && autoSeedInTest) {
      await DatabaseSeeder.seedIfEmpty(_db!);
    }

    return this;
  }

  /// Allows the owner to optionally load demo seed data if the database is currently empty.
  Future<bool> loadOptionalDemoSeedData() async {
    return DatabaseSeeder.seedIfEmpty(db);
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
  }

  Future<void> reopen() async {
    await close();
    await init(customPath: _dbPath);
  }
}
