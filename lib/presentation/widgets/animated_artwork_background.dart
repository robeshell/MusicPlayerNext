import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final artworkUri = album.artworkUri?.trim();
    if (artworkUri == null || artworkUri.isEmpty) return;
    final provider = artworkImageProvider(
      artworkUri,
      cacheWidth: artworkPaletteCacheExtent,
      cacheHeight: artworkPaletteCacheExtent,
    );
    if (provider == null) return;
    final requestKey = '$artworkUri|${brightness.name}';
    await _AnimatedArtworkBackgroundState._cachedScheme(
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
    with SingleTickerProviderStateMixin {
  static final Map<String, Future<ColorScheme>> _schemeCache = {};
  static const _cacheLimit = 64;

  late List<Color> _colors;
  late final AnimationController _motionController;
  Brightness? _brightness;
  String? _requestKey;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _colors = _fallbackColors(widget.album, Brightness.light);
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
      value: _positionPhase(widget.position),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_brightness != brightness) {
      _brightness = brightness;
      _loadArtworkColors();
    }
    _reduceMotion = reduceMotion;
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
      position.inMilliseconds.remainder(14000) / 14000;

  Future<void> _loadArtworkColors() async {
    final brightness = _brightness ?? Theme.of(context).brightness;
    final artworkUri = widget.album.artworkUri?.trim();
    final fallback = _fallbackColors(widget.album, brightness);
    final requestKey = '${artworkUri ?? widget.album.id}|${brightness.name}';
    _requestKey = requestKey;

    if (mounted) _transitionTo(fallback);
    if (artworkUri == null || artworkUri.isEmpty) return;

    final provider = artworkImageProvider(
      artworkUri,
      cacheWidth: artworkPaletteCacheExtent,
      cacheHeight: artworkPaletteCacheExtent,
    );
    if (provider == null) return;

    try {
      final scheme = await _cachedScheme(requestKey, provider, brightness);
      if (!mounted || _requestKey != requestKey) return;
      _transitionTo(artworkGradientColorsFromScheme(scheme, brightness));
    } catch (error) {
      // Broken, unavailable, or unsupported artwork keeps the deterministic
      // album fallback. Playback should never fail because palette extraction
      // could not complete.
      if (kDebugMode) {
        debugPrint('Artwork palette extraction failed for $artworkUri: $error');
      }
    }
  }

  void _transitionTo(List<Color> colors) {
    if (listEquals(_colors, colors)) return;
    setState(() => _colors = colors);
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

    return RepaintBoundary(
      key: const ValueKey('now-playing-artwork-background'),
      child: CustomPaint(
        key: const ValueKey('now-playing-background-base'),
        painter: ArtworkGradientPainter(
          colors: _colors,
          motion: _motionController,
          reduceMotion: _reduceMotion,
          brightness: brightness,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
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
  }) : super(repaint: motion);

  final List<Color> colors;
  final Animation<double> motion;
  final bool reduceMotion;
  final Brightness brightness;

  double get phase => reduceMotion ? 0 : motion.value * math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = LinearGradient(
      begin: Alignment(
        -0.82 + math.sin(phase * 0.72) * 0.34,
        -0.9 + math.cos(phase * 0.58) * 0.22,
      ),
      end: Alignment(
        0.82 + math.cos(phase * 0.68) * 0.34,
        0.9 + math.sin(phase * 0.52) * 0.22,
      ),
      colors: colors,
      stops: const [0, 0.52, 1],
    );
    canvas.drawRect(rect, Paint()..shader = base.createShader(rect));

    final first = RadialGradient(
      center: Alignment(
        -0.48 + math.sin(phase) * 0.46,
        -0.52 + math.cos(phase * 0.83) * 0.38,
      ),
      radius: 0.86,
      colors: [
        colors[2].withValues(alpha: 0.90),
        colors[2].withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = first.createShader(rect));

    final second = RadialGradient(
      center: Alignment(
        0.54 + math.cos(phase * 0.71) * 0.42,
        0.42 + math.sin(phase * 0.91) * 0.44,
      ),
      radius: 0.96,
      colors: [
        colors[0].withValues(alpha: 0.72),
        colors[0].withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = second.createShader(rect));

    canvas.drawRect(
      rect,
      Paint()
        ..color = brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(ArtworkGradientPainter oldDelegate) {
    return oldDelegate.brightness != brightness ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.motion != motion ||
        !listEquals(oldDelegate.colors, colors);
  }
}

@visibleForTesting
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

List<Color> _fallbackColors(Album album, Brightness brightness) {
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
