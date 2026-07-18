class AudioFormatDefinition {
  const AudioFormatDefinition({
    required this.extension,
    required this.contentType,
    required this.displayName,
    this.mimeAliases = const <String>[],
    this.metadataReaderSupported = true,
  });

  final String extension;
  final String contentType;
  final String displayName;
  final List<String> mimeAliases;

  /// Whether audio_metadata_reader can parse this container directly.
  ///
  /// Raw AAC is indexed through a validated filename fallback. AAC and ALAC
  /// inside M4A use the MP4 metadata parser.
  final bool metadataReaderSupported;
}

const supportedAudioFormats = <AudioFormatDefinition>[
  AudioFormatDefinition(
    extension: '.mp3',
    contentType: 'audio/mpeg',
    displayName: 'MP3',
    mimeAliases: <String>['audio/mp3'],
  ),
  AudioFormatDefinition(
    extension: '.flac',
    contentType: 'audio/flac',
    displayName: 'FLAC',
    mimeAliases: <String>['audio/x-flac'],
  ),
  AudioFormatDefinition(
    extension: '.m4a',
    contentType: 'audio/mp4',
    displayName: 'M4A (AAC/ALAC)',
    mimeAliases: <String>['audio/x-m4a', 'audio/m4a'],
  ),
  AudioFormatDefinition(
    extension: '.aac',
    contentType: 'audio/aac',
    displayName: 'AAC (ADTS)',
    mimeAliases: <String>['audio/x-aac'],
    metadataReaderSupported: false,
  ),
  AudioFormatDefinition(
    extension: '.wav',
    contentType: 'audio/wav',
    displayName: 'WAV',
    mimeAliases: <String>['audio/x-wav', 'audio/vnd.wave'],
  ),
  AudioFormatDefinition(
    extension: '.ogg',
    contentType: 'audio/ogg',
    displayName: 'Ogg Vorbis',
    mimeAliases: <String>['application/ogg'],
  ),
  AudioFormatDefinition(
    extension: '.opus',
    contentType: 'audio/ogg',
    displayName: 'Opus',
    mimeAliases: <String>['audio/opus'],
  ),
];

AudioFormatDefinition? audioFormatForPath(String value) {
  final path = _pathWithoutQueryOrFragment(value);
  if (isSystemMetadataPath(path)) return null;
  final lowerPath = path.toLowerCase();
  for (final format in supportedAudioFormats) {
    if (lowerPath.endsWith(format.extension)) return format;
  }
  return null;
}

/// Whether [value] points at metadata created by macOS rather than user media.
///
/// AppleDouble sidecars mirror the original filename as `._<name>` and can
/// therefore retain an audio extension such as `.mp3`. WebDAV servers commonly
/// expose them as regular files, but their contents are resource-fork metadata
/// and cannot be played as audio. `__MACOSX` is the equivalent metadata tree
/// produced when macOS archives are extracted.
bool isMacOSMetadataPath(String value) {
  final path = _pathWithoutQueryOrFragment(value).replaceAll('\\', '/');
  return path.split('/').any((segment) {
    final decoded = _decodePathSegment(segment).toLowerCase();
    return decoded.startsWith('._') || decoded == '__macosx';
  });
}

/// Whether [value] belongs to a well-known OS or NAS metadata-only tree.
///
/// These names are deliberately limited to high-confidence system folders.
/// General dotfiles, small files, and conflict copies are not rejected because
/// they can still be intentional user audio.
bool isSystemMetadataPath(String value) {
  final path = _pathWithoutQueryOrFragment(value).replaceAll('\\', '/');
  return path.split('/').any((segment) {
    final decoded = _decodePathSegment(segment).toLowerCase();
    return decoded.startsWith('._') ||
        decoded == '__macosx' ||
        decoded == r'$recycle.bin' ||
        decoded == 'system volume information' ||
        decoded == '.trashes' ||
        decoded.startsWith('.trash-') ||
        decoded == '.spotlight-v100' ||
        decoded == '.fseventsd' ||
        decoded == 'lost+found' ||
        decoded == '@eadir' ||
        decoded == '#recycle' ||
        decoded == '.@__thumb' ||
        decoded == '.@__qini' ||
        decoded == '.snapshot' ||
        decoded == '@recently-snapshot';
  });
}

/// Detects AppleSingle/AppleDouble metadata from bytes already fetched for
/// metadata extraction. Calling this never requires an additional read.
bool hasAppleMetadataHeader(List<int> bytes) {
  if (bytes.length < 4) return false;
  final magic =
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  return magic == 0x00051600 || magic == 0x00051607;
}

AudioFormatDefinition? audioFormatForMimeType(String? value) {
  final normalized = value?.split(';').first.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final format in supportedAudioFormats) {
    if (format.contentType == normalized ||
        format.mimeAliases.contains(normalized)) {
      return format;
    }
  }
  return null;
}

bool isSupportedAudioPath(String value) => audioFormatForPath(value) != null;

bool isSupportedAudioMimeType(String? value) =>
    audioFormatForMimeType(value) != null;

String? audioContentTypeForPath(String value) =>
    audioFormatForPath(value)?.contentType;

String audioExtensionForPath(String value) =>
    audioFormatForPath(value)?.extension ?? '';

String _pathWithoutQueryOrFragment(String value) {
  Uri? uri;
  try {
    uri = Uri.tryParse(value);
  } on ArgumentError {
    // WebDAV displayname is a plain filename, not necessarily a valid URI.
    // Literal percent characters (for example `100% Love.mp3`) must remain
    // usable as ordinary path text instead of aborting the whole scan.
  }
  if (uri != null && uri.hasScheme) return uri.path;
  final queryIndex = value.indexOf('?');
  final fragmentIndex = value.indexOf('#');
  final cutAt = <int>[
    if (queryIndex >= 0) queryIndex,
    if (fragmentIndex >= 0) fragmentIndex,
  ];
  if (cutAt.isEmpty) return value;
  cutAt.sort();
  return value.substring(0, cutAt.first);
}

String _decodePathSegment(String value) {
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  }
}
