import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

class ManageServicesUseCase {
  final ServiceRepository _repository;

  const ManageServicesUseCase(this._repository);

  Future<List<ServiceEntity>> getServices({String? searchQuery}) =>
      _repository.getAllServices(searchQuery: searchQuery);

  Future<ServiceEntity?> getServiceById(int id) =>
      _repository.getServiceById(id);

  Future<int> addService(ServiceEntity service) =>
      _repository.addService(service);

  Future<void> updateService(ServiceEntity service) =>
      _repository.updateService(service);

  Future<void> deleteService(int id) => _repository.deleteService(id);
}
