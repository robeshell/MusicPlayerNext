import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/library_models.dart';
import 'playback_controller.dart';

enum SleepTimerMode { off, duration, endOfTrack }

class SleepTimerController extends ChangeNotifier with WidgetsBindingObserver {
  SleepTimerController(this._playback, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _trackStartedSubscription = _playback.trackStarted.listen(
      _handleTrackStarted,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  final SoundPlaybackController _playback;
  final DateTime Function() _now;
  Timer? _deadlineTimer;
  Timer? _ticker;
  late final StreamSubscription<Track> _trackStartedSubscription;
  SleepTimerMode _mode = SleepTimerMode.off;
  DateTime? _deadline;
  String? _armedTrackId;
  bool _disposed = false;

  SleepTimerMode get mode => _mode;
  bool get isActive => _mode != SleepTimerMode.off;
  DateTime? get deadline => _deadline;
  Duration get remaining {
    final target = _deadline;
    if (target == null) return Duration.zero;
    final value = target.difference(_now());
    return value.isNegative ? Duration.zero : value;
  }

  void start(Duration duration) {
    if (duration <= Duration.zero) {
      cancel();
      return;
    }
    _cancelTimers();
    _mode = SleepTimerMode.duration;
    _deadline = _now().add(duration);
    _armedTrackId = null;
    _deadlineTimer = Timer(duration, _expire);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (remaining <= Duration.zero) {
        _expire();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stopAfterCurrentTrack() {
    final track = _playback.displayTrack;
    if (track == null) return;
    _cancelTimers();
    _mode = SleepTimerMode.endOfTrack;
    _deadline = null;
    _armedTrackId = track.id;
    notifyListeners();
  }

  void cancel() {
    if (!isActive) return;
    _cancelTimers();
    _mode = SleepTimerMode.off;
    _deadline = null;
    _armedTrackId = null;
    notifyListeners();
  }

  void _handleTrackStarted(Track _) {
    if (_mode != SleepTimerMode.endOfTrack) return;
    final armed = _armedTrackId;
    final current = _playback.displayTrack?.id;
    if (armed != null && current != null && current != armed) {
      _expire();
    }
  }

  void _expire() {
    if (_disposed || !isActive) return;
    _cancelTimers();
    _mode = SleepTimerMode.off;
    _deadline = null;
    _armedTrackId = null;
    notifyListeners();
    scheduleMicrotask(() => unawaited(_playback.pause()));
  }

  void _cancelTimers() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _mode == SleepTimerMode.duration &&
        remaining <= Duration.zero) {
      _expire();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_trackStartedSubscription.cancel());
    _cancelTimers();
    super.dispose();
  }
}
