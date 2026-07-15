import 'package:flutter/foundation.dart';

import '../../domain/library_models.dart';
import '../../playback/playback_media_provider.dart';
import 'webdav_cache.dart';

class WebDavPlaybackMediaProvider
    implements PlaybackMediaProvider, PlaybackMediaAccessSink {
  WebDavPlaybackMediaProvider({this.cache});

  final WebDavCache? cache;
  List<PlaybackMediaAccessRule> _accessRules = const [];

  @override
  bool supports(Track track) => track.source == SourceKind.webDav;

  @override
  void updatePlaybackMediaAccess(List<PlaybackMediaAccessRule> rules) {
    _accessRules = List.unmodifiable(rules);
  }

  @override
  Future<PlaybackMediaResource?> resolve(
    Track track, {
    required bool preferLocalFile,
  }) async {
    final value = track.mediaUri?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    final access = _accessFor(uri);
    final mediaCache = cache;
    var cachedPath = mediaCache == null ? null : await mediaCache.get(value);
    if (cachedPath == null &&
        preferLocalFile &&
        access.allowBadCertificate &&
        mediaCache != null) {
      try {
        cachedPath = await mediaCache.download(
          value,
          headers: access.headers,
          allowBadCertificate: true,
        );
      } catch (error) {
        debugPrint(
          'Precise remote media preparation failed; falling back to stream: '
          '$error',
        );
      }
    }
    if (cachedPath != null) {
      return PlaybackMediaResource(uri: Uri.file(cachedPath));
    }

    return PlaybackMediaResource(
      uri: uri,
      headers: access.headers,
      allowBadCertificate: access.allowBadCertificate,
      cacheKey: value,
      cache: mediaCache == null
          ? null
          : () => mediaCache.download(
              value,
              headers: access.headers,
              allowBadCertificate: access.allowBadCertificate,
            ),
    );
  }

  _ResolvedPlaybackAccess _accessFor(Uri resource) {
    PlaybackMediaAccessRule? best;
    for (final rule in _accessRules) {
      if (_contains(rule.baseUri, resource) &&
          (best == null ||
              rule.baseUri.path.length > best.baseUri.path.length)) {
        best = rule;
      }
    }
    return _ResolvedPlaybackAccess(
      headers: best?.headers ?? const {},
      allowBadCertificate: best?.allowBadCertificate ?? false,
    );
  }

  bool _contains(Uri base, Uri resource) {
    if (base.scheme.toLowerCase() != resource.scheme.toLowerCase() ||
        base.host.toLowerCase() != resource.host.toLowerCase() ||
        base.port != resource.port) {
      return false;
    }
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    return resource.path.startsWith(basePath);
  }
}

class _ResolvedPlaybackAccess {
  const _ResolvedPlaybackAccess({
    required this.headers,
    required this.allowBadCertificate,
  });

  final Map<String, String> headers;
  final bool allowBadCertificate;
}
