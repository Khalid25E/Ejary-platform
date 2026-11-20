import '../entities/zone_entity.dart';

abstract class ZoneRepository {
  Future<List<ZoneEntity>> getAllZones({String? searchQuery});
  Future<ZoneEntity?> getZoneById(int id);
  Future<int> getPropertyCountForZone(int zoneId);
  Future<int> addZone(ZoneEntity zone);
  Future<void> updateZone(ZoneEntity zone);
  Future<void> deleteZone(int zoneId);
}
