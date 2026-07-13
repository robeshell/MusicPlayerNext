import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/core/sound_theme.dart';
import 'package:sound_player/presentation/widgets/sound_components.dart';

void main() {
  testWidgets('Sound dialog and navigation use branded components', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: SoundTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            bottomNavigationBar: SoundNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                SoundNavigationItem(
                  icon: Icons.album_outlined,
                  selectedIcon: Icons.album_rounded,
                  label: '资料库',
                ),
                SoundNavigationItem(
                  icon: Icons.search_rounded,
                  selectedIcon: Icons.search_rounded,
                  label: '搜索',
                ),
              ],
            ),
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => SoundDialog(
                    title: const Text('统一弹窗'),
                    content: const Text('内容保持 Sound 的视觉语言。'),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('完成'),
                      ),
                    ],
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SoundNavigationBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(SoundDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('统一弹窗'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('sound-dialog-content'))).width,
      lessThan(600),
    );
    expect(tester.takeException(), isNull);
  });

  test('global theme overrides platform-looking component defaults', () {
    final theme = SoundTheme.dark;
    expect(theme.splashFactory, same(NoSplash.splashFactory));
    expect(theme.dialogTheme.elevation, 0);
    expect(theme.popupMenuTheme.elevation, 0);
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
  });
}
