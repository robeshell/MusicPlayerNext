import 'dart:async';

import '../../library/library_records.dart';
import '../../library/library_repository.dart';
import 'local_directory_access.dart';

typedef UtcClock = DateTime Function();

class LocalSourceService {
  LocalSourceService({
    required this.repository,
    required this.directoryAccess,
    UtcClock? clock,
  }) : _clock = clock ?? _utcNow;

  final LibraryRepository repository;
  final LocalDirectoryAccess directoryAccess;
  final UtcClock _clock;

  Stream<List<LibrarySourceRecord>> watchLocalSources() {
    return repository.watchSources().map(
      (sources) => sources
          .where((source) => source.type == LibrarySourceType.local)
          .toList(growable: false),
    );
  }

  Future<LibrarySourceRecord?> addLocalFolder() async {
    final grant = await directoryAccess.pickDirectory();
    if (grant == null) return null;
    final now = _clock().toUtc();
    final id = stableLocalSourceId(grant.rootUri);
    final existing = await repository.getSource(id);
    final source = LibrarySourceRecord(
      id: id,
      type: LibrarySourceType.local,
      displayName: grant.displayName,
      rootUri: grant.rootUri,
      permissionBookmark: grant.permissionToken,
      status: _sourceStatus(grant.status),
      scanRevision: existing?.scanRevision ?? 0,
      lastScanStartedAt: existing?.lastScanStartedAt,
      lastScanCompletedAt: existing?.lastScanCompletedAt,
      lastError: grant.isAvailable ? null : '需要重新授权此文件夹。',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await repository.upsertSource(source);
    return source;
  }

  Future<void> restoreLocalFolders() async {
    final sources = await repository.getSources();
    for (final source in sources) {
      if (source.type != LibrarySourceType.local) continue;
      await _restore(source);
    }
  }

  Future<void> _restore(LibrarySourceRecord source) async {
    final now = _clock().toUtc();
    try {
      final grant = await directoryAccess.restoreDirectory(
        rootUri: source.rootUri,
        permissionToken: source.permissionBookmark,
      );
      await repository.upsertSource(
        LibrarySourceRecord(
          id: source.id,
          type: source.type,
          displayName: grant.displayName,
          rootUri: grant.rootUri,
          permissionBookmark:
              grant.permissionToken ?? source.permissionBookmark,
          status: _sourceStatus(grant.status),
          scanRevision: source.scanRevision,
          lastScanStartedAt: source.lastScanStartedAt,
          lastScanCompletedAt: source.lastScanCompletedAt,
          lastError: grant.isAvailable ? null : '文件夹不可用或授权已失效。',
          createdAt: source.createdAt,
          updatedAt: now,
        ),
      );
    } catch (error) {
      await repository.upsertSource(
        LibrarySourceRecord(
          id: source.id,
          type: source.type,
          displayName: source.displayName,
          rootUri: source.rootUri,
          permissionBookmark: source.permissionBookmark,
          status: LibrarySourceStatus.permissionRequired,
          scanRevision: source.scanRevision,
          lastScanStartedAt: source.lastScanStartedAt,
          lastScanCompletedAt: source.lastScanCompletedAt,
          lastError: error.toString(),
          createdAt: source.createdAt,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> removeLocalFolder(LibrarySourceRecord source) async {
    await directoryAccess.releaseDirectory(source.rootUri);
    await repository.deleteSource(source.id);
  }
}

String stableLocalSourceId(String rootUri) =>
    'local:${Uri.encodeComponent(rootUri)}';

LibrarySourceStatus _sourceStatus(LocalDirectoryAccessStatus status) {
  return switch (status) {
    LocalDirectoryAccessStatus.available => LibrarySourceStatus.available,
    LocalDirectoryAccessStatus.permissionRequired =>
      LibrarySourceStatus.permissionRequired,
    LocalDirectoryAccessStatus.unavailable ||
    LocalDirectoryAccessStatus.unsupported => LibrarySourceStatus.unavailable,
  };
}

DateTime _utcNow() => DateTime.now().toUtc();
