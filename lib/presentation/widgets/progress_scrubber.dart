import 'package:flutter/material.dart';

class ProgressScrubber extends StatefulWidget {
  const ProgressScrubber({
    required this.position,
    required this.duration,
    required this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.trackHeight = 3,
    this.thumbRadius = 5,
    this.overlayRadius = 14,
    this.padding,
    super.key,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final double trackHeight;
  final double thumbRadius;
  final double overlayRadius;
  final EdgeInsetsGeometry? padding;

  @override
  State<ProgressScrubber> createState() => _ProgressScrubberState();
}

class _ProgressScrubberState extends State<ProgressScrubber> {
  double? _previewMilliseconds;

  double get _durationMs =>
      widget.duration.inMilliseconds.toDouble().clamp(1, double.infinity);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.duration > Duration.zero;
    final engineValue = widget.position.inMilliseconds.toDouble();
    final displayValue = (_previewMilliseconds ?? engineValue)
        .clamp(0, _durationMs)
        .toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: widget.trackHeight,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: widget.thumbRadius,
        ),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: widget.overlayRadius,
        ),
        inactiveTrackColor:
            widget.inactiveColor ?? Colors.white.withValues(alpha: 0.16),
      ),
      child: Slider(
        value: displayValue,
        max: _durationMs,
        padding: widget.padding,
        activeColor: widget.activeColor ?? Colors.white,
        onChanged: enabled
            ? (value) => setState(() => _previewMilliseconds = value)
            : null,
        onChangeEnd: enabled
            ? (value) {
                setState(() => _previewMilliseconds = null);
                widget.onSeek(Duration(milliseconds: value.round()));
              }
            : null,
      ),
    );
  }
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
