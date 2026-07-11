import 'package:media_kit/media_kit.dart' as media_kit;

Future<bool> seekRemoteWithKeyframes(
  media_kit.Player player,
  Duration position,
) async {
  final platform = player.platform;
  if (platform is! media_kit.NativePlayer) return false;
  await platform.command([
    'seek',
    (position.inMilliseconds / 1000).toStringAsFixed(4),
    'absolute+keyframes',
  ]);
  return true;
}
