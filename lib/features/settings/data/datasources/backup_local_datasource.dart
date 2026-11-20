import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/backup_metadata_entity.dart';

class BackupLocalDataSource {
  final AppDatabase _appDb;

  const BackupLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  static const List<String> _orderedTablesForExportAndImport = [
    DatabaseTables.appMetadata,
    DatabaseTables.zones,
    DatabaseTables.properties,
    DatabaseTables.services,
    DatabaseTables.apartments,
    DatabaseTables.apartmentServices,
    DatabaseTables.tenants,
    DatabaseTables.contracts,
    DatabaseTables.contractServices,
    DatabaseTables.invoices,
    DatabaseTables.payments,
  ];

  /// Exports a full relational snapshot of the SQLite database to a JSON map.
  Future<Map<String, dynamic>> exportBackupPayload() async {
    final tablesData = <String, List<Map<String, dynamic>>>{};
    for (final table in _orderedTablesForExportAndImport) {
      final rows = await _db.query(table);
      tablesData[table] = rows;
    }

    return {
      'app': 'Ejary Platform',
      'schema_version': DatabaseTables.currentSchemaVersion,
      'created_at': DateTime.now().toIso8601String(),
      'tables': tablesData,
    };
  }

  /// Writes the backup payload to a local file in [targetDirectory] (or device documents directory).
  Future<File> exportBackupToFile({
    String? customDirectoryPath,
    String? customFileName,
  }) async {
    final payload = await exportBackupPayload();
    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    final dirPath =
        customDirectoryPath ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = customFileName ?? 'ejary_backup_$timestamp.json';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(jsonString, flush: true);
    return file;
  }

  /// Lists available local backup files in the directory.
  Future<List<BackupMetadataEntity>> listLocalBackups({
    String? customDirectoryPath,
  }) async {
    final dirPath =
        customDirectoryPath ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final result = <BackupMetadataEntity>[];
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('ejary_backup_') &&
          entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic> &&
              decoded['app'] == 'Ejary Platform') {
            result.add(
              BackupMetadataEntity(
                fileName: entity.path,
                createdAt: (decoded['created_at'] as String?) ?? '',
                schemaVersion: (decoded['schema_version'] as int?) ?? 1,
              ),
            );
          }
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Validates the backup payload's structure, integrity, and schema version.
  void validateBackupPayload(Map<String, dynamic> payload) {
    if (payload['app'] != 'Ejary Platform') {
      throw const ValidationException(
        'Invalid backup file: Not an Ejary Platform backup.',
      );
    }
    final version = payload['schema_version'];
    if (version is! int ||
        version < 1 ||
        version > DatabaseTables.currentSchemaVersion) {
      throw ValidationException(
        'Incompatible database schema version: $version (Current: ${DatabaseTables.currentSchemaVersion}).',
      );
    }
    final tables = payload['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const ValidationException(
        'Corrupted backup file: Missing tables section.',
      );
    }
    for (final requiredTable in _orderedTablesForExportAndImport) {
      if (!tables.containsKey(requiredTable) ||
          tables[requiredTable] is! List) {
        throw ValidationException(
          'Corrupted backup file: Missing table "$requiredTable".',
        );
      }
    }
  }

  /// Restores a backup from [backupFile] after:
  /// 1. Verifying file integrity and schema version.
  /// 2. Creating an automatic pre-restore safety backup of current data.
  /// 3. Restoring all records atomically in a single SQLite Transaction preserving relationships.
  Future<File> restoreFromBackupFile(
    File backupFile, {
    String? safetyBackupDirectoryPath,
  }) async {
    if (!await backupFile.exists()) {
      throw const NotFoundException('Backup file does not exist.');
    }

    final rawContent = await backupFile.readAsString();
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } catch (_) {
      throw const ValidationException('Backup file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException('Invalid backup JSON root object.');
    }

    // 1. Verify integrity & schema version
    validateBackupPayload(decoded);

    // 2. Create automatic safety backup of current database before modifying anything
    final safetyDir = safetyBackupDirectoryPath ?? p.dirname(backupFile.path);
    final safetyFile = await exportBackupToFile(
      customDirectoryPath: safetyDir,
      customFileName:
          'ejary_backup_safety_pre_restore_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    // 3. Atomic full restore inside a SQLite Transaction
    final tablesMap = decoded['tables'] as Map<String, dynamic>;
    await _db.transaction((txn) async {
      // Delete in reverse dependency order (children first, then parents)
      for (final table in _orderedTablesForExportAndImport.reversed) {
        await txn.delete(table);
      }

      // Insert in parent-first dependency order
      for (final table in _orderedTablesForExportAndImport) {
        final rows = tablesMap[table] as List<dynamic>;
        for (final row in rows) {
          final rowMap = Map<String, dynamic>.from(row as Map);
          await txn.insert(
            table,
            rowMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    return safetyFile;
  }
}
