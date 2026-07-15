import '../../domain/library_models.dart';
import '../../offline/offline_media_provider.dart';
import 'webdav_cache.dart';

/// WebDAV implementation of the protocol-neutral offline media boundary.
class WebDavOfflineMediaProvider implements OfflineMediaProvider {
  WebDavOfflineMediaProvider({required this.cache});

  final WebDavCache cache;
  Map<String, Map<String, String>> _authHeaders = const {};
  Set<String> _allowBadCertificateUrls = const {};

  @override
  String get id => 'webdav';

  @override
  String get displayName => 'WebDAV';

  void updateAccess({
    required Map<String, Map<String, String>> authHeaders,
    required Iterable<String> allowBadCertificateUrls,
  }) {
    _authHeaders = Map<String, Map<String, String>>.unmodifiable({
      for (final entry in authHeaders.entries)
        entry.key: Map<String, String>.unmodifiable(entry.value),
    });
    _allowBadCertificateUrls = Set.unmodifiable(allowBadCertificateUrls);
  }

  @override
  bool supports(Track track) {
    final mediaUri = track.mediaUri;
    if (track.source != SourceKind.webDav || mediaUri == null) return false;
    final uri = Uri.tryParse(mediaUri);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  OfflineMediaReference referenceFor(Track track) {
    if (!supports(track)) {
      throw ArgumentError.value(track.mediaUri, 'track', 'Not a WebDAV track');
    }
    return OfflineMediaReference(providerId: id, resourceId: track.mediaUri!);
  }

  @override
  Future<OfflineStorageStats> stats() async {
    final value = await cache.stats();
    return OfflineStorageStats(
      totalBytes: value.totalBytes,
      pinnedBytes: value.pinnedBytes,
      transientBytes: value.transientBytes,
      totalEntries: value.totalEntries,
      pinnedEntries: value.pinnedEntries,
    );
  }

  @override
  Future<List<OfflineStoredMedia>> items() async {
    return [
      for (final item in await cache.items())
        OfflineStoredMedia(
          reference: OfflineMediaReference(
            providerId: id,
            resourceId: item.url,
          ),
          path: item.path,
          size: item.size,
          pinned: item.pinned,
          accessedAt: item.accessedAt,
        ),
    ];
  }

  @override
  Future<String> pin(
    Track track, {
    OfflineDownloadProgressCallback? onProgress,
  }) async {
    final reference = referenceFor(track);
    try {
      return await cache.pin(
        reference.resourceId,
        headers: _headersFor(reference.resourceId),
        allowBadCertificate: _allowsBadCertificate(reference.resourceId),
        onProgress: onProgress == null
            ? null
            : (progress) => onProgress(
                OfflineDownloadProgress(
                  receivedBytes: progress.receivedBytes,
                  totalBytes: progress.totalBytes,
                ),
              ),
      );
    } on WebDavDownloadCancelledException {
      throw const OfflineDownloadCancelledException();
    }
  }

  @override
  bool cancel(OfflineMediaReference reference, {bool includePending = false}) {
    _checkReference(reference);
    return cache.cancel(reference.resourceId, includePending: includePending);
  }

  @override
  Future<bool> remove(OfflineMediaReference reference) {
    _checkReference(reference);
    return cache.remove(reference.resourceId);
  }

  @override
  Future<int> clearTransient() => cache.clearTransient();

  @override
  Future<int> clearAll() => cache.clear(includePinned: true);

  bool _allowsBadCertificate(String mediaUrl) {
    final media = Uri.tryParse(mediaUrl);
    if (media == null) return false;
    return _allowBadCertificateUrls.any((baseUrl) {
      final base = Uri.tryParse(baseUrl);
      if (base == null ||
          media.scheme.toLowerCase() != base.scheme.toLowerCase() ||
          media.host.toLowerCase() != base.host.toLowerCase() ||
          media.port != base.port) {
        return false;
      }
      final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
      return media.path == base.path || media.path.startsWith(basePath);
    });
  }

  Map<String, String> _headersFor(String mediaUrl) {
    final media = Uri.tryParse(mediaUrl);
    if (media == null) return const {};
    String? bestKey;
    for (final key in _authHeaders.keys) {
      final base = Uri.tryParse(key);
      if (base == null ||
          media.scheme.toLowerCase() != base.scheme.toLowerCase() ||
          media.host.toLowerCase() != base.host.toLowerCase() ||
          media.port != base.port) {
        continue;
      }
      final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
      if ((media.path == base.path || media.path.startsWith(basePath)) &&
          (bestKey == null || key.length > bestKey.length)) {
        bestKey = key;
      }
    }
    return bestKey == null ? const {} : _authHeaders[bestKey]!;
  }

  void _checkReference(OfflineMediaReference reference) {
    if (reference.providerId != id) {
      throw ArgumentError.value(reference.providerId, 'reference.providerId');
    }
  }
}
