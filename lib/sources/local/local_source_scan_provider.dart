import '../../library/library_records.dart';
import '../../library/scanning/local_library_scanner.dart';
import '../source_provider.dart';
import 'local_source_service.dart';

class LocalSourceScanProvider implements SourceScanProvider {
  const LocalSourceScanProvider({
    required this.sourceService,
    required this.scanner,
  });

  final LocalSourceService sourceService;
  final LocalLibraryScanner scanner;

  @override
  LibrarySourceType get type => LibrarySourceType.local;

  @override
  bool isScanning(String sourceId) => scanner.isScanning(sourceId);

  @override
  bool cancel(String sourceId) => scanner.cancel(sourceId);

  @override
  Future<SourceScanSummary> rescan(String sourceId) async {
    final source = await sourceService.repository.getSource(sourceId);
    if (source == null || source.type != type) {
      throw StateError('Local source is unavailable: $sourceId');
    }
    final report = await scanner.scan(source);
    return SourceScanSummary(
      indexedTracks: report.indexedTracks,
      skippedFiles: report.skippedFiles,
      addedTracks: report.addedTracks,
      modifiedTracks: report.modifiedTracks,
      movedTracks: report.movedTracks,
      removedTracks: report.removedTracks,
      unchangedTracks: report.unchangedTracks,
    );
  }
}
