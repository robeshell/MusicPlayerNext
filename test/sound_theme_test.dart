import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/core/sound_theme.dart';

void main() {
  test('light theme exposes the approved warm glass tokens', () {
    final theme = SoundTheme.light;
    final glass = theme.extension<SoundGlassTheme>();

    expect(theme.scaffoldBackgroundColor, SoundColors.lightCanvas);
    expect(theme.colorScheme.primary, SoundColors.accent);
    expect(theme.colorScheme.outline.a, closeTo(0.08, 0.005));
    expect(theme.colorScheme.outlineVariant.a, closeTo(0.055, 0.005));
    expect(
      theme.colorScheme.outlineVariant.a,
      lessThan(theme.colorScheme.outline.a),
    );
    expect(glass, isNotNull);
    expect(glass?.surface.a, closeTo(0.72, 0.01));
    expect(glass?.strongSurface.a, closeTo(0.87, 0.01));
    expect(glass?.primaryText, const Color(0xFF1C1C22));
    expect(glass?.secondaryText, const Color(0xFF5A5A62));
    expect(glass?.mutedText, const Color(0xFF77747D));
    expect(glass?.blur, 20);
    expect(glass?.strongBlur, 28);
    expect(theme.chipTheme.disabledColor?.a, lessThan(0.04));
    final fill = theme.filledButtonTheme.style?.backgroundColor;
    expect(fill?.resolve({WidgetState.hovered}), SoundColors.accentHover);
    expect(fill?.resolve({WidgetState.pressed}), SoundColors.accentPressed);
  });
}
