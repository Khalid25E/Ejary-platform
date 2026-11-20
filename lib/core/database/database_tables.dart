class DatabaseTables {
  DatabaseTables._();

  static const String databaseName = 'ejary_platform.db';
  static const int currentSchemaVersion = 1;

  static const String appMetadata = 'app_metadata';
  static const String zones = 'zones';
  static const String properties = 'properties';
  static const String apartments = 'apartments';
  static const String services = 'services';
  static const String apartmentServices = 'apartment_services';
  static const String tenants = 'tenants';
  static const String contracts = 'contracts';
  static const String contractServices = 'contract_services';
  static const String invoices = 'invoices';
  static const String payments = 'payments';
}
