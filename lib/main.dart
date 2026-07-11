import 'package:flutter/widgets.dart';

import 'app/sound_app.dart';
import 'playback/just_audio_playback_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SoundApp(engine: JustAudioPlaybackEngine()));
}
