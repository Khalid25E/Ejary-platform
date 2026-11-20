class BackupMetadataEntity {
  final String fileName;
  final String createdAt;
  final int schemaVersion;

  const BackupMetadataEntity({
    required this.fileName,
    required this.createdAt,
    required this.schemaVersion,
  });
}
