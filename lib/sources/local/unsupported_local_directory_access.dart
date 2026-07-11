import 'local_directory_access.dart';

class UnsupportedLocalDirectoryAccess implements LocalDirectoryAccess {
  const UnsupportedLocalDirectoryAccess();

  @override
  Future<LocalDirectoryGrant?> pickDirectory() async => null;

  @override
  Future<LocalDirectoryGrant> restoreDirectory({
    required String rootUri,
    permissionToken,
  }) async {
    return LocalDirectoryGrant(
      rootUri: rootUri,
      displayName: _displayName(rootUri),
      status: LocalDirectoryAccessStatus.unsupported,
      permissionToken: permissionToken,
    );
  }

  @override
  Future<void> releaseDirectory(String rootUri) async {}
}

String _displayName(String rootUri) {
  final uri = Uri.tryParse(rootUri);
  return uri?.pathSegments.where((segment) => segment.isNotEmpty).lastOrNull ??
      rootUri;
}
