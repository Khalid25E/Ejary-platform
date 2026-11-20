class ApartmentEntity {
  final int id;
  final int propertyId;
  final String apartmentNumber;
  final int floor;
  final int roomsCount;
  final num baseRent;
  final String status; // vacant, rented, maintenance, unavailable
  final String notes;
  final String createdAt;

  const ApartmentEntity({
    required this.id,
    required this.propertyId,
    required this.apartmentNumber,
    required this.floor,
    required this.roomsCount,
    required this.baseRent,
    required this.status,
    required this.notes,
    required this.createdAt,
  });
}
