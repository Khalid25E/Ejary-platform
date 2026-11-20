class PropertyEntity {
  final int id;
  final String name;
  final String description;
  final String status; // active, inactive, maintenance
  final String type; // residential, commercial, mixed, other
  final int zoneId;
  final double? longitude;
  final double? latitude;
  final String createdAt;

  const PropertyEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.type,
    required this.zoneId,
    this.longitude,
    this.latitude,
    required this.createdAt,
  });
}
