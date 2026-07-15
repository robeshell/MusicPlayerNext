abstract interface class PlaybackSessionStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<String?> readCheckpoint();

  Future<void> writeCheckpoint(String value);

  Future<void> clear();
}

class MemoryPlaybackSessionStorage implements PlaybackSessionStorage {
  String? _value;
  String? _checkpoint;

  @override
  Future<String?> read() async => _value;

  @override
  Future<String?> readCheckpoint() async => _checkpoint;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> writeCheckpoint(String value) async => _checkpoint = value;

  @override
  Future<void> clear() async {
    _value = null;
    _checkpoint = null;
  }
}
