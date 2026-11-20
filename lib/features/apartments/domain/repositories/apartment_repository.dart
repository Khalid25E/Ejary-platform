import '../entities/apartment_entity.dart';
import '../entities/apartment_service_entity.dart';

abstract class ApartmentRepository {
  Future<List<ApartmentEntity>> getAllApartments({
    String? searchQuery,
    int? propertyId,
    int? floor,
    String? status,
  });
  Future<ApartmentEntity?> getApartmentById(int id);
  Future<int> addApartment(ApartmentEntity apartment);
  Future<void> updateApartment(ApartmentEntity apartment);
  Future<void> deleteApartment(int id);
  Future<List<ApartmentServiceEntity>> getApartmentServices(int apartmentId);
  Future<List<ApartmentServiceEntity>> getAllApartmentServices();
  Future<void> saveApartmentServices(
    int apartmentId,
    List<ApartmentServiceEntity> services,
  );
}
