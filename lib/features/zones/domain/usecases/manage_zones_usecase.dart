import '../entities/zone_entity.dart';
import '../repositories/zone_repository.dart';

class ManageZonesUseCase {
  final ZoneRepository _repository;

  const ManageZonesUseCase(this._repository);

  Future<List<ZoneEntity>> getZones({String? searchQuery}) =>
      _repository.getAllZones(searchQuery: searchQuery);

  Future<ZoneEntity?> getZoneById(int id) => _repository.getZoneById(id);

  Future<int> getPropertyCount(int zoneId) =>
      _repository.getPropertyCountForZone(zoneId);

  Future<int> addZone(ZoneEntity zone) => _repository.addZone(zone);

  Future<void> updateZone(ZoneEntity zone) => _repository.updateZone(zone);

  Future<void> deleteZone(int zoneId) => _repository.deleteZone(zoneId);
}
