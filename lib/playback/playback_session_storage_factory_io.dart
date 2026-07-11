import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'playback_session_storage_contract.dart';

Future<PlaybackSessionStorage> createDefaultPlaybackSessionStorage() async {
  final directory = await getApplicationDocumentsDirectory();
  return FilePlaybackSessionStorage(directory.path);
}

PlaybackSessionStorage createPlaybackSessionStorageAt(String directory) {
  return FilePlaybackSessionStorage(directory);
}

class FilePlaybackSessionStorage implements PlaybackSessionStorage {
  FilePlaybackSessionStorage(this.directory);

  final String directory;

  File get _file => File(p.join(directory, 'playback_session.json'));

  @override
  Future<String?> read() async {
    final file = _file;
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    final file = _file;
    if (await file.exists()) await file.delete();
  }
}
