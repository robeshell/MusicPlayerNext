import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/library_models.dart';
import 'album_art.dart';

/// A skeuomorphic vinyl record used by the vinyl now-playing style.
///
/// The record spins only while [isPlaying] is true, [isActive] is true, and
/// the platform is not requesting reduced motion. Pausing freezes the disc
/// mid-revolution; deactivating the surface (e.g. while the mobile player is
/// sliding) freezes spin without lifting the tonearm. The white tonearm pivots
/// above the platter: it swings down onto the record when playback starts and
/// lifts back to its rest position above the right rim when it pauses.
class VinylRecordArt extends StatefulWidget {
  const VinylRecordArt({
    required this.album,
    required this.isPlaying,
    this.isActive = true,
    this.size,
    super.key,
  });

  final Album album;
  final bool isPlaying;

  /// When false, continuous disc rotation is frozen so route / expansion
  /// motion does not compete with the spin ticker. Tonearm pose still follows
  /// [isPlaying].
  final bool isActive;

  /// Square extent of the whole composition (record plus tonearm). When null,
  /// the widget sizes itself from its layout constraints like [AlbumArt].
  final double? size;

  @override
  State<VinylRecordArt> createState() => VinylRecordArtState();
}

class VinylRecordArtState extends State<VinylRecordArt>
    with SingleTickerProviderStateMixin {
  /// One revolution of the record. Real 33⅓ rpm is ~1.8s/turn; we keep a
  /// calmer on-screen pace so the disc reads as continuous motion, not a blur.
  static const _revolutionDuration = Duration(seconds: 14);

  static const _armSwingDuration = Duration(milliseconds: 700);

  /// Diameter of the record relative to the widget side (tonearm needs a
  /// little headroom above the platter).
  static const _discFraction = 0.88;

  /// Diameter of the center label (the album artwork) relative to the record.
  /// Kept in lockstep with [_VinylDiscPainter.labelFrameRadius].
  static const _labelFraction = _VinylDiscPainter.labelFrameRadius;

  /// Platter sits slightly below center so the arm has room, but not so low
  /// that the disc hugs the title under the art block.
  static const _discCenterFraction = Offset(0.5, 0.54);

  /// Tonearm pivot just above the larger platter.
  static const _armPivotFraction = Offset(0.48, 0.055);

  /// Arm paint box size relative to the widget side (must match [build]).
  static const _armBoxFraction = 0.75;

  /// Clockwise turns from rest so the cartridge sits on the mid-line of the
  /// black groove ring (halfway between label rim 0.66r and outer surface
  /// 0.94r → 0.80r). Derived from pivot / disc geometry and [_TonearmPainter]
  /// rest offsets — do not hand-tune independently of those constants.
  static final double _armPlayTurns = _armPlayTurnsForGrooveCenter();

  /// Solve the play angle for a unit-side composition.
  static double _armPlayTurnsForGrooveCenter() {
    const side = 1.0;
    final discRadius = side * _discFraction / 2;
    // Mid-line of the matte black band (label frame → outer surface).
    final targetRadius =
        discRadius *
        (_VinylDiscPainter.labelFrameRadius +
            _VinylDiscPainter.outerSurfaceRadius) /
        2;
    final discCenter = Offset(
      side * _discCenterFraction.dx,
      side * _discCenterFraction.dy,
    );
    final pivot = Offset(
      side * _armPivotFraction.dx,
      side * _armPivotFraction.dy,
    );
    final unit = side * _armBoxFraction;
    // Rest-pose cartridge center in pivot-local space (see [_TonearmPainter]).
    final cartLocal = _TonearmPainter.cartridgeCenterFromPivot(unit);
    // Search the first half-turn for the landing on the upper-right groove.
    var bestTurns = 0.056;
    var bestError = double.infinity;
    for (var i = 0; i <= 2000; i++) {
      final turns = i / 2000 * 0.5;
      final theta = turns * 2 * math.pi;
      final cosT = math.cos(theta);
      final sinT = math.sin(theta);
      // Flutter positive rotation is clockwise with y-down.
      final world = pivot +
          Offset(
            cartLocal.dx * cosT - cartLocal.dy * sinT,
            cartLocal.dx * sinT + cartLocal.dy * cosT,
          );
      final error = ((world - discCenter).distance - targetRadius).abs();
      if (error < bestError) {
        bestError = error;
        bestTurns = turns;
      }
    }
    return bestTurns;
  }

  late final AnimationController _rotation;
  bool _reduceMotion = false;

  /// Whether the disc rotation ticker is currently running.
  @visibleForTesting
  bool get isDiscSpinning => _rotation.isAnimating;

  /// Current disc angle in turns (0..1), for freeze-resume assertions.
  @visibleForTesting
  double get discTurns => _rotation.value;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: _revolutionDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
    }
    _syncRotation();
  }

  @override
  void didUpdateWidget(covariant VinylRecordArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying ||
        widget.isActive != oldWidget.isActive) {
      _syncRotation();
    }
  }

  void _syncRotation() {
    final shouldSpin =
        widget.isPlaying && widget.isActive && !_reduceMotion;
    if (shouldSpin) {
      if (!_rotation.isAnimating) _rotation.repeat();
    } else {
      // Freeze mid-revolution; resuming picks up where the record stopped.
      _rotation.stop();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final armDuration = _reduceMotion ? Duration.zero : _armSwingDuration;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = widget.size ?? constraints.biggest.shortestSide;
        final side = available.isFinite && available > 0 ? available : 240.0;
        final discDiameter = side * _discFraction;
        final labelDiameter = discDiameter * _labelFraction;
        final discCenter = Offset(
          side * _discCenterFraction.dx,
          side * _discCenterFraction.dy,
        );
        final armPivot = Offset(
          side * _armPivotFraction.dx,
          side * _armPivotFraction.dy,
        );
        // The tonearm rotates around the center of its paint box, so the box
        // is centered on the pivot. The arm and headshell stay inside the
        // widget; only transparent corners of the box overflow.
        final armBox = side * _armBoxFraction;
        return SizedBox.square(
          key: const ValueKey('vinyl-record-art'),
          dimension: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: discCenter.dx - discDiameter / 2,
                top: discCenter.dy - discDiameter / 2,
                child: RotationTransition(
                  turns: _rotation,
                  child: SizedBox.square(
                    dimension: discDiameter,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: CustomPaint(painter: _VinylDiscPainter()),
                        ),
                        Center(
                          child: ClipOval(
                            child: AlbumArt(
                              album: widget.album,
                              size: labelDiameter,
                              borderRadius: 0,
                              showShadow: false,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: armPivot.dx - armBox / 2,
                top: armPivot.dy - armBox / 2,
                child: AnimatedRotation(
                  turns: widget.isPlaying ? _armPlayTurns : 0,
                  duration: armDuration,
                  curve: Curves.easeOutCubic,
                  child: CustomPaint(
                    size: Size.square(armBox),
                    painter: _TonearmPainter(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VinylDiscPainter extends CustomPainter {
  const _VinylDiscPainter();

  /// Label radius relative to the record radius: the label diameter is
  /// [VinylRecordArtState._labelFraction] of the record diameter, so its
  /// edge sits at the same fraction of the record radius.
  static const labelFrameRadius = 0.66;

  /// Outer matte black surface radius relative to the record radius.
  static const outerSurfaceRadius = 0.94;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Raised outer bezel ring, slightly lighter than the record itself.
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF26262B));
    canvas.drawCircle(
      center,
      radius - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // Matte black record surface.
    canvas.drawCircle(
      center,
      radius * outerSurfaceRadius,
      Paint()..color = const Color(0xFF0E0E10),
    );

    // Barely-there grooves; the reference record reads almost smooth.
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.03);
    for (var r = radius * 0.72; r < radius * 0.90; r += radius * 0.045) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Thin dark ring framing the label.
    canvas.drawCircle(
      center,
      radius * (labelFrameRadius + 0.012),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.022
        ..color = const Color(0xFF050506),
    );

    // Gloss: two soft reflection bands (brighter upper-left, fainter
    // lower-right) sweeping around the record. Painted inside the rotating
    // subtree, so the sheen travels with the disc.
    canvas.drawCircle(
      center,
      radius * outerSurfaceRadius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
            Colors.transparent,
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.09, 0.20, 0.58, 0.70, 0.83],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_VinylDiscPainter oldPainter) => false;
}

class _TonearmPainter extends CustomPainter {
  const _TonearmPainter();

  static const _armColor = Color(0xFFF2F2F4);

  /// Rest-pose offset of the arm/headshell joint from the pivot, in [unit]
  /// multiples (must match [paint]).
  static const tipFromPivot = Offset(0.413, 0.18);

  /// Rest-pose elbow from the pivot, in [unit] multiples.
  static const elbowFromPivot = Offset(0.205, 0.163);

  /// Cartridge center sits this far past the tip joint along the last segment.
  static const cartridgePastTip = 0.055;

  /// World offset of the cartridge center from the pivot at rest.
  static Offset cartridgeCenterFromPivot(double unit) {
    final tip = Offset(tipFromPivot.dx * unit, tipFromPivot.dy * unit);
    final elbow = Offset(elbowFromPivot.dx * unit, elbowFromPivot.dy * unit);
    final seg2 = tip - elbow;
    final dir = seg2 / seg2.distance;
    return tip + dir * (cartridgePastTip * unit);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = size.center(Offset.zero);
    final unit = size.shortestSide;
    // Rest position: the headshell hovers above the record's right rim.
    final tip = pivot + Offset(tipFromPivot.dx * unit, tipFromPivot.dy * unit);

    // Bent-tube shape: two straight segments meeting at a rounded elbow —
    // long steep section out of the pivot, short near-level section into
    // the cartridge.
    final elbow =
        pivot + Offset(elbowFromPivot.dx * unit, elbowFromPivot.dy * unit);
    final seg1 = elbow - pivot;
    final seg2 = tip - elbow;
    // Trim both segments at the elbow and bridge the gap with a quadratic
    // curve, so the bend reads as a rounded corner instead of a hard angle.
    final trim = unit * 0.035;
    final before = elbow - seg1 / seg1.distance * trim;
    final after = elbow + seg2 / seg2.distance * trim;
    final armPath = Path()
      ..moveTo(pivot.dx, pivot.dy)
      ..lineTo(before.dx, before.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy, after.dx, after.dy)
      ..lineTo(tip.dx, tip.dy);
    canvas.drawPath(
      armPath,
      Paint()
        ..color = _armColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.028
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Cartridge: a clean white block aligned with the second segment,
    // separated from the arm tube by a thin gap.
    final tangentAngle = math.atan2(tip.dy - elbow.dy, tip.dx - elbow.dx);
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(tangentAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(unit * cartridgePastTip, 0),
          width: unit * 0.11,
          height: unit * 0.046,
        ),
        Radius.circular(unit * 0.010),
      ),
      Paint()..color = _armColor,
    );
    canvas.drawLine(
      Offset(unit * 0.006, -unit * 0.020),
      Offset(unit * 0.006, unit * 0.020),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = unit * 0.008
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // Pivot cap.
    canvas.drawCircle(pivot, unit * 0.040, Paint()..color = _armColor);
    canvas.drawCircle(
      pivot,
      unit * 0.040,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.007
        ..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      pivot,
      unit * 0.013,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_TonearmPainter oldPainter) => false;
}
