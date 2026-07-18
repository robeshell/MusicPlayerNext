import 'dart:math' as math;

/// Runs scan work with bounded concurrency while preserving input order.
///
/// Provider implementations choose an appropriate [maxConcurrency] for their
/// I/O characteristics. Keeping the scheduler in the shared scanning layer
/// prevents every provider from growing its own subtly different worker pool.
Future<List<R>> mapScanTasks<T, R>(
  List<T> items, {
  required int maxConcurrency,
  required Future<R> Function(T item) task,
}) async {
  if (items.isEmpty) return <R>[];
  if (maxConcurrency < 1) {
    throw ArgumentError.value(
      maxConcurrency,
      'maxConcurrency',
      'Must be at least one.',
    );
  }

  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (nextIndex < items.length) {
      final index = nextIndex++;
      results[index] = await task(items[index]);
    }
  }

  await Future.wait([
    for (
      var workerIndex = 0;
      workerIndex < math.min(maxConcurrency, items.length);
      workerIndex++
    )
      worker(),
  ]);
  return results.cast<R>();
}
