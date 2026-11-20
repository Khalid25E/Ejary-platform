import '../entities/property_entity.dart';

abstract class PropertyRepository {
  Future<List<PropertyEntity>> getAllProperties({
    String? searchQuery,
    String? status,
    int? zoneId,
  });
  Future<PropertyEntity?> getPropertyById(int id);
  Future<int> addProperty(PropertyEntity property);
  Future<void> updateProperty(PropertyEntity property);
  Future<void> deleteProperty(int id);
  Future<Map<String, num>> getPropertyFinancialSummary(int propertyId);
}
