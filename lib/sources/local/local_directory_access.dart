import 'dart:typed_data';

enum LocalDirectoryAccessStatus {
  available,
  permissionRequired,
  unavailable,
  unsupported,
}

class LocalDirectoryGrant {
  const LocalDirectoryGrant({
    required this.rootUri,
    required this.displayName,
    required this.status,
    this.permissionToken,
    this.isStale = false,
  });

  final String rootUri;
  final String displayName;
  final LocalDirectoryAccessStatus status;
  final Uint8List? permissionToken;
  final bool isStale;

  bool get isAvailable => status == LocalDirectoryAccessStatus.available;
}

abstract interface class LocalDirectoryAccess {
  Future<LocalDirectoryGrant?> pickDirectory();

  Future<LocalDirectoryGrant> restoreDirectory({
    required String rootUri,
    Uint8List? permissionToken,
  });

  Future<void> releaseDirectory(String rootUri);
}
