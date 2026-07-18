import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../domain/library_models.dart';
import 'artwork_image_provider.dart';

/// A restrained, content-aware background for the now-playing screen.
///
/// Colors are extracted from the same artwork provider used by the album art.
/// Motion is derived from the current playback position, so the gradient moves
/// while playback updates and naturally settles when playback pauses.
class AnimatedArtworkBackground extends StatefulWidget {
  const AnimatedArtworkBackground({
    required this.album,
    required this.position,
    required this.isPlaying,
    super.key,
  });

  final Album album;
  final Duration position;
  final bool isPlaying;

  /// Starts the bounded artwork decode and palette extraction before the
  /// now-playing route is opened. The route can still paint its deterministic
  /// fallback immediately when this future has not completed yet.
  static Future<void> prewarm({
    required Album album,
    required Brightness brightness,
  }) async {
    await colorSchemeForAlbum(album: album, brightness: brightness);
  }

  /// Returns the cached Material color scheme extracted from [album]'s cover.
  /// Album pages and the now-playing background share this path so opening one
  /// surface also warms the other without decoding the artwork twice.
  static Future<ColorScheme?> colorSchemeForAlbum({
    required Album album,
    required Brightness brightness,
  }) async {
    final artworkUri = album.artworkUri?.trim();
    if (artworkUri == null || artworkUri.isEmpty) return null;
    final provider = artworkImageProvider(
      artworkUri,
      cacheWidth: artworkPaletteCacheExtent,
      cacheHeight: artworkPaletteCacheExtent,
    );
    if (provider == null) return null;
    final requestKey = '$artworkUri|${brightness.name}';
    return _AnimatedArtworkBackgroundState._cachedScheme(
      requestKey,
      provider,
      brightness,
    );
  }

  @visibleForTesting
  static bool debugHasPrewarmed({
    required Album album,
    required Brightness brightness,
  }) {
    final artworkUri = album.artworkUri?.trim();
    if (artworkUri == null || artworkUri.isEmpty) return false;
    return _AnimatedArtworkBackgroundState._schemeCache.containsKey(
      '$artworkUri|${brightness.name}',
    );
  }

  @override
  State<AnimatedArtworkBackground> createState() =>
      _AnimatedArtworkBackgroundState();
}

