import '../../../tenants/domain/entities/tenant_entity.dart';
import '../entities/contract_entity.dart';
import '../entities/contract_service_entity.dart';
import '../repositories/contract_repository.dart';

class ManageContractsUseCase {
  final ContractRepository _repository;

  const ManageContractsUseCase(this._repository);

  Future<List<ContractEntity>> getContracts({
    String? searchQuery,
    String? status,
    int? tenantId,
    int? apartmentId,
  }) =>
      _repository.getAllContracts(
        searchQuery: searchQuery,
        status: status,
        tenantId: tenantId,
        apartmentId: apartmentId,
      );

  Future<ContractEntity?> getContractById(int id) =>
      _repository.getContractById(id);

  Future<List<ContractServiceEntity>> getContractServices(int contractId) =>
      _repository.getContractServices(contractId);

  Future<List<ContractServiceEntity>> getAllContractServices() =>
      _repository.getAllContractServices();

  Future<int> createContract({
    required ContractEntity contract,
    required List<ContractServiceEntity> servicesSnapshot,
    TenantEntity? inlineNewTenant,
  }) =>
      _repository.createContractAtomically(
        contract: contract,
        servicesSnapshot: servicesSnapshot,
        inlineNewTenant: inlineNewTenant,
      );

  Future<int> renewContract({
    required int oldContractId,
    required String newContractNumber,
    required String newStartDate,
    required String newEndDate,
    required num newBaseRent,
    required List<ContractServiceEntity> newServicesSnapshot,
    String? notes,
  }) =>
      _repository.renewContractAtomically(
        oldContractId: oldContractId,
        newContractNumber: newContractNumber,
        newStartDate: newStartDate,
        newEndDate: newEndDate,
        newBaseRent: newBaseRent,
        newServicesSnapshot: newServicesSnapshot,
        notes: notes,
      );

  Future<void> terminateContract({
    required int contractId,
    required String terminationDate,
    required String terminationReason,
    required String nextApartmentStatus,
  }) =>
      _repository.terminateContractAtomically(
        contractId: contractId,
        terminationDate: terminationDate,
        terminationReason: terminationReason,
        nextApartmentStatus: nextApartmentStatus,
      );
}
