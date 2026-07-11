abstract interface class PlaybackSessionStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

class MemoryPlaybackSessionStorage implements PlaybackSessionStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;
}
