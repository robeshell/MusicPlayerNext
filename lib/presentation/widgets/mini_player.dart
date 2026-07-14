import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/library_models.dart';
import '../../playback/playback_controller.dart';
import '../controllers/library_user_state_controller.dart';
import 'album_art.dart';
import 'playback_status_badge.dart';
import 'progress_scrubber.dart';
import 'source_badge.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.playback,
    this.userState,
    required this.onOpen,
    required this.compact,
    this.onOpenQueue,
    super.key,
  });

  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;
  final VoidCallback onOpen;
  final bool compact;
  final VoidCallback? onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([playback, ?userState]),
      builder: (context, _) {
        final track = playback.displayTrack;
        if (track == null) return const SizedBox.shrink();
        final visual = PlaybackVisualState.fromSnapshot(
          playback.snapshot,
          hasDisplayTrack: true,
        );
        final album = albumForTrack(track);
        final position = playback.displayPosition;
        final duration = playback.displayDuration;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = !compact && constraints.maxWidth >= 900;
            final height = compact ? 72.0 : (wide ? 88.0 : 82.0);
            return ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 16 : 20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDE7).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(compact ? 16 : 20),
                    border: Border.all(
                      color: visual.primaryVisual == PlaybackPrimaryVisual.retry
                          ? visual.color.withValues(alpha: 0.68)
                          : Colors.white.withValues(alpha: 0.42),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: wide
                      ? _WideMiniPlayer(
                          track: track,
                          album: album,
                          visual: visual,
                          playback: playback,
                          userState: userState,
                          onOpen: onOpen,
                          onOpenQueue: onOpenQueue,
                          position: position,
                          duration: duration,
                        )
                      : _CondensedMiniPlayer(
                          track: track,
                          album: album,
                          visual: visual,
                          playback: playback,
                          onOpen: onOpen,
                          onOpenQueue: onOpenQueue,
                          position: position,
                          duration: duration,
                          compact: compact,
                          availableWidth: constraints.maxWidth,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WideMiniPlayer extends StatelessWidget {
  const _WideMiniPlayer({
    required this.track,
    required this.album,
    required this.visual,
    required this.playback,
    required this.userState,
    required this.onOpen,
    required this.onOpenQueue,
    required this.position,
    required this.duration,
  });

  final Track track;
  final Album album;
  final PlaybackVisualState visual;
  final SoundPlaybackController playback;
  final LibraryUserStateController? userState;
  final VoidCallback onOpen;
  final VoidCallback? onOpenQueue;
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _OpenArtwork(album: album, onOpen: onOpen, dimension: 58),
          const SizedBox(width: 13),
          Expanded(
            flex: 34,
            child: _TrackIdentity(
              track: track,
              visual: visual,
              onOpen: onOpen,
              showBadges: true,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            flex: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TransportControls(playback: playback, visual: visual),
                _MiniProgressRow(
                  playback: playback,
                  position: position,
                  duration: duration,
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 1,
            height: 38,
            color: Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 158,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (userState case final state?)
                  _MiniIconButton(
                    icon: state.isFavorite(track.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: state.isFavorite(track.id)
                        ? const Color(0xFFE84D67)
                        : null,
                    tooltip: state.isFavorite(track.id) ? '取消收藏' : '收藏歌曲',
                    onTap: () => unawaited(state.toggleFavorite(track)),
                  ),
                _MiniIconButton(
                  icon: Icons.lyrics_outlined,
                  tooltip: '打开歌词',
                  onTap: onOpen,
                ),
                _MiniIconButton(
                  icon: Icons.queue_music_rounded,
                  tooltip: '打开播放队列',
                  onTap: onOpenQueue ?? onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CondensedMiniPlayer extends StatelessWidget {
  const _CondensedMiniPlayer({
    required this.track,
    required this.album,
    required this.visual,
    required this.playback,
    required this.onOpen,
    required this.onOpenQueue,
    required this.position,
    required this.duration,
    required this.compact,
    required this.availableWidth,
  });

  final Track track;
  final Album album;
  final PlaybackVisualState visual;
  final SoundPlaybackController playback;
  final VoidCallback onOpen;
  final VoidCallback? onOpenQueue;
  final Duration position;
  final Duration duration;
  final bool compact;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final showPrevious = !compact && availableWidth >= 600;
    final showQueue = !compact && availableWidth >= 690;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 9 : 13, 7, 8, 13),
            child: Row(
              children: [
                _OpenArtwork(
                  album: album,
                  onOpen: onOpen,
                  dimension: compact ? 46 : 50,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _TrackIdentity(
                    track: track,
                    visual: visual,
                    onOpen: onOpen,
                    showBadges: false,
                  ),
                ),
                if (showPrevious)
                  _MiniIconButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: '上一首',
                    onTap: playback.previous,
                  ),
                _MiniIconButton(
                  key: const ValueKey('mini-player-playback-toggle'),
                  icon: visual.primaryIcon,
                  tooltip: visual.primaryTooltip,
                  onTap: visual.primaryEnabled ? playback.toggle : null,
                  prominent: true,
                  size: compact ? 22 : 23,
                ),
                _MiniIconButton(
                  icon: Icons.skip_next_rounded,
                  tooltip: '下一首',
                  onTap: playback.next,
                  size: 23,
                ),
                if (showQueue)
                  _MiniIconButton(
                    icon: Icons.queue_music_rounded,
                    tooltip: '打开播放队列',
                    onTap: onOpenQueue ?? onOpen,
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -3,
          height: 28,
          child: ProgressScrubber(
            key: const ValueKey('mini-player-progress'),
            position: position,
            duration: duration,
            onSeek: playback.seek,
            activeColor: const Color(0xD6000000),
            inactiveColor: Colors.black.withValues(alpha: 0.12),
            trackHeight: 2.5,
            thumbRadius: 3.5,
            overlayRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _OpenArtwork extends StatelessWidget {
  const _OpenArtwork({
    required this.album,
    required this.onOpen,
    required this.dimension,
  });

  final Album album;
  final VoidCallback onOpen;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '打开正在播放',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: dimension,
          child: AlbumArt(album: album, borderRadius: 7),
        ),
      ),
    );
  }
}

class _TrackIdentity extends StatelessWidget {
  const _TrackIdentity({
    required this.track,
    required this.visual,
    required this.onOpen,
    required this.showBadges,
  });

  final Track track;
  final PlaybackVisualState visual;
  final VoidCallback onOpen;
  final bool showBadges;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.9),
                fontSize: showBadges ? 15 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${track.artist} — ${track.albumTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.56),
                fontSize: showBadges ? 12 : 11,
              ),
            ),
            if (showBadges) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  PlaybackStatusBadge(
                    state: visual,
                    onLightSurface: true,
                    compact: true,
                  ),
                  const SizedBox(width: 7),
                  SourceBadge(track.source),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.playback, required this.visual});

  final SoundPlaybackController playback;
  final PlaybackVisualState visual;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniIconButton(
            icon: Icons.skip_previous_rounded,
            tooltip: '上一首',
            onTap: playback.previous,
            size: 23,
          ),
          const SizedBox(width: 4),
          _MiniIconButton(
            key: const ValueKey('mini-player-playback-toggle'),
            icon: visual.primaryIcon,
            tooltip: visual.primaryTooltip,
            onTap: visual.primaryEnabled ? playback.toggle : null,
            prominent: true,
            size: 24,
          ),
          const SizedBox(width: 4),
          _MiniIconButton(
            icon: Icons.skip_next_rounded,
            tooltip: '下一首',
            onTap: playback.next,
            size: 23,
          ),
        ],
      ),
    );
  }
}

