import '../entities/apartment_entity.dart';
import '../entities/apartment_service_entity.dart';
import '../repositories/apartment_repository.dart';

class ManageApartmentsUseCase {
  final ApartmentRepository _repository;

  const ManageApartmentsUseCase(this._repository);

  Future<List<ApartmentEntity>> getApartments({
    String? searchQuery,
    int? propertyId,
    int? floor,
    String? status,
  }) =>
      _repository.getAllApartments(
        searchQuery: searchQuery,
        propertyId: propertyId,
        floor: floor,
        status: status,
      );

  Future<ApartmentEntity?> getApartmentById(int id) =>
      _repository.getApartmentById(id);

  Future<int> addApartment(ApartmentEntity apartment) =>
      _repository.addApartment(apartment);

  Future<void> updateApartment(ApartmentEntity apartment) =>
      _repository.updateApartment(apartment);

  Future<void> deleteApartment(int id) => _repository.deleteApartment(id);

  Future<List<ApartmentServiceEntity>> getApartmentServices(int apartmentId) =>
      _repository.getApartmentServices(apartmentId);

  Future<List<ApartmentServiceEntity>> getAllApartmentServices() =>
      _repository.getAllApartmentServices();

  Future<void> saveApartmentServices(
    int apartmentId,
    List<ApartmentServiceEntity> services,
  ) =>
      _repository.saveApartmentServices(apartmentId, services);
}
