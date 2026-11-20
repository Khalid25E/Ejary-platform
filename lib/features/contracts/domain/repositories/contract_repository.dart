import '../../../tenants/domain/entities/tenant_entity.dart';
import '../entities/contract_entity.dart';
import '../entities/contract_service_entity.dart';

abstract class ContractRepository {
  Future<List<ContractEntity>> getAllContracts({
    String? searchQuery,
    String? status,
    int? tenantId,
    int? apartmentId,
  });
  Future<ContractEntity?> getContractById(int id);
  Future<List<ContractServiceEntity>> getContractServices(int contractId);
  Future<List<ContractServiceEntity>> getAllContractServices();

  /// Atomically creates a contract, optional inline tenant, historical contract_services
  /// snapshot, updates apartment status to 'rented', and creates initial due invoice.
  Future<int> createContractAtomically({
    required ContractEntity contract,
    required List<ContractServiceEntity> servicesSnapshot,
    TenantEntity? inlineNewTenant,
  });

  /// Atomically renews an existing contract, marks the previous contract as expired,
  /// creates the new linked contract and its services snapshot.
  Future<int> renewContractAtomically({
    required int oldContractId,
    required String newContractNumber,
    required String newStartDate,
    required String newEndDate,
    required num newBaseRent,
    required List<ContractServiceEntity> newServicesSnapshot,
    String? notes,
  });

  /// Atomically terminates a contract, records reason and date, updates apartment status,
  /// and preserves all historical invoices and payments.
  Future<void> terminateContractAtomically({
    required int contractId,
    required String terminationDate,
    required String terminationReason,
    required String nextApartmentStatus,
  });
}