class _MiniProgressRow extends StatelessWidget {
  const _MiniProgressRow({
    required this.playback,
    required this.position,
    required this.duration,
  });

  final SoundPlaybackController playback;
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final remaining = duration - position;
    final remainingLabel = duration > Duration.zero
        ? '-${formatDuration(remaining.isNegative ? Duration.zero : remaining)}'
        : '0:00';
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(formatDuration(position), style: _timeStyle),
          ),
          Expanded(
            child: ProgressScrubber(
              key: const ValueKey('mini-player-progress'),
              position: position,
              duration: duration,
              onSeek: playback.seek,
              activeColor: const Color(0xD6000000),
              inactiveColor: Colors.black.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbRadius: 4.5,
              overlayRadius: 13,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              remainingLabel,
              textAlign: TextAlign.end,
              style: _timeStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.onTap,
    this.size = 20,
    this.tooltip,
    this.color,
    this.prominent = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;
  final Color? color;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final foreground = prominent
        ? (onTap == null ? Colors.white38 : Colors.white)
        : color ??
              (onTap == null
                  ? const Color(0x52000000)
                  : const Color(0xD6000000));
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: foreground, size: size),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: prominent
          ? IconButton.styleFrom(
              backgroundColor: onTap == null
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.86),
              minimumSize: const Size.square(40),
              maximumSize: const Size.square(40),
              padding: EdgeInsets.zero,
            )
          : IconButton.styleFrom(
              minimumSize: const Size.square(40),
              maximumSize: const Size.square(40),
              padding: EdgeInsets.zero,
            ),
    );
  }
}

const _timeStyle = TextStyle(
  color: Color(0x84000000),
  fontSize: 10,
  fontFeatures: [FontFeature.tabularFigures()],
);
