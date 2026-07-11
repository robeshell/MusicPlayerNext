import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/app/sound_app.dart';
import 'package:sound_player/playback/simulated_playback_engine.dart';
import 'package:sound_player/presentation/widgets/mini_player.dart';

void main() {
  testWidgets('starts on the retained library design shell', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(SoundApp(engine: SimulatedPlaybackEngine()));

    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('资料库'), findsWidgets);
    expect(find.text('最近添加'), findsWidgets);
    expect(find.text('范特西'), findsWidgets);
  });

  testWidgets('compact mini player sits just above bottom navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(SoundApp(engine: SimulatedPlaybackEngine()));

    final miniPlayerBottom = tester.getBottomLeft(find.byType(MiniPlayer)).dy;
    final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;

    expect(navigationTop - miniPlayerBottom, 10);
  });
}
