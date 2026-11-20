import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

class ManagePropertiesUseCase {
  final PropertyRepository _repository;

  const ManagePropertiesUseCase(this._repository);

  Future<List<PropertyEntity>> getProperties({
    String? searchQuery,
    String? status,
    int? zoneId,
  }) =>
      _repository.getAllProperties(
        searchQuery: searchQuery,
        status: status,
        zoneId: zoneId,
      );

  Future<PropertyEntity?> getPropertyById(int id) =>
      _repository.getPropertyById(id);

  Future<int> addProperty(PropertyEntity property) =>
      _repository.addProperty(property);

  Future<void> updateProperty(PropertyEntity property) =>
      _repository.updateProperty(property);

  Future<void> deleteProperty(int id) => _repository.deleteProperty(id);

  Future<Map<String, num>> getFinancialSummary(int propertyId) =>
      _repository.getPropertyFinancialSummary(propertyId);
}
