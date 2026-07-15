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
  File get _checkpointFile =>
      File(p.join(directory, 'playback_session_checkpoint.json'));

  @override
  Future<String?> read() async {
    final file = _file;
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<String?> readCheckpoint() async {
    final file = _checkpointFile;
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
  Future<void> writeCheckpoint(String value) async {
    final file = _checkpointFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    final file = _file;
    if (await file.exists()) await file.delete();
    final checkpointFile = _checkpointFile;
    if (await checkpointFile.exists()) await checkpointFile.delete();
  }
}
