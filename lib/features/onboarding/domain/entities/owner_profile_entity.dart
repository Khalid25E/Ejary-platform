class OwnerProfileEntity {
  final String fullName;
  final String phone;
  final String? avatarPath;
  final String defaultCurrency;

  const OwnerProfileEntity({
    required this.fullName,
    required this.phone,
    this.avatarPath,
    required this.defaultCurrency,
  });
}
