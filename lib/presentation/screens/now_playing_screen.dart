import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_failure.dart';
import '../../core/sound_theme.dart';
import '../../domain/library_models.dart';
import '../../playback/playback_controller.dart';
import '../../playback/playback_mode.dart';
import '../../playback/lyrics_timeline.dart';
import '../controllers/library_user_state_controller.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/album_art.dart';
import '../widgets/animated_artwork_background.dart';
import '../widgets/playback_status_badge.dart';
import '../widgets/playback_queue_sheet.dart';
import '../widgets/progress_scrubber.dart';
import '../widgets/sound_components.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    required this.playback,
    this.userState,
    this.isActive = true,
    this.onClose,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    super.key,
  });

  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;

  /// Whether this surface should consume real-time playback ticks and animate
  /// its full-screen background. Mobile keeps this false while the surface is
  /// sliding on or off screen so route motion does not compete with playback
  /// position updates and a full-screen repaint on the same frames.
  final bool isActive;
  final VoidCallback? onClose;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;

  void _close(BuildContext context) {
    final close = onClose;
    if (close != null) {
      close();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // Keep this wrapper in the tree while mobile expansion is dragged.
      // Swapping between an AnimatedBuilder and its child replaces the whole
      // player subtree, which makes artwork and the gradient flash for a frame.
      child: AnimatedBuilder(
        animation: isActive
            ? Listenable.merge([playback, ?userState])
            : const _SilentListenable(),
        builder: (context, _) => _buildPlayer(context),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final track = playback.displayTrack;
    if (track == null) return _NoTrackPlaying(onClose: onClose);
    final album = albumForTrack(track);
    final snapshot = playback.snapshot;
    final compactChrome = context.soundIsCompact;
    final foldableChrome = context.soundUsesMobileShell && !compactChrome;
    return Scaffold(
      backgroundColor: album.palette.last,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedArtworkBackground(
            album: album,
            position: playback.displayPosition,
            isPlaying: snapshot.isPlaying && isActive,
          ),
          SafeArea(
            minimum: EdgeInsets.only(top: context.soundTitlebarInset),
            child: Column(
              children: [
                GestureDetector(
                  key: const ValueKey('now-playing-drag-handle'),
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: onVerticalDragStart,
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onVerticalDragEnd: onVerticalDragEnd,
                  onVerticalDragCancel: onVerticalDragCancel,
                  child: Padding(
                    padding: compactChrome
                        ? const EdgeInsets.fromLTRB(20, 4, 20, 8)
                        : foldableChrome
                        ? const EdgeInsets.fromLTRB(24, 0, 24, 2)
                        : const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _close(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () =>
                              showPlaybackQueueSheet(context, playback),
                          tooltip: '播放队列',
                          icon: const Icon(Icons.queue_music_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Open foldables are commonly around 700 logical
                      // pixels wide. Use that space for a centered
                      // two-pane player, with the crease falling inside
                      // the inter-pane gap.
                      final compact = constraints.maxWidth < 680;
                      if (compact) {
                        return _CompactNowPlaying(
                          album: album,
                          track: track,
                          playback: playback,
                          userState: userState,
                          onVerticalDragStart: onVerticalDragStart,
                          onVerticalDragUpdate: onVerticalDragUpdate,
                          onVerticalDragEnd: onVerticalDragEnd,
                          onVerticalDragCancel: onVerticalDragCancel,
                        );
                      }
                      return _WideNowPlaying(
                        album: album,
                        track: track,
                        playback: playback,
                        userState: userState,
                      );
                    },
                  ),
                ),
                if (snapshot.errorMessage case final message?)
                  _PlaybackErrorBanner(
                    message: message,
                    onRetry: playback.toggle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stable, inert animation source used while the mobile player is moving.
///
/// Keeping the same [AnimatedBuilder] element preserves the album artwork,
/// scroll position, and animated background state across drag boundaries.
class _SilentListenable implements Listenable {
  const _SilentListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _NoTrackPlaying extends StatelessWidget {
  const _NoTrackPlaying({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(top: context.soundTitlebarInset),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 10,
              child: IconButton.filledTonal(
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
            Center(
              child: Text(
                '当前没有正在播放的歌曲',
                style: TextStyle(color: context.soundSecondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideNowPlaying extends StatelessWidget {
  const _WideNowPlaying({
    required this.album,
    required this.track,
    required this.playback,
    this.userState,
  });

  final Album album;
  final Track track;
  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 50.0;
        const playerChromeHeight = 230.0;
        final foldableWidth = constraints.maxWidth < 780;
        final horizontalPadding = foldableWidth ? 24.0 : 44.0;
        final paneGap = math.max(
          foldableWidth ? 24.0 : 48.0,
          _centerDisplayFeatureGap(context, constraints),
        );
        final paneWidth = math.max(
          160.0,
          (constraints.maxWidth - horizontalPadding * 2 - paneGap) / 2,
        );
        final playerHeight = math.max(
          0.0,
          constraints.maxHeight - verticalPadding,
        );
        final artSize = math.min(
          math.min(340.0, paneWidth),
          math.max(160.0, playerHeight - playerChromeHeight),
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            foldableWidth ? 0 : 8,
            horizontalPadding,
            24,
          ),
          child: Row(
            crossAxisAlignment: foldableWidth
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  key: const ValueKey('wide-now-playing-player'),
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: SingleChildScrollView(
                      child: _PlayerColumn(
                        album: album,
                        track: track,
                        playback: playback,
                        userState: userState,
                        artSize: artSize,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: paneGap),
              Expanded(
                child: Padding(
                  key: const ValueKey('wide-now-playing-lyrics'),
                  padding: EdgeInsets.fromLTRB(
                    8, 6, 0, foldableWidth ? 24 : 0,
                  ),
                  child: _LyricsPanel(
                    track: track,
                    position: playback.displayPosition,
                    discontinuityRevision:
                        playback.positionDiscontinuityRevision,
                    onSeek: playback.seek,
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

double _centerDisplayFeatureGap(
  BuildContext context,
  BoxConstraints constraints,
) {
  var gap = 0.0;
  for (final feature in MediaQuery.of(context).displayFeatures) {
    final bounds = feature.bounds;
    final nearCenter =
        bounds.center.dx > constraints.maxWidth * 0.35 &&
        bounds.center.dx < constraints.maxWidth * 0.65;
    final vertical = bounds.height > constraints.maxHeight * 0.5;
    if (nearCenter && vertical) gap = math.max(gap, bounds.width + 16);
  }
  return gap;
}

class _CompactNowPlaying extends StatefulWidget {
  const _CompactNowPlaying({
    required this.album,
    required this.track,
    required this.playback,
    this.userState,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
  });

  final Album album;
  final Track track;
  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;

  @override
  State<_CompactNowPlaying> createState() => _CompactNowPlayingState();
}

class _CompactNowPlayingState extends State<_CompactNowPlaying> {
  bool _showLyrics = false;
  final ScrollController _coverScrollController = ScrollController();
  int? _coverPointer;
  double? _coverLastGlobalDy;
  bool _coverDismissGestureActive = false;

  void _handleCoverPointerDown(PointerDownEvent event) {
    _coverPointer = event.pointer;
    _coverLastGlobalDy = event.position.dy;
    _coverDismissGestureActive = false;
  }

  void _handleCoverPointerMove(PointerMoveEvent event) {
    if (_coverPointer != event.pointer || _coverLastGlobalDy == null) return;
    final delta = event.position.dy - _coverLastGlobalDy!;
    _coverLastGlobalDy = event.position.dy;
    if (!_coverDismissGestureActive) {
      final scrollOffset = _coverScrollController.hasClients
          ? _coverScrollController.offset
          : 0.0;
      if (delta <= 0 || scrollOffset > 0.5) return;
      _coverDismissGestureActive = true;
      widget.onVerticalDragStart?.call(
        DragStartDetails(
          globalPosition: event.position,
          localPosition: event.localPosition,
          sourceTimeStamp: event.timeStamp,
        ),
      );
    }
    widget.onVerticalDragUpdate?.call(
      DragUpdateDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        delta: Offset(0, delta),
        primaryDelta: delta,
        sourceTimeStamp: event.timeStamp,
      ),
    );
  }

  void _finishCoverPointer() {
    if (_coverDismissGestureActive) {
      _coverDismissGestureActive = false;
      widget.onVerticalDragEnd?.call(DragEndDetails());
    }
    _coverPointer = null;
    _coverLastGlobalDy = null;
  }

  void _cancelCoverPointer(PointerCancelEvent event) {
    if (_coverDismissGestureActive) {
      _coverDismissGestureActive = false;
      widget.onVerticalDragCancel?.call();
    }
    _coverPointer = null;
    _coverLastGlobalDy = null;
  }

  @override
  void dispose() {
    _coverScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      child: _showLyrics
          ? _CompactLyricsPlayer(
              key: const ValueKey('compact-lyrics'),
              album: widget.album,
              track: widget.track,
              playback: widget.playback,
              userState: widget.userState,
              onToggleLyrics: () => setState(() => _showLyrics = false),
              onVerticalDragStart: widget.onVerticalDragStart,
              onVerticalDragUpdate: widget.onVerticalDragUpdate,
              onVerticalDragEnd: widget.onVerticalDragEnd,
              onVerticalDragCancel: widget.onVerticalDragCancel,
            )
          : Listener(
              key: const ValueKey('now-playing-cover-drag-region'),
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handleCoverPointerDown,
              onPointerMove: _handleCoverPointerMove,
              onPointerUp: (_) => _finishCoverPointer(),
              onPointerCancel: _cancelCoverPointer,
              child: SingleChildScrollView(
                key: const ValueKey('compact-player'),
                controller: _coverScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _PlayerColumn(
                      album: widget.album,
                      track: widget.track,
                      playback: widget.playback,
                      userState: widget.userState,
                      compactLayout: true,
                      onToggleLyrics: () => setState(() => _showLyrics = true),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.album,
    required this.track,
    required this.playback,
    this.userState,
    this.artSize,
    this.compactLayout = false,
    this.onToggleLyrics,
  });

  final Album album;
  final Track track;
  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;
  final double? artSize;
  final bool compactLayout;
  final VoidCallback? onToggleLyrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlbumArt(
          key: compactLayout
              ? const ValueKey('compact-now-playing-artwork')
              : null,
          album: album,
          size: artSize,
          gaplessPlayback: true,
        ),
        SizedBox(height: compactLayout ? 26 : 24),
        if (compactLayout)
          _TrackChangeTransition(
            trackId: track.id,
            child: SizedBox(
              key: const ValueKey('now-playing-track-title'),
              width: double.infinity,
              child: Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _TrackChangeTransition(
                  trackId: track.id,
                  child: Text(
                    key: const ValueKey('now-playing-track-title'),
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              _NowPlayingActions(
                track: track,
                userState: userState,
                lyricsSelected: false,
                onToggleLyrics: onToggleLyrics,
              ),
            ],
          ),
        SizedBox(height: compactLayout ? 8 : 5),
        _TrackChangeTransition(
          trackId: track.id,
          child: Text(
            '${track.artist} — ${track.albumTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.soundSecondaryText, fontSize: 13),
          ),
        ),
        SizedBox(height: compactLayout ? 26 : 20),
        _PlaybackTimelineAndControls(
          key: compactLayout
              ? const ValueKey('compact-cover-playback-controls')
              : null,
          playback: playback,
        ),
        if (compactLayout) ...[
          const SizedBox(height: 24),
          _NowPlayingActions(
            key: const ValueKey('compact-now-playing-secondary-actions'),
            track: track,
            userState: userState,
            lyricsSelected: false,
            onToggleLyrics: onToggleLyrics,
            distributed: true,
          ),
        ],
      ],
    );
  }
}

class _TrackChangeTransition extends StatelessWidget {
  const _TrackChangeTransition({required this.trackId, required this.child});

  final String trackId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(trackId), child: child),
    );
  }
}

class _CompactLyricsPlayer extends StatelessWidget {
  const _CompactLyricsPlayer({
    required this.album,
    required this.track,
    required this.playback,
    required this.userState,
    required this.onToggleLyrics,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onVerticalDragCancel,
    super.key,
  });

  final Album album;
  final Track track;
  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;
  final VoidCallback onToggleLyrics;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: Column(
        children: [
          GestureDetector(
            key: const ValueKey('now-playing-expanded-drag-region'),
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: onVerticalDragStart,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onVerticalDragCancel: onVerticalDragCancel,
            child: Row(
              children: [
                AlbumArt(
                  key: const ValueKey('compact-lyrics-artwork'),
                  album: album,
                  size: 56,
                  borderRadius: 8,
                  showShadow: false,
                  gaplessPlayback: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TrackChangeTransition(
                        trackId: track.id,
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      _TrackChangeTransition(
                        trackId: track.id,
                        child: Text(
                          '${track.artist} — ${track.albumTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.soundSecondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              key: const ValueKey('compact-lyrics-region'),
              constraints: const BoxConstraints(maxHeight: 392),
              child: _LyricsPanel(
                track: track,
                position: playback.displayPosition,
                discontinuityRevision: playback.positionDiscontinuityRevision,
                onSeek: playback.seek,
                compact: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PlaybackTimelineAndControls(
            key: const ValueKey('compact-lyrics-playback-controls'),
            playback: playback,
          ),
          const SizedBox(height: 24),
          _NowPlayingActions(
            key: const ValueKey('compact-lyrics-secondary-actions'),
            track: track,
            userState: userState,
            lyricsSelected: true,
            onToggleLyrics: onToggleLyrics,
            distributed: true,
          ),
        ],
      ),
    );
  }
}

class _PlaybackTimelineAndControls extends StatelessWidget {
  const _PlaybackTimelineAndControls({required this.playback, super.key});

  final SoundPlaybackController playback;

  @override
  Widget build(BuildContext context) {
    final position = playback.displayPosition;
    final duration = playback.displayDuration;
    final visual = PlaybackVisualState.fromSnapshot(
      playback.snapshot,
      hasDisplayTrack: true,
    );
    final remaining = duration - position;
    final remainingLabel = duration > Duration.zero
        ? '-${formatDuration(remaining.isNegative ? Duration.zero : remaining)}'
        : '0:00';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressScrubber(
          position: position,
          duration: duration,
          onSeek: playback.seek,
        ),
        Row(
          children: [
            Text(formatDuration(position), style: _timeStyle(context)),
            const Spacer(),
            Text(remainingLabel, style: _timeStyle(context)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: playback.toggleShuffle,
              tooltip: PlaybackMode.shuffle.label,
              icon: const Icon(Icons.shuffle_rounded),
              color: playback.playbackMode == PlaybackMode.shuffle
                  ? SoundColors.accent
                  : null,
            ),
            IconButton(
              onPressed: playback.previous,
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 34,
            ),
            IconButton.filled(
              onPressed: visual.primaryEnabled ? playback.toggle : null,
              tooltip: visual.primaryTooltip,
              icon: visual.busy && !visual.primaryEnabled
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: context.soundSecondaryText,
                      ),
                    )
                  : Icon(visual.primaryIcon),
              iconSize: 34,
              style: IconButton.styleFrom(
                backgroundColor: context.soundPrimaryText,
                foregroundColor: context.soundGlass.canvasHighlight,
                fixedSize: const Size.square(52),
              ),
            ),
            IconButton(
              onPressed: playback.next,
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 34,
            ),
            IconButton(
              onPressed: playback.cycleRepeatMode,
              tooltip: playback.playbackMode.label,
              icon: Icon(
                playback.playbackMode == PlaybackMode.repeatOne
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
              ),
              color:
                  playback.playbackMode == PlaybackMode.repeatAll ||
                      playback.playbackMode == PlaybackMode.repeatOne
                  ? SoundColors.accent
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _NowPlayingActions extends StatelessWidget {
  const _NowPlayingActions({
    required this.track,
    required this.userState,
    required this.lyricsSelected,
    required this.onToggleLyrics,
    this.distributed = false,
    super.key,
  });

  final Track track;
  final LibraryUserStateController? userState;
  final bool lyricsSelected;
  final VoidCallback? onToggleLyrics;
  final bool distributed;

  @override
  Widget build(BuildContext context) {
    final state = userState;
    final isFavorite = state?.isFavorite(track.id) ?? false;
    return Row(
      mainAxisSize: distributed ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: distributed
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      textDirection: distributed ? TextDirection.rtl : TextDirection.ltr,
      children: [
        if (state != null)
          IconButton(
            key: ValueKey('favorite-now-playing-${track.id}'),
            onPressed: () => unawaited(state.toggleFavorite(track)),
            tooltip: isFavorite ? '取消收藏' : '收藏歌曲',
            color: isFavorite ? SoundColors.accent : null,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        if (state != null)
          IconButton(
            key: ValueKey('add-now-playing-${track.id}-to-playlist'),
            onPressed: () =>
                showAddToPlaylistSheet(context, userState: state, track: track),
            tooltip: '添加到播放列表',
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        if (onToggleLyrics != null)
          IconButton(
            key: ValueKey(
              lyricsSelected
                  ? 'return-now-playing-cover'
                  : 'show-now-playing-lyrics',
            ),
            onPressed: onToggleLyrics,
            tooltip: lyricsSelected ? '返回封面' : '查看歌词',
            color: lyricsSelected ? SoundColors.accent : null,
            icon: const Icon(Icons.lyrics_rounded),
          ),
      ],
    );
  }
}

class _PlaybackErrorBanner extends StatelessWidget {
  const _PlaybackErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = AppFailure.fromMessage(message);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: SoundGlassSurface(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          borderRadius: BorderRadius.circular(12),
          borderColor: SoundColors.accent.withValues(alpha: 0.52),
          blur: false,
          showShadow: false,
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: SoundColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      failure.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      failure.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.soundSecondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _timeStyle(BuildContext context) => TextStyle(
  color: context.soundSecondaryText,
  fontSize: 11,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class _LyricsPanel extends StatefulWidget {
  const _LyricsPanel({
    required this.track,
    required this.position,
    required this.discontinuityRevision,
    required this.onSeek,
    this.compact = false,
  });

  final Track track;
  final Duration position;
  final int discontinuityRevision;
  final Future<void> Function(Duration position) onSeek;
  final bool compact;

  @override
  State<_LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<_LyricsPanel> {
  static const _offsetStep = Duration(milliseconds: 500);
  static const _followDuration = Duration(milliseconds: 300);
  static const _manualScrollPause = Duration(seconds: 3);

  final _scrollController = ScrollController();
  late List<GlobalKey> _lineKeys;
  late LyricsTimeline _timeline;
  Duration _offset = Duration.zero;
  int? _lastActiveIndex;
  bool _snapNextFollow = false;
  bool _showingPreamble = true;
  bool _autoFollowPaused = false;
  Timer? _manualScrollTimer;

  Track get track => widget.track;

  @override
  void initState() {
    super.initState();
    _lineKeys = _keysFor(track.lyrics.length);
    _timeline = LyricsTimeline.forTrack(track);
  }

  @override
  void didUpdateWidget(covariant _LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != track.id) {
      _manualScrollTimer?.cancel();
      _offset = Duration.zero;
      _lastActiveIndex = null;
      _snapNextFollow = false;
      _showingPreamble = true;
      _autoFollowPaused = false;
      _lineKeys = _keysFor(track.lyrics.length);
      _timeline = LyricsTimeline.forTrack(track);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } else if (!identical(oldWidget.track.lyrics, track.lyrics)) {
      _lineKeys = _keysFor(track.lyrics.length);
      _timeline = LyricsTimeline.forTrack(track);
      _lastActiveIndex = null;
    } else if (widget.discontinuityRevision !=
            oldWidget.discontinuityRevision ||
        widget.position + const Duration(milliseconds: 500) <
            oldWidget.position) {
      // Seeks and repeat-one wraps cancel any old follow animation.
      _manualScrollTimer?.cancel();
      _autoFollowPaused = false;
      _snapNextFollow = true;
      _lastActiveIndex = null;
    }
  }

  @override
  void dispose() {
    _manualScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<GlobalKey> _keysFor(int length) =>
      List.generate(length, (index) => GlobalKey(debugLabel: 'lyric-$index'));

  void _followActiveLine(int active) {
    final cueStart = _timeline.cueStartIndex(active);
    if (_autoFollowPaused || _lastActiveIndex == cueStart) return;
    _showingPreamble = false;
    final snap = _snapNextFollow;
    _snapNextFollow = false;
    _lastActiveIndex = cueStart;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoFollowPaused || cueStart >= _lineKeys.length) {
        return;
      }
      final lineContext = _lineKeys[cueStart].currentContext;
      if (lineContext == null) return;
      Scrollable.ensureVisible(
        lineContext,
        alignment: 0.45,
        duration: snap ? Duration.zero : _followDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _followPreamble() {
    if (_autoFollowPaused || _showingPreamble) return;
    _showingPreamble = true;
    _lastActiveIndex = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _seekToLine(int index, LyricLine line) async {
    final timestamp = line.time;
    if (timestamp == null || !_timeline.isSeekable(index)) return;
    final target = timestamp - _offset;
    _resumeAutoFollow();
    await widget.onSeek(target.isNegative ? Duration.zero : target);
  }

  void _pauseAutoFollow() {
    if (!_timeline.isSynchronized) return;
    _manualScrollTimer?.cancel();
    if (!_autoFollowPaused && mounted) {
      setState(() => _autoFollowPaused = true);
    }
    _manualScrollTimer = Timer(_manualScrollPause, _resumeAutoFollow);
  }

  void _resumeAutoFollow() {
    _manualScrollTimer?.cancel();
    _manualScrollTimer = null;
    if (!mounted) return;
    setState(() {
      _autoFollowPaused = false;
      _snapNextFollow = true;
      _lastActiveIndex = null;
    });
  }

  void _changeOffset(Duration delta) {
    setState(() {
      _offset += delta;
      _lastActiveIndex = null;
      _showingPreamble = false;
      _snapNextFollow = true;
    });
  }

  String get _offsetLabel {
    final seconds = _offset.inMilliseconds / 1000;
    return '${seconds >= 0 ? '+' : ''}${seconds.toStringAsFixed(1)}s';
  }

  Widget _buildLyricLine(
    List<LyricLine> lyrics,
    int index, {
    required int? active,
    required bool synchronized,
  }) {
    final isActive = _timeline.isInCue(index, active);
    final line = lyrics[index];
    return GestureDetector(
      key: _lineKeys[index],
      behavior: HitTestBehavior.opaque,
      onTap: !_timeline.isSeekable(index)
          ? null
          : () => _seekToLine(index, line),
      // The cue must become visibly active on its timestamp. Animating the
      // text style here made a correct cue index appear roughly 320 ms late.
      child: AnimatedDefaultTextStyle(
        duration: Duration.zero,
        style: TextStyle(
          color: context.soundPrimaryText.withValues(
            alpha: isActive
                ? 1
                : active != null && index < active
                ? 0.28
                : 0.5,
          ),
          fontSize: isActive ? 22 : 20,
          height: synchronized ? 2.25 : 1.7,
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: -0.4,
        ),
        child: Text(line.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = track.lyrics;
    if (lyrics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '歌词',
            style: TextStyle(
              color: context.soundSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '这首歌曲没有内嵌歌词',
                style: TextStyle(color: context.soundSecondaryText),
              ),
            ),
          ),
        ],
      );
    }
    final synchronized = _timeline.isSynchronized;
    final active = synchronized
        ? _timeline.activeLineIndex(widget.position, offset: _offset)
        : null;
    if (active != null) {
      _followActiveLine(active);
    } else if (synchronized) {
      _followPreamble();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              synchronized && _timeline.hasTimedContent ? '同步歌词' : '歌词',
              style: TextStyle(
                color: context.soundSecondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (synchronized && _timeline.hasTimedContent) ...[
              const Spacer(),
              if (_autoFollowPaused) ...[
                _LyricsOffsetButton(
                  label: '回到当前',
                  tooltip: '恢复自动跟随',
                  onTap: _resumeAutoFollow,
                ),
                const SizedBox(width: 8),
              ],
              _LyricsOffsetButton(
                label: '−0.5',
                tooltip: '歌词延后 0.5 秒',
                onTap: () => _changeOffset(-_offsetStep),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: _offset == Duration.zero
                      ? null
                      : () => setState(() {
                          _offset = Duration.zero;
                          _lastActiveIndex = null;
                          _snapNextFollow = true;
                        }),
                  child: Text(
                    _offsetLabel,
                    style: TextStyle(
                      color: _offset == Duration.zero
                          ? context.soundSecondaryText.withValues(alpha: 0.68)
                          : context.soundSecondaryText,
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              _LyricsOffsetButton(
                label: '+0.5',
                tooltip: '歌词提前 0.5 秒',
                onTap: () => _changeOffset(_offsetStep),
              ),
            ],
          ],
        ),
        SizedBox(height: widget.compact ? 12 : 26),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) _pauseAutoFollow();
              },
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (notification) {
                  if (notification.dragDetails != null) _pauseAutoFollow();
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: widget.compact
                        ? math.max(72, constraints.maxHeight * 0.34)
                        : math.max(110, constraints.maxHeight * 0.45),
                    bottom: widget.compact
                        ? math.max(72, constraints.maxHeight * 0.66)
                        : math.max(110, constraints.maxHeight * 0.55),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < lyrics.length; index++)
                        _buildLyricLine(
                          lyrics,
                          index,
                          active: active,
                          synchronized: synchronized,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LyricsOffsetButton extends StatelessWidget {
  const _LyricsOffsetButton({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.soundTint(0.06),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                color: context.soundSecondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
