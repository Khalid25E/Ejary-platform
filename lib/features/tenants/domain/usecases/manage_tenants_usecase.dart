import '../entities/tenant_entity.dart';
import '../entities/tenant_statement_entity.dart';
import '../repositories/tenant_repository.dart';

class ManageTenantsUseCase {
  final TenantRepository _repository;

  const ManageTenantsUseCase(this._repository);

  Future<List<TenantEntity>> getTenants({String? searchQuery}) =>
      _repository.getAllTenants(searchQuery: searchQuery);

  Future<TenantEntity?> getTenantById(int id) => _repository.getTenantById(id);

  Future<int> addTenant(TenantEntity tenant) => _repository.addTenant(tenant);

  Future<void> updateTenant(TenantEntity tenant) =>
      _repository.updateTenant(tenant);

  Future<void> deleteTenant(int id) => _repository.deleteTenant(id);

  Future<TenantStatementEntity> getStatement(int tenantId) =>
      _repository.getTenantStatement(tenantId);
}
