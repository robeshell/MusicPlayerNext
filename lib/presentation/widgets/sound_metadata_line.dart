import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';

/// Tappable artist / album metadata used across list rows, mini player and
/// now-playing. Parent row activation (play) still owns the surrounding hit
/// target; these spans only intercept their own text.
class SoundMetadataLine extends StatefulWidget {
  const SoundMetadataLine({
    required this.artist,
    required this.album,
    this.onOpenArtist,
    this.onOpenAlbum,
    this.separator = ' · ',
    this.style,
    this.linkStyle,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String artist;
  final String album;
  final VoidCallback? onOpenArtist;
  final VoidCallback? onOpenAlbum;
  final String separator;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int maxLines;
  final TextAlign textAlign;

  @override
  State<SoundMetadataLine> createState() => _SoundMetadataLineState();
}

class _SoundMetadataLineState extends State<SoundMetadataLine> {
  TapGestureRecognizer? _artistRecognizer;
  TapGestureRecognizer? _albumRecognizer;

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant SoundMetadataLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onOpenArtist != widget.onOpenArtist ||
        oldWidget.onOpenAlbum != widget.onOpenAlbum) {
      _disposeRecognizers();
      _syncRecognizers();
    }
  }

  void _syncRecognizers() {
    if (widget.onOpenArtist != null) {
      _artistRecognizer = TapGestureRecognizer()
        ..onTap = widget.onOpenArtist;
    }
    if (widget.onOpenAlbum != null) {
      _albumRecognizer = TapGestureRecognizer()..onTap = widget.onOpenAlbum;
    }
  }

  void _disposeRecognizers() {
    _artistRecognizer?.dispose();
    _albumRecognizer?.dispose();
    _artistRecognizer = null;
    _albumRecognizer = null;
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.style ??
        TextStyle(
          color: context.soundMutedText.withValues(
            alpha: context.soundMutedText.a * 0.82,
          ),
          fontSize: 11.5,
        );
    // Prefer weight over underline so dense 64px rows do not overflow.
    final link =
        widget.linkStyle ??
        base.copyWith(
          color: context.soundSecondaryText.withValues(
            alpha: context.soundSecondaryText.a * 0.94,
          ),
          fontWeight: FontWeight.w700,
        );
    final artist = widget.artist.trim().isEmpty ? '未知艺人' : widget.artist.trim();
    final album = widget.album.trim().isEmpty ? '未知专辑' : widget.album.trim();

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: artist,
            style: widget.onOpenArtist == null ? base : link,
            recognizer: _artistRecognizer,
            mouseCursor: widget.onOpenArtist == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
          ),
          TextSpan(text: widget.separator),
          TextSpan(
            text: album,
            style: widget.onOpenAlbum == null ? base : link,
            recognizer: _albumRecognizer,
            mouseCursor: widget.onOpenAlbum == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
          ),
        ],
      ),
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.textAlign,
    );
  }
}
