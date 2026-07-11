import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'app/sound_app.dart';
import 'playback/just_audio_playback_engine.dart';
import 'playback/media_kit_playback_engine.dart';
import 'playback/playback_engine.dart';

const _engineName = String.fromEnvironment(
  'SOUND_ENGINE',
  defaultValue: 'just_audio',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final PlaybackEngine engine;
  if (_engineName == 'just_audio') {
    engine = JustAudioPlaybackEngine();
  } else {
    MediaKit.ensureInitialized();
    engine = MediaKitPlaybackEngine();
  }
  runApp(SoundApp(engine: engine));
}
