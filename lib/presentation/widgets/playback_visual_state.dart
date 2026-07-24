import 'package:flutter/material.dart';

import '../../playback/playback_engine.dart';

enum PlaybackPrimaryVisual { none, play, pause, replay, retry }

/// 引擎相位 → 传输按钮视觉（图标/可用性/忙碌态）的映射。
///
/// 播放状态由传输按钮图标、进度行为与错误横幅表达，
/// 不单独渲染状态徽章（2026-07 设计审计后移除）。
@immutable
class PlaybackVisualState {
  const PlaybackVisualState({
    required this.label,
    required this.primaryVisual,
    this.busy = false,
  });

  factory PlaybackVisualState.fromSnapshot(
    PlaybackSnapshot snapshot, {
    required bool hasDisplayTrack,
  }) {
    return switch (snapshot.phase) {
      PlaybackPhase.idle => PlaybackVisualState(
        label: hasDisplayTrack ? '等待播放' : '未播放',
        primaryVisual: hasDisplayTrack
            ? PlaybackPrimaryVisual.play
            : PlaybackPrimaryVisual.none,
      ),
      PlaybackPhase.loading => const PlaybackVisualState(
        label: '正在载入',
        primaryVisual: PlaybackPrimaryVisual.none,
        busy: true,
      ),
      PlaybackPhase.ready => const PlaybackVisualState(
        label: '已就绪',
        primaryVisual: PlaybackPrimaryVisual.play,
      ),
      PlaybackPhase.playing => const PlaybackVisualState(
        label: '正在播放',
        primaryVisual: PlaybackPrimaryVisual.pause,
      ),
      PlaybackPhase.paused => const PlaybackVisualState(
        label: '已暂停',
        primaryVisual: PlaybackPrimaryVisual.play,
      ),
      PlaybackPhase.buffering => PlaybackVisualState(
        label: '正在缓冲',
        primaryVisual: snapshot.isPlaying
            ? PlaybackPrimaryVisual.pause
            : PlaybackPrimaryVisual.play,
        busy: true,
      ),
      PlaybackPhase.completed => const PlaybackVisualState(
        label: '播放完成',
        primaryVisual: PlaybackPrimaryVisual.replay,
      ),
      PlaybackPhase.error => const PlaybackVisualState(
        label: '播放错误',
        primaryVisual: PlaybackPrimaryVisual.retry,
      ),
    };
  }

  final String label;
  final PlaybackPrimaryVisual primaryVisual;
  final bool busy;

  bool get primaryEnabled => primaryVisual != PlaybackPrimaryVisual.none;

  IconData get primaryIcon => switch (primaryVisual) {
    PlaybackPrimaryVisual.none => Icons.hourglass_empty_rounded,
    PlaybackPrimaryVisual.play => Icons.play_arrow_rounded,
    PlaybackPrimaryVisual.pause => Icons.pause_rounded,
    PlaybackPrimaryVisual.replay => Icons.replay_rounded,
    PlaybackPrimaryVisual.retry => Icons.refresh_rounded,
  };

  String get primaryTooltip => switch (primaryVisual) {
    PlaybackPrimaryVisual.none => label,
    PlaybackPrimaryVisual.play => '播放',
    PlaybackPrimaryVisual.pause => '暂停',
    PlaybackPrimaryVisual.replay => '重新播放',
    PlaybackPrimaryVisual.retry => '重试播放',
  };
}
