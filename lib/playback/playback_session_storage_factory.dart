import 'playback_session_storage_contract.dart';
import 'playback_session_storage_factory_stub.dart'
    if (dart.library.io) 'playback_session_storage_factory_io.dart'
    as implementation;

export 'playback_session_storage_contract.dart';

Future<PlaybackSessionStorage> createDefaultPlaybackSessionStorage() {
  return implementation.createDefaultPlaybackSessionStorage();
}

PlaybackSessionStorage createPlaybackSessionStorageAt(String directory) {
  return implementation.createPlaybackSessionStorageAt(directory);
}
