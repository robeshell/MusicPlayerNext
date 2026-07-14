class ScanCancelledException implements Exception {
  const ScanCancelledException();

  @override
  String toString() => '资料库扫描已取消';
}

class ScanCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const ScanCancelledException();
  }
}
