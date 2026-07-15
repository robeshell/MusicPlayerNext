import '../domain/library_models.dart';

class PlaybackMediaAccessRule {
  const PlaybackMediaAccessRule({
    required this.baseUri,
    this.headers = const {},
    this.allowBadCertificate = false,
  });

  final Uri baseUri;
  final Map<String, String> headers;
  final bool allowBadCertificate;
}

abstract interface class PlaybackMediaAccessSink {
  void updatePlaybackMediaAccess(List<PlaybackMediaAccessRule> rules);
}

class PlaybackMediaResource {
  const PlaybackMediaResource({
    required this.uri,
    this.headers = const {},
    this.allowBadCertificate = false,
    this.cacheKey,
    this.cache,
  });

  final Uri uri;
  final Map<String, String> headers;
  final bool allowBadCertificate;
  final String? cacheKey;
  final Future<void> Function()? cache;
}

abstract interface class PlaybackMediaProvider {
  bool supports(Track track);

  Future<PlaybackMediaResource?> resolve(
    Track track, {
    required bool preferLocalFile,
  });
}

class PlaybackMediaProviderRegistry implements PlaybackMediaAccessSink {
  PlaybackMediaProviderRegistry(Iterable<PlaybackMediaProvider> providers)
    : _providers = List.unmodifiable(providers);

  factory PlaybackMediaProviderRegistry.direct() {
    return PlaybackMediaProviderRegistry(const [DirectPlaybackMediaProvider()]);
  }

  final List<PlaybackMediaProvider> _providers;

  Future<PlaybackMediaResource?> resolve(
    Track track, {
    required bool preferLocalFile,
  }) async {
    for (final provider in _providers) {
      if (!provider.supports(track)) continue;
      final resource = await provider.resolve(
        track,
        preferLocalFile: preferLocalFile,
      );
      if (resource != null) return resource;
    }
    return null;
  }

  @override
  void updatePlaybackMediaAccess(List<PlaybackMediaAccessRule> rules) {
    for (final provider in _providers) {
      if (provider case PlaybackMediaAccessSink sink) {
        sink.updatePlaybackMediaAccess(rules);
      }
    }
  }
}

class DirectPlaybackMediaProvider implements PlaybackMediaProvider {
  const DirectPlaybackMediaProvider();

  @override
  bool supports(Track track) => true;

  @override
  Future<PlaybackMediaResource?> resolve(
    Track track, {
    required bool preferLocalFile,
  }) async {
    final value = track.mediaUri?.trim();
    if (value == null || value.isEmpty) return null;

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.scheme.isNotEmpty) {
      if (parsed.scheme == 'file') {
        return PlaybackMediaResource(uri: Uri.file(parsed.toFilePath()));
      }
      return PlaybackMediaResource(uri: parsed);
    }
    return PlaybackMediaResource(uri: Uri.file(value));
  }
}
