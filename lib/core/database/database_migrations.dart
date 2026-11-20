import 'package:sqflite/sqflite.dart';
import 'database_tables.dart';

class DatabaseMigrations {
  DatabaseMigrations._();

  static Future<void> onCreate(Database db, int version) async {
    await _createV1Schema(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _createV1Schema(db);
    }
    // Future migrations (e.g., if (oldVersion < 2) { ... }) are added here
    // sequentially without dropping existing tables or losing owner data.
  }

  static Future<void> _createV1Schema(DatabaseExecutor db) async {
    // 0. App Metadata table (schema version, seed flag, owner backup metadata)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.appMetadata} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 1. Zones table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.zones} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Properties table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.properties} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK(status IN ('active', 'inactive', 'maintenance')),
        type TEXT NOT NULL CHECK(type IN ('residential', 'commercial', 'mixed', 'other')),
        zone_id INTEGER NOT NULL,
        longitude REAL,
        latitude REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (zone_id) REFERENCES ${DatabaseTables.zones}(id) ON DELETE RESTRICT
      )
    ''');

    // 3. Apartments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.apartments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        apartment_number TEXT NOT NULL,
        floor INTEGER NOT NULL DEFAULT 0,
        rooms_count INTEGER NOT NULL CHECK(rooms_count > 0),
        base_rent INTEGER NOT NULL CHECK(base_rent >= 0),
        status TEXT NOT NULL CHECK(status IN ('vacant', 'rented', 'maintenance', 'unavailable')),
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        UNIQUE(property_id, apartment_number),
        FOREIGN KEY (property_id) REFERENCES ${DatabaseTables.properties}(id) ON DELETE RESTRICT
      )
    ''');

    // 4. Services Catalog table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.services} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL DEFAULT '',
        default_price INTEGER NOT NULL CHECK(default_price >= 0),
        billing_type TEXT NOT NULL CHECK(billing_type IN ('fixed_monthly', 'usage_based')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Apartment Custom Services table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.apartmentServices} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        custom_price INTEGER NOT NULL CHECK(custom_price >= 0),
        billing_type TEXT NOT NULL CHECK(billing_type IN ('fixed_monthly', 'usage_based')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        UNIQUE(apartment_id, service_id),
        FOREIGN KEY (apartment_id) REFERENCES ${DatabaseTables.apartments}(id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES ${DatabaseTables.services}(id) ON DELETE RESTRICT
      )
    ''');

    // 6. Tenants table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tenants} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        national_id TEXT NOT NULL UNIQUE,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // 7. Contracts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.contracts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_number TEXT NOT NULL UNIQUE,
        apartment_id INTEGER NOT NULL,
        tenant_id INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        price INTEGER NOT NULL CHECK(price >= 0),
        total_services INTEGER NOT NULL DEFAULT 0 CHECK(total_services >= 0),
        conditions_json TEXT NOT NULL DEFAULT '[]',
        due_date TEXT NOT NULL,
        due_day INTEGER NOT NULL CHECK(due_day >= 1 AND due_day <= 31),
        rental_at TEXT NOT NULL,
        auto_renew INTEGER NOT NULL DEFAULT 0 CHECK(auto_renew IN (0, 1)),
        status TEXT NOT NULL CHECK(status IN ('active', 'expiring', 'expired', 'terminated')),
        notes TEXT NOT NULL DEFAULT '',
        renewal_of_contract_id INTEGER,
        termination_date TEXT,
        termination_reason TEXT,
        FOREIGN KEY (apartment_id) REFERENCES ${DatabaseTables.apartments}(id) ON DELETE RESTRICT,
        FOREIGN KEY (tenant_id) REFERENCES ${DatabaseTables.tenants}(id) ON DELETE RESTRICT,
        FOREIGN KEY (renewal_of_contract_id) REFERENCES ${DatabaseTables.contracts}(id) ON DELETE SET NULL
      )
    ''');

    // 8. Historical Contract Services Snapshot table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.contractServices} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        service_name TEXT NOT NULL,
        price INTEGER NOT NULL CHECK(price >= 0),
        billing_type TEXT NOT NULL CHECK(billing_type IN ('fixed_monthly', 'usage_based')),
        created_at TEXT NOT NULL,
        FOREIGN KEY (contract_id) REFERENCES ${DatabaseTables.contracts}(id) ON DELETE RESTRICT,
        FOREIGN KEY (service_id) REFERENCES ${DatabaseTables.services}(id) ON DELETE RESTRICT
      )
    ''');

    // 9. Monthly Invoices table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.invoices} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        billing_month TEXT NOT NULL,
        due_date TEXT NOT NULL,
        base_rent INTEGER NOT NULL CHECK(base_rent >= 0),
        services_total INTEGER NOT NULL DEFAULT 0 CHECK(services_total >= 0),
        total_amount INTEGER NOT NULL CHECK(total_amount >= 0),
        paid_amount INTEGER NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
        remaining_amount INTEGER NOT NULL CHECK(remaining_amount >= 0),
        status TEXT NOT NULL CHECK(status IN ('Pending', 'Partially Paid', 'Paid', 'Overdue', 'Cancelled')),
        created_at TEXT NOT NULL,
        UNIQUE(contract_id, billing_month),
        FOREIGN KEY (contract_id) REFERENCES ${DatabaseTables.contracts}(id) ON DELETE RESTRICT
      )
    ''');

    // 10. Payments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.payments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        invoice_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('full', 'partial')),
        pay_at TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK(amount > 0),
        pay_method TEXT NOT NULL CHECK(pay_method IN ('cash', 'bank', 'remittance', 'other')),
        pay_ref TEXT NOT NULL DEFAULT '',
        billing_month TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_cancelled INTEGER NOT NULL DEFAULT 0 CHECK(is_cancelled IN (0, 1)),
        created_at TEXT NOT NULL,
        FOREIGN KEY (contract_id) REFERENCES ${DatabaseTables.contracts}(id) ON DELETE RESTRICT,
        FOREIGN KEY (invoice_id) REFERENCES ${DatabaseTables.invoices}(id) ON DELETE RESTRICT
      )
    ''');

    // Indexes for high-performance relational lookups & financial aggregations
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_properties_zone ON ${DatabaseTables.properties}(zone_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_apartments_property ON ${DatabaseTables.apartments}(property_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_apartments_status ON ${DatabaseTables.apartments}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_apt_services_apt ON ${DatabaseTables.apartmentServices}(apartment_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contracts_apt ON ${DatabaseTables.contracts}(apartment_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contracts_tenant ON ${DatabaseTables.contracts}(tenant_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contracts_status ON ${DatabaseTables.contracts}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contract_services_cnt ON ${DatabaseTables.contractServices}(contract_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_contract ON ${DatabaseTables.invoices}(contract_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_month ON ${DatabaseTables.invoices}(billing_month)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_status ON ${DatabaseTables.invoices}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_invoice ON ${DatabaseTables.payments}(invoice_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_contract ON ${DatabaseTables.payments}(contract_id)',
    );

    // Record schema version in app_metadata
    await db.insert(
      DatabaseTables.appMetadata,
      {
        'key': 'schema_version',
        'value': '${DatabaseTables.currentSchemaVersion}',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
