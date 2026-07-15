import 'package:flutter/foundation.dart';

import '../../domain/library_models.dart';
import '../../offline/offline_media_provider.dart';

enum OfflineDownloadTaskState { downloading, failed }

@immutable
class OfflineDownloadTask {
  const OfflineDownloadTask({
    required this.state,
    this.progress,
    this.receivedBytes = 0,
    this.totalBytes,
    this.error,
  });

  final OfflineDownloadTaskState state;
  final double? progress;
  final int receivedBytes;
  final int? totalBytes;
  final String? error;
}

@immutable
class OfflineDownloadItem {
  const OfflineDownloadItem({
    required this.reference,
    required this.providerLabel,
    required this.title,
    required this.artist,
    required this.albumTitle,
    required this.size,
    required this.pinned,
    required this.accessedAt,
    required this.task,
    required this.track,
  });

  final OfflineMediaReference reference;
  final String providerLabel;
  final String title;
  final String artist;
  final String albumTitle;
  final int size;
  final bool pinned;
  final DateTime? accessedAt;
  final OfflineDownloadTask? task;
  final Track? track;

  bool get canRetry =>
      track != null && task?.state == OfflineDownloadTaskState.failed;
  bool get isDownloading => task?.state == OfflineDownloadTaskState.downloading;
}

@immutable
class OfflineDownloadBatchResult {
  const OfflineDownloadBatchResult({
    required this.completed,
    required this.failed,
    this.cancelled = 0,
  });

  final int completed;
  final int failed;
  final int cancelled;

  bool get hasFailures => failed > 0;
  bool get wasCancelled => cancelled > 0;
}

/// Coordinates offline downloads without knowing how any source protocol
/// authenticates, scans, downloads or stores its media.
class OfflineDownloadController extends ChangeNotifier {
  OfflineDownloadController({required Iterable<OfflineMediaProvider> providers})
    : providers = List.unmodifiable(providers) {
    for (final provider in this.providers) {
      if (_providersById.containsKey(provider.id)) {
        throw ArgumentError('Duplicate offline provider id: ${provider.id}');
      }
      _providersById[provider.id] = provider;
    }
  }

  final List<OfflineMediaProvider> providers;
  final Map<String, OfflineMediaProvider> _providersById = {};
  OfflineStorageStats _stats = OfflineStorageStats.empty;
  List<OfflineStoredMedia> _storedItems = const [];
  Map<OfflineMediaReference, Track> _tracksByReference = const {};
  Set<OfflineMediaReference> _pinnedReferences = const {};
  final Set<OfflineMediaReference> _cancelledReferences = {};
  final Map<OfflineMediaReference, OfflineDownloadTask> _tasks = {};
  bool _disposed = false;

  OfflineStorageStats get stats => _stats;

  List<OfflineDownloadItem> get offlineItems {
    final results = <OfflineDownloadItem>[];
    final added = <OfflineMediaReference>{};
    for (final item in _storedItems.where((item) => item.pinned)) {
      results.add(_offlineItem(item.reference, storedItem: item));
      added.add(item.reference);
    }
    for (final reference in _tasks.keys) {
      if (added.add(reference)) results.add(_offlineItem(reference));
    }
    results.sort((left, right) {
      final stateCompare = _itemSortRank(left).compareTo(_itemSortRank(right));
      if (stateCompare != 0) return stateCompare;
      final leftAt = left.accessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightAt =
          right.accessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightAt.compareTo(leftAt);
    });
    return List.unmodifiable(results);
  }

  bool supports(Track track) => _bindingFor(track) != null;

  bool isPinned(Track track) {
    final binding = _bindingFor(track);
    return binding != null && _pinnedReferences.contains(binding.reference);
  }

  bool isPinnedReference(OfflineMediaReference reference) =>
      _pinnedReferences.contains(reference);

  OfflineDownloadTask? taskFor(Track track) {
    final binding = _bindingFor(track);
    return binding == null ? null : _tasks[binding.reference];
  }

  OfflineDownloadTask? taskForReference(OfflineMediaReference reference) =>
      _tasks[reference];

  bool isDownloading(Track track) =>
      taskFor(track)?.state == OfflineDownloadTaskState.downloading;

  bool areAllPinned(Iterable<Track> tracks) {
    final supported = tracks.where(supports).toList(growable: false);
    return supported.isNotEmpty && supported.every(isPinned);
  }

  bool isDownloadingAny(Iterable<Track> tracks) =>
      tracks.where(supports).any(isDownloading);

