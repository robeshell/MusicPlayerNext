import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'local_directory_access.dart';

class FileSystemLocalDirectoryAccess implements LocalDirectoryAccess {
  @override
  Future<LocalDirectoryGrant?> pickDirectory() async {
    final path = await getDirectoryPath(confirmButtonText: '选择音乐文件夹');
    if (path == null) return null;
    return _grantForPath(path, LocalDirectoryAccessStatus.available);
  }

  @override
  Future<LocalDirectoryGrant> restoreDirectory({
    required String rootUri,
    permissionToken,
  }) async {
    final uri = Uri.tryParse(rootUri);
    if (uri == null || uri.scheme != 'file') {
      return LocalDirectoryGrant(
        rootUri: rootUri,
        displayName: rootUri,
        status: LocalDirectoryAccessStatus.unavailable,
      );
    }
    final path = uri.toFilePath(windows: Platform.isWindows);
    final exists = await Directory(path).exists();
    return _grantForPath(
      path,
      exists
          ? LocalDirectoryAccessStatus.available
          : LocalDirectoryAccessStatus.unavailable,
    );
  }

  @override
  Future<void> releaseDirectory(String rootUri) async {}

  LocalDirectoryGrant _grantForPath(
    String path,
    LocalDirectoryAccessStatus status,
  ) {
    final uri = Uri.directory(path, windows: Platform.isWindows);
    final displayName = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .lastOrNull;
    return LocalDirectoryGrant(
      rootUri: uri.toString(),
      displayName: displayName ?? path,
      status: status,
    );
  }
}
