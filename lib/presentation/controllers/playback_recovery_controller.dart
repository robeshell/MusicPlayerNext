import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/app_failure.dart';
import '../../domain/library_models.dart';
import '../../playback/playback_controller.dart';
import '../../playback/playback_engine.dart';
import 'app_diagnostics_controller.dart';

class PlaybackRecoveryController extends ChangeNotifier
    with WidgetsBindingObserver {
  PlaybackRecoveryController(
    this._playback,
    this._diagnostics, {
    this.beforeRetry,
    List<Duration> retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
  }) : _retryDelays = List.unmodifiable(retryDelays) {
    _playback.addListener(_handlePlaybackChanged);
    WidgetsBinding.instance.addObserver(this);
    _handlePlaybackChanged();
  }

  final SoundPlaybackController _playback;
  final AppDiagnosticsController _diagnostics;
  final Future<void> Function()? beforeRetry;
  final List<Duration> _retryDelays;
  Timer? _retryTimer;
  int _attempt = 0;
  String? _lastErrorIdentity;
  bool _retrying = false;
  bool _disposed = false;

  bool get isRetrying => _retrying;
  int get automaticAttempt => _attempt;
  bool get hasScheduledRetry => _retryTimer != null;

  void _handlePlaybackChanged() {
    final snapshot = _playback.snapshot;
    if (snapshot.phase != PlaybackPhase.error) {
      if (snapshot.phase == PlaybackPhase.playing ||
          snapshot.phase == PlaybackPhase.paused) {
        _retryTimer?.cancel();
        _retryTimer = null;
        _attempt = 0;
        _lastErrorIdentity = null;
      }
      return;
    }

    final raw = snapshot.errorMessage ?? '播放引擎发生未知错误';
    final identity = '${snapshot.sessionId}:${snapshot.track?.id}:$raw';
    if (_lastErrorIdentity == identity) return;
    _lastErrorIdentity = identity;
    final failure = AppFailure.fromMessage(raw);
    _diagnostics.record(
      area: DiagnosticArea.playback,
      failure: failure,
      context: snapshot.track == null
          ? null
          : '${snapshot.track!.title} · ${snapshot.track!.artist}',
    );
    if (snapshot.track?.source == SourceKind.webDav && failure.isTransient) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null || _retrying || _attempt >= _retryDelays.length) {
      return;
    }
    final delay = _retryDelays[_attempt++];
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(retryNow(automatic: true));
    });
    notifyListeners();
  }

  Future<void> retryNow({bool automatic = false}) async {
    if (_retrying || _playback.displayTrack == null) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retrying = true;
    notifyListeners();
    var scheduleAnotherAttempt = false;
    try {
      await beforeRetry?.call();
      await _playback.retryCurrent();
    } catch (error) {
      final failure = AppFailure.from(error);
      _diagnostics.record(
        area: DiagnosticArea.playback,
        failure: failure,
        context: automatic ? '自动恢复第 $_attempt 次' : '手动重试',
      );
      scheduleAnotherAttempt = automatic && failure.isTransient;
    } finally {
      _retrying = false;
      if (!_disposed) {
        if (scheduleAnotherAttempt) _scheduleRetry();
        notifyListeners();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final snapshot = _playback.snapshot;
    if (snapshot.phase == PlaybackPhase.error &&
        AppFailure.fromMessage(snapshot.errorMessage ?? '未知错误').isTransient) {
      unawaited(retryNow());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _playback.removeListener(_handlePlaybackChanged);
    _retryTimer?.cancel();
    super.dispose();
  }
}