  double? progressFor(Iterable<Track> tracks) {
    final supported = tracks.where(supports).toList(growable: false);
    if (supported.isEmpty) return null;
    var total = 0.0;
    for (final track in supported) {
      if (isPinned(track)) {
        total += 1;
      } else {
        total += taskFor(track)?.progress ?? 0;
      }
    }
    return (total / supported.length).clamp(0, 1);
  }

  int pinnedCount(Iterable<Track> tracks) =>
      tracks.where(supports).where(isPinned).length;

  void updateLibraryTracks(Iterable<Track> tracks) {
    final mapped = <OfflineMediaReference, Track>{};
    for (final track in tracks) {
      final binding = _bindingFor(track);
      if (binding != null) mapped[binding.reference] = track;
    }
    _tracksByReference = Map.unmodifiable(mapped);
    _notify();
  }

  Future<void> refresh() async {
    await _reloadStorageState();
    _notify();
  }

  Future<void> pinTrack(Track track) {
    return _pinTrack(track, resetCancellation: true);
  }

  Future<void> retry(OfflineMediaReference reference) async {
    final track = _tracksByReference[reference];
    if (track == null) {
      throw StateError('歌曲已不在资料库中，无法重新下载');
    }
    await pinTrack(track);
  }

  Future<void> _pinTrack(Track track, {required bool resetCancellation}) async {
    final binding = _bindingFor(track);
    if (binding == null) {
      throw ArgumentError.value(track.mediaUri, 'track', 'Unsupported source');
    }
    final reference = binding.reference;
    _tracksByReference = {..._tracksByReference, reference: track};
    if (resetCancellation) _cancelledReferences.remove(reference);
    _tasks[reference] = const OfflineDownloadTask(
      state: OfflineDownloadTaskState.downloading,
      progress: 0,
    );
    _notify();
    try {
      await binding.provider.pin(
        track,
        onProgress: (progress) {
          if (_cancelledReferences.contains(reference)) return;
          _tasks[reference] = OfflineDownloadTask(
            state: OfflineDownloadTaskState.downloading,
            progress: progress.fraction,
            receivedBytes: progress.receivedBytes,
            totalBytes: progress.totalBytes,
          );
          _notify();
        },
      );
      if (_cancelledReferences.contains(reference)) {
        await binding.provider.remove(reference);
        throw const OfflineDownloadCancelledException();
      }
      _tasks.remove(reference);
      await _reloadStorageState();
      _notify();
    } on OfflineDownloadCancelledException {
      _tasks.remove(reference);
      _notify();
      rethrow;
    } catch (error) {
      _tasks[reference] = OfflineDownloadTask(
        state: OfflineDownloadTaskState.failed,
        error: _friendlyError(error),
      );
      _notify();
      rethrow;
    }
  }

  Future<OfflineDownloadBatchResult> pinTracks(Iterable<Track> tracks) async {
    final pending = _uniqueSupportedTracks(
      tracks,
    ).where((track) => !isPinned(track)).toList(growable: false);
    final references = {
      for (final track in pending) _bindingFor(track)!.reference,
    };
    _cancelledReferences.removeAll(references);
    var completed = 0;
    var failed = 0;
    var cancelled = 0;
    for (var index = 0; index < pending.length; index++) {
      final track = pending[index];
      final reference = _bindingFor(track)!.reference;
      if (_cancelledReferences.contains(reference)) {
        cancelled = pending.length - index;
        break;
      }
      try {
        await _pinTrack(track, resetCancellation: false);
        completed++;
      } on OfflineDownloadCancelledException {
        cancelled = pending.length - index;
        break;
      } catch (_) {
        failed++;
      }
    }
    _cancelledReferences.removeAll(references);
    return OfflineDownloadBatchResult(
      completed: completed,
      failed: failed,
      cancelled: cancelled,
    );
  }

  bool cancelTrack(Track track) {
    final binding = _bindingFor(track);
    if (binding == null) return false;
    return _cancelReferences({binding.reference});
  }

  bool cancelTracks(Iterable<Track> tracks) {
    final references = {
      for (final track in _uniqueSupportedTracks(tracks))
        _bindingFor(track)!.reference,
    };
    return _cancelReferences(references);
  }

  bool cancelReference(OfflineMediaReference reference) =>
      _cancelReferences({reference});

