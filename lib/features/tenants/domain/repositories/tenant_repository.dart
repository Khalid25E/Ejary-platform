import '../entities/tenant_entity.dart';
import '../entities/tenant_statement_entity.dart';

abstract class TenantRepository {
  Future<List<TenantEntity>> getAllTenants({String? searchQuery});
  Future<TenantEntity?> getTenantById(int id);
  Future<int> addTenant(TenantEntity tenant);
  Future<void> updateTenant(TenantEntity tenant);
  Future<void> deleteTenant(int id);
  Future<TenantStatementEntity> getTenantStatement(int tenantId);
}
