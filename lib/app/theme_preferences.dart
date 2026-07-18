import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/sound_theme.dart';

class ThemePreferences {
  ThemePreferences._(
    this._file,
    this.selectedAccentPreset,
    this.selectedSkinPreset,
  );

  final File _file;
  AccentPreset selectedAccentPreset;
  SoundSkinPreset selectedSkinPreset;

  /// Kept as a compatibility alias for callers created before skin support.
  AccentPreset get selectedPreset => selectedAccentPreset;

  static Future<ThemePreferences> load({Directory? supportDirectory}) async {
    final dir = supportDirectory ?? await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'theme.json'));
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final accentPresetId = json['accentPreset'] as String?;
        final storedSkinPresetId = json['skinPreset'] as String?;
        final skinPresetId = storedSkinPresetId == 'warm-mist'
            ? SoundSkins.defaultPreset.id
            : storedSkinPresetId;
        AccentPreset? accentPreset;
        for (final p in SoundColors.accentPresets) {
          if (p.id == accentPresetId) {
            accentPreset = p;
            break;
          }
        }
        SoundSkinPreset? skinPreset;
        for (final p in SoundSkins.presets) {
          if (p.id == skinPresetId) {
            skinPreset = p;
            break;
          }
        }
        return ThemePreferences._(
          file,
          accentPreset ?? SoundColors.defaultAccentPreset,
          skinPreset ?? SoundSkins.defaultPreset,
        );
      }
    } catch (_) {
      // Corrupted file — fall back to the original Reverie appearance.
    }
    return ThemePreferences._(
      file,
      SoundColors.defaultAccentPreset,
      SoundSkins.defaultPreset,
    );
  }

  Future<void> save({
    AccentPreset? accentPreset,
    SoundSkinPreset? skinPreset,
  }) async {
    final nextAccent = accentPreset ?? selectedAccentPreset;
    final nextSkin = skinPreset ?? selectedSkinPreset;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode({'accentPreset': nextAccent.id, 'skinPreset': nextSkin.id}),
      flush: true,
    );
    selectedAccentPreset = nextAccent;
    selectedSkinPreset = nextSkin;
  }
}