  bool _cancelReferences(Set<OfflineMediaReference> references) {
    if (references.isEmpty) return false;
    _cancelledReferences.addAll(references);
    var cancelled = false;
    for (final reference in references) {
      final provider = _providersById[reference.providerId];
      if (provider == null) continue;
      final wasDownloading =
          _tasks[reference]?.state == OfflineDownloadTaskState.downloading;
      cancelled =
          provider.cancel(reference, includePending: wasDownloading) ||
          wasDownloading ||
          cancelled;
      if (wasDownloading) _tasks.remove(reference);
    }
    _notify();
    return cancelled;
  }

  Future<void> removeTrack(Track track) async {
    final binding = _bindingFor(track);
    if (binding == null) return;
    await removeReference(binding.reference);
  }

  Future<void> removeReference(OfflineMediaReference reference) async {
    final provider = _providersById[reference.providerId];
    if (provider == null) return;
    if (_tasks[reference]?.state == OfflineDownloadTaskState.downloading) {
      _cancelReferences({reference});
    }
    if (_pinnedReferences.contains(reference)) {
      final removed = await provider.remove(reference);
      if (!removed) throw StateError('文件正在使用，暂时无法移除');
    }
    _tasks.remove(reference);
    await _reloadStorageState();
    _notify();
  }

  Future<void> removeTracks(Iterable<Track> tracks) async {
    for (final track in _uniqueSupportedTracks(tracks)) {
      await removeTrack(track);
    }
  }

  Future<int> clearTransient() async {
    var removed = 0;
    for (final provider in providers) {
      removed += await provider.clearTransient();
    }
    await refresh();
    return removed;
  }

  Future<int> clearAll() async {
    _cancelReferences(_tasks.keys.toSet());
    var removed = 0;
    for (final provider in providers) {
      removed += await provider.clearAll();
    }
    _pinnedReferences = const {};
    _storedItems = const [];
    _tasks.clear();
    await _reloadStorageState();
    _notify();
    return removed;
  }

  Future<void> _reloadStorageState() async {
    final items = <OfflineStoredMedia>[];
    var stats = OfflineStorageStats.empty;
    for (final provider in providers) {
      items.addAll(await provider.items());
      stats += await provider.stats();
    }
    _storedItems = List.unmodifiable(items);
    _pinnedReferences = Set.unmodifiable(
      items.where((item) => item.pinned).map((item) => item.reference),
    );
    _stats = stats;
  }

  OfflineDownloadItem _offlineItem(
    OfflineMediaReference reference, {
    OfflineStoredMedia? storedItem,
  }) {
    final track = _tracksByReference[reference];
    final task = _tasks[reference];
    return OfflineDownloadItem(
      reference: reference,
      providerLabel:
          _providersById[reference.providerId]?.displayName ??
          reference.providerId,
      title: track?.title ?? _fallbackTitle(reference.resourceId),
      artist: track?.artist ?? '未知艺人',
      albumTitle: track?.albumTitle ?? '来源已不在资料库',
      size: storedItem?.size ?? task?.receivedBytes ?? 0,
      pinned: storedItem?.pinned ?? false,
      accessedAt: storedItem?.accessedAt,
      task: task,
      track: track,
    );
  }

  int _itemSortRank(OfflineDownloadItem item) {
    return switch (item.task?.state) {
      OfflineDownloadTaskState.downloading => 0,
      OfflineDownloadTaskState.failed => 1,
      null => 2,
    };
  }

  String _fallbackTitle(String resourceId) {
    final uri = Uri.tryParse(resourceId);
    final raw = uri?.pathSegments.lastOrNull;
    if (raw == null || raw.isEmpty) return '未知歌曲';
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  Iterable<Track> _uniqueSupportedTracks(Iterable<Track> tracks) sync* {
    final seen = <OfflineMediaReference>{};
    for (final track in tracks) {
      final binding = _bindingFor(track);
      if (binding == null || !seen.add(binding.reference)) continue;
      yield track;
    }
  }

  _OfflineProviderBinding? _bindingFor(Track track) {
    for (final provider in providers) {
      if (provider.supports(track)) {
        return _OfflineProviderBinding(
          provider: provider,
          reference: provider.referenceFor(track),
        );
      }
    }
    return null;
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^\w+Exception:\s*'),
      '',
    );
    return message.isEmpty ? '下载失败，请检查网络与来源设置' : message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final entry in _tasks.entries.where(
      (entry) => entry.value.state == OfflineDownloadTaskState.downloading,
    )) {
      _providersById[entry.key.providerId]?.cancel(
        entry.key,
        includePending: true,
      );
    }
    super.dispose();
  }
}

class _OfflineProviderBinding {
  const _OfflineProviderBinding({
    required this.provider,
    required this.reference,
  });

  final OfflineMediaProvider provider;
  final OfflineMediaReference reference;
}
