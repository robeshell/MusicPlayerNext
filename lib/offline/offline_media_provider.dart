import 'package:flutter/foundation.dart';

import '../domain/library_models.dart';

/// Stable identity for one remotely stored media object.
///
/// [providerId] identifies the protocol adapter (for example `webdav`), while
/// [resourceId] is private to that adapter. The offline feature never parses
/// the resource identifier or branches on a protocol.
@immutable
class OfflineMediaReference {
  const OfflineMediaReference({
    required this.providerId,
    required this.resourceId,
  });

  final String providerId;
  final String resourceId;

  String get storageKey => '$providerId:${Uri.encodeComponent(resourceId)}';

  @override
  bool operator ==(Object other) =>
      other is OfflineMediaReference &&
      other.providerId == providerId &&
      other.resourceId == resourceId;

  @override
  int get hashCode => Object.hash(providerId, resourceId);

  @override
  String toString() => '$providerId:$resourceId';
}

@immutable
class OfflineStorageStats {
  const OfflineStorageStats({
    required this.totalBytes,
    required this.pinnedBytes,
    required this.transientBytes,
    required this.totalEntries,
    required this.pinnedEntries,
  });

  static const empty = OfflineStorageStats(
    totalBytes: 0,
    pinnedBytes: 0,
    transientBytes: 0,
    totalEntries: 0,
    pinnedEntries: 0,
  );

  final int totalBytes;
  final int pinnedBytes;
  final int transientBytes;
  final int totalEntries;
  final int pinnedEntries;

  int get transientEntries => totalEntries - pinnedEntries;

  OfflineStorageStats operator +(OfflineStorageStats other) {
    return OfflineStorageStats(
      totalBytes: totalBytes + other.totalBytes,
      pinnedBytes: pinnedBytes + other.pinnedBytes,
      transientBytes: transientBytes + other.transientBytes,
      totalEntries: totalEntries + other.totalEntries,
      pinnedEntries: pinnedEntries + other.pinnedEntries,
    );
  }
}

@immutable
class OfflineStoredMedia {
  const OfflineStoredMedia({
    required this.reference,
    required this.path,
    required this.size,
    required this.pinned,
    required this.accessedAt,
  });

  final OfflineMediaReference reference;
  final String path;
  final int size;
  final bool pinned;
  final DateTime accessedAt;
}

@immutable
class OfflineDownloadProgress {
  const OfflineDownloadProgress({required this.receivedBytes, this.totalBytes});

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0, 1);
  }
}

typedef OfflineDownloadProgressCallback =
    void Function(OfflineDownloadProgress progress);

class OfflineDownloadCancelledException implements Exception {
  const OfflineDownloadCancelledException();

  @override
  String toString() => '下载已取消';
}

/// Protocol boundary used by the product-level offline download manager.
///
/// A future SMB, S3 or Subsonic implementation adds another provider instead
/// of adding protocol branches to screens or the download controller.
abstract interface class OfflineMediaProvider {
  String get id;

  String get displayName;

  bool supports(Track track);

  OfflineMediaReference referenceFor(Track track);

  Future<OfflineStorageStats> stats();

  Future<List<OfflineStoredMedia>> items();

  Future<String> pin(
    Track track, {
    OfflineDownloadProgressCallback? onProgress,
  });

  bool cancel(OfflineMediaReference reference, {bool includePending = false});

  Future<bool> remove(OfflineMediaReference reference);

  Future<int> clearTransient();

  Future<int> clearAll();
}
