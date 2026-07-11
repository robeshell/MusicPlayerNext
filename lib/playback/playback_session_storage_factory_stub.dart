import 'playback_session_storage_contract.dart';

Future<PlaybackSessionStorage> createDefaultPlaybackSessionStorage() async {
  return MemoryPlaybackSessionStorage();
}

PlaybackSessionStorage createPlaybackSessionStorageAt(String directory) {
  return MemoryPlaybackSessionStorage();
}