class _AnimatedArtworkBackgroundState extends State<AnimatedArtworkBackground>
    with TickerProviderStateMixin {
  static final Map<String, Future<ColorScheme>> _schemeCache = {};
  static const _cacheLimit = 64;

  late List<Color> _fromColors;
  late List<Color> _targetColors;
  late final AnimationController _motionController;
  late final AnimationController _paletteController;
  Brightness? _brightness;
  String? _requestKey;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _targetColors = artworkFallbackGradientColors(
      widget.album,
      Brightness.light,
    );
    _fromColors = List<Color>.of(_targetColors);
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
      value: 0,
    );
    _motionController.value = _positionPhase(widget.position);
    _paletteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final effects = context.soundSkinEffects;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _reduceMotion = reduceMotion;
    _motionController.duration = effects.motionDuration;
    _paletteController.duration = effects.paletteTransitionDuration;
    if (_brightness != brightness) {
      _brightness = brightness;
      _loadArtworkColors();
    }
    _syncMotion();
  }

  @override
  void didUpdateWidget(AnimatedArtworkBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.album.artworkUri != widget.album.artworkUri ||
        oldWidget.album.id != widget.album.id) {
      _loadArtworkColors();
    }
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _motionController.value = _positionPhase(widget.position);
      }
      _syncMotion();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _loadArtworkColors();
  }

  void _syncMotion() {
    if (_reduceMotion || !widget.isPlaying) {
      _motionController.stop();
      if (_reduceMotion) _motionController.value = 0;
      return;
    }
    if (!_motionController.isAnimating) _motionController.repeat();
  }

  double _positionPhase(Duration position) =>
      position.inMilliseconds.remainder(
        _motionController.duration?.inMilliseconds ?? 14000,
      ) /
      (_motionController.duration?.inMilliseconds ?? 14000);

  Future<void> _loadArtworkColors() async {
    final brightness = _brightness ?? Theme.of(context).brightness;
    final artworkUri = widget.album.artworkUri?.trim();
    final fallback = artworkFallbackGradientColors(widget.album, brightness);
    final requestKey = '${artworkUri ?? widget.album.id}|${brightness.name}';
    _requestKey = requestKey;

    if (artworkUri == null || artworkUri.isEmpty) {
      if (mounted) _transitionTo(fallback);
      return;
    }

    try {
      final scheme = await AnimatedArtworkBackground.colorSchemeForAlbum(
        album: widget.album,
        brightness: brightness,
      );
      if (scheme == null) {
        if (mounted && _requestKey == requestKey) _transitionTo(fallback);
        return;
      }
      if (!mounted || _requestKey != requestKey) return;
      _transitionTo(artworkGradientColorsFromScheme(scheme, brightness));
    } catch (error) {
      // Broken, unavailable, or unsupported artwork keeps the deterministic
      // album fallback. Playback should never fail because palette extraction
      // could not complete.
      if (kDebugMode) {
        debugPrint('Artwork palette extraction failed for $artworkUri: $error');
      }
      if (mounted && _requestKey == requestKey) _transitionTo(fallback);
    }
  }

  void _transitionTo(List<Color> colors) {
    if (listEquals(_targetColors, colors)) return;
    final currentColors = _interpolatedColors;
    setState(() {
      _fromColors = currentColors;
      _targetColors = List<Color>.of(colors);
    });
    if (_reduceMotion) {
      _paletteController.value = 1;
    } else {
      _paletteController.forward(from: 0);
    }
  }

  List<Color> get _interpolatedColors {
    final progress = Curves.easeOutCubic.transform(_paletteController.value);
    return List<Color>.generate(
      _targetColors.length,
      (index) => Color.lerp(
        _fromColors[index.clamp(0, _fromColors.length - 1)],
        _targetColors[index],
        progress,
      )!,
      growable: false,
    );
  }

  static Future<ColorScheme> _cachedScheme(
    String key,
    ImageProvider<Object> provider,
    Brightness brightness,
  ) async {
    final cached = _schemeCache[key];
    if (cached != null) return cached;

    if (_schemeCache.length >= _cacheLimit) {
      _schemeCache.remove(_schemeCache.keys.first);
    }
    final future = ColorScheme.fromImageProvider(
      provider: provider,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    _schemeCache[key] = future;
    try {
      return await future;
    } catch (_) {
      _schemeCache.remove(key);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    final effects = context.soundSkinEffects;

    return RepaintBoundary(
      key: const ValueKey('now-playing-artwork-background'),
      child: AnimatedBuilder(
        animation: _paletteController,
        builder: (context, _) => CustomPaint(
          key: const ValueKey('now-playing-background-base'),
          painter: ArtworkGradientPainter(
            colors: _interpolatedColors,
            motion: _motionController,
            reduceMotion: _reduceMotion,
            brightness: brightness,
            motionStrength: effects.motionStrength,
            primaryGlowOpacity: effects.primaryGlowOpacity,
            secondaryGlowOpacity: effects.secondaryGlowOpacity,
            lightVeilOpacity: effects.lightVeilOpacity,
            darkVeilOpacity: effects.darkVeilOpacity,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    _paletteController.dispose();
    super.dispose();
  }
}

/// Palette generation never needs the full-resolution cover. Keeping this
/// bounded avoids decoding a multi-megapixel image during route animation.
@visibleForTesting
const artworkPaletteCacheExtent = 256;

@visibleForTesting
class ArtworkGradientPainter extends CustomPainter {
  const ArtworkGradientPainter({
    required this.colors,
    required this.motion,
    required this.reduceMotion,
    required this.brightness,
    this.motionStrength = 1,
    this.primaryGlowOpacity = 0.90,
    this.secondaryGlowOpacity = 0.72,
    this.lightVeilOpacity = 0.04,
    this.darkVeilOpacity = 0.12,
  }) : super(repaint: motion);

  final List<Color> colors;
  final Animation<double> motion;
  final bool reduceMotion;
  final Brightness brightness;
  final double motionStrength;
  final double primaryGlowOpacity;
  final double secondaryGlowOpacity;
  final double lightVeilOpacity;
  final double darkVeilOpacity;

  double get phase => reduceMotion ? 0 : motion.value * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = LinearGradient(
      begin: Alignment(
        -0.82 + math.sin(phase * 0.72) * 0.34 * motionStrength,
        -0.9 + math.cos(phase * 0.58) * 0.22 * motionStrength,
      ),
      end: Alignment(
        0.82 + math.cos(phase * 0.68) * 0.34 * motionStrength,
        0.9 + math.sin(phase * 0.52) * 0.22 * motionStrength,
      ),
      colors: colors,
      stops: const [0, 0.52, 1],
    );
    canvas.drawRect(rect, Paint()..shader = base.createShader(rect));

    final first = RadialGradient(
      center: Alignment(
        -0.48 + math.sin(phase) * 0.46 * motionStrength,
        -0.52 + math.cos(phase * 0.83) * 0.38 * motionStrength,
      ),
      radius: 0.86,
      colors: [
        colors[2].withValues(alpha: primaryGlowOpacity),
        colors[2].withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = first.createShader(rect));

    final second = RadialGradient(
      center: Alignment(
        0.54 + math.cos(phase * 0.71) * 0.42 * motionStrength,
        0.42 + math.sin(phase * 0.91) * 0.44 * motionStrength,
      ),
      radius: 0.96,
      colors: [
        colors[0].withValues(alpha: secondaryGlowOpacity),
        colors[0].withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = second.createShader(rect));

    canvas.drawRect(
      rect,
      Paint()
        ..color = brightness == Brightness.light
            ? Colors.white.withValues(alpha: lightVeilOpacity)
            : Colors.black.withValues(alpha: darkVeilOpacity),
    );
  }

  @override
  bool shouldRepaint(ArtworkGradientPainter oldDelegate) {
    return oldDelegate.brightness != brightness ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.motionStrength != motionStrength ||
        oldDelegate.primaryGlowOpacity != primaryGlowOpacity ||
        oldDelegate.secondaryGlowOpacity != secondaryGlowOpacity ||
        oldDelegate.lightVeilOpacity != lightVeilOpacity ||
        oldDelegate.darkVeilOpacity != darkVeilOpacity ||
        oldDelegate.motion != motion ||
        !listEquals(oldDelegate.colors, colors);
  }
}

List<Color> artworkGradientColorsFromScheme(
  ColorScheme scheme,
  Brightness brightness,
) {
  // Material's generated tertiary color is intentionally complementary. That
  // is useful for controls, but makes unrelated covers converge on the same
  // pair of hues (for example brown -> cyan and cyan -> brown). Keep all three
  // background stops in the artwork's dominant color family instead.
  final blended = Color.lerp(scheme.primary, scheme.secondary, 0.48)!;
  final analogous = _shiftHue(scheme.primary, 24);
  if (brightness == Brightness.light) {
    return [
      _tone(scheme.primary, saturation: 0.52, lightness: 0.77),
      _tone(blended, saturation: 0.34, lightness: 0.86),
      _tone(analogous, saturation: 0.52, lightness: 0.66),
    ];
  }
  return [
    _tone(scheme.primary, saturation: 0.48, lightness: 0.14),
    _tone(blended, saturation: 0.32, lightness: 0.10),
    _tone(analogous, saturation: 0.50, lightness: 0.24),
  ];
}

Color _shiftHue(Color color, double degrees) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

List<Color> artworkFallbackGradientColors(Album album, Brightness brightness) {
  final palette = album.palette.isEmpty
      ? const [Color(0xFF5E7774), Color(0xFF25302F)]
      : album.palette;
  final first = palette.first;
  final last = palette.last;
  final middle = Color.lerp(first, last, 0.42)!;
  if (brightness == Brightness.light) {
    return [
      _tone(first, saturation: 0.34, lightness: 0.82),
      _tone(middle, saturation: 0.24, lightness: 0.88),
      _tone(last, saturation: 0.38, lightness: 0.76),
    ];
  }
  return [
    _tone(first, saturation: 0.34, lightness: 0.14),
    _tone(middle, saturation: 0.22, lightness: 0.10),
    _tone(last, saturation: 0.38, lightness: 0.22),
  ];
}

/// Contrast-safe colors shared by artwork-led detail pages.
@immutable
class ArtworkPagePalette {
  const ArtworkPagePalette({
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.divider,
    required this.controlSurface,
    required this.useLightText,
  });

  factory ArtworkPagePalette.fromBackground(List<Color> colors) {
    final sample = Color.lerp(
      Color.lerp(colors.first, colors[1], 0.58),
      colors.last,
      0.24,
    )!;
    final useLightText = sample.computeLuminance() < 0.34;
    final primary = useLightText
        ? Colors.white.withValues(alpha: 0.94)
        : const Color(0xEC17171C);
    final secondary = useLightText
        ? Colors.white.withValues(alpha: 0.76)
        : Colors.black.withValues(alpha: 0.64);
    final muted = useLightText
        ? Colors.white.withValues(alpha: 0.60)
        : Colors.black.withValues(alpha: 0.49);
    return ArtworkPagePalette(
      primaryText: primary,
      secondaryText: secondary,
      mutedText: muted,
      divider: primary.withValues(alpha: useLightText ? 0.15 : 0.10),
      controlSurface: primary.withValues(alpha: useLightText ? 0.13 : 0.075),
      useLightText: useLightText,
    );
  }

  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color divider;
  final Color controlSurface;
  final bool useLightText;
}

/// Softens extracted artwork colors into a restrained page background.
List<Color> artworkPageBackgroundColors(
  List<Color> source,
  Brightness brightness,
) {
  final safeSource = source.isEmpty
      ? const [Color(0xFF5E7774), Color(0xFF42514F), Color(0xFF25302F)]
      : source;
  final targetLightness = brightness == Brightness.light
      ? const [0.78, 0.83, 0.74]
      : const [0.18, 0.13, 0.23];
  return List<Color>.generate(3, (index) {
    final hsl = HSLColor.fromColor(safeSource[index % safeSource.length]);
    final saturation = brightness == Brightness.light
        ? (hsl.saturation * 0.52).clamp(0.12, 0.34).toDouble()
        : (hsl.saturation * 0.62).clamp(0.14, 0.42).toDouble();
    return hsl
        .withSaturation(saturation)
        .withLightness(targetLightness[index])
        .toColor();
  });
}

Color _tone(
  Color color, {
  required double saturation,
  required double lightness,
}) {
  final hsl = HSLColor.fromColor(color);
  final sourceSaturation = hsl.saturation.clamp(0.12, 0.64).toDouble();
  return hsl
      .withSaturation((sourceSaturation * 0.55 + saturation * 0.45).clamp(0, 1))
      .withLightness(lightness)
      .toColor();
}
