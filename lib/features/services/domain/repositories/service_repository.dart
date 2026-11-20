import '../entities/service_entity.dart';

abstract class ServiceRepository {
  Future<List<ServiceEntity>> getAllServices({String? searchQuery});
  Future<ServiceEntity?> getServiceById(int id);
  Future<int> addService(ServiceEntity service);
  Future<void> updateService(ServiceEntity service);
  Future<void> deleteService(int id);
}
