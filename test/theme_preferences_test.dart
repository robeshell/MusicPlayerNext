import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/app/theme_preferences.dart';
import 'package:sound_player/core/sound_theme.dart';

void main() {
  late Directory supportDirectory;

  setUp(() async {
    SoundColors.defaultAccentPreset.apply();
    supportDirectory = await Directory.systemTemp.createTemp(
      'sound-theme-preferences-',
    );
  });

  tearDown(() async {
    SoundColors.defaultAccentPreset.apply();
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test(
    'persists a preset without mutating the live application theme',
    () async {
      final preferences = await ThemePreferences.load(
        supportDirectory: supportDirectory,
      );
      final violet = SoundColors.accentPresets.firstWhere(
        (preset) => preset.id == 'violet',
      );
      await preferences.save(
        accentPreset: violet,
        skinPreset: SoundSkins.deepNight,
      );

      SoundColors.defaultAccentPreset.apply();
      final restored = await ThemePreferences.load(
        supportDirectory: supportDirectory,
      );

      expect(restored.selectedAccentPreset, same(violet));
      expect(restored.selectedSkinPreset, same(SoundSkins.deepNight));
      expect(SoundColors.accent, SoundColors.defaultAccentPreset.accent);
    },
  );

  test('falls back safely when the stored preset is unknown', () async {
    await File(
      '${supportDirectory.path}/theme.json',
    ).writeAsString('{"accentPreset":"missing"}');

    final restored = await ThemePreferences.load(
      supportDirectory: supportDirectory,
    );

    expect(
      restored.selectedAccentPreset,
      same(SoundColors.defaultAccentPreset),
    );
    expect(restored.selectedSkinPreset, same(SoundSkins.defaultPreset));
  });

  test('migrates an accent-only preference to the default skin', () async {
    await File(
      '${supportDirectory.path}/theme.json',
    ).writeAsString('{"accentPreset":"indigo"}');

    final restored = await ThemePreferences.load(
      supportDirectory: supportDirectory,
    );

    expect(restored.selectedAccentPreset.id, 'indigo');
    expect(restored.selectedSkinPreset, same(SoundSkins.standard));
  });

  test('migrates the temporary warm-mist skin identifier', () async {
    await File(
      '${supportDirectory.path}/theme.json',
    ).writeAsString('{"accentPreset":"coral","skinPreset":"warm-mist"}');

    final restored = await ThemePreferences.load(
      supportDirectory: supportDirectory,
    );

    expect(restored.selectedSkinPreset, same(SoundSkins.standard));
  });
}
