import '../../library/library_records.dart';
import '../source_provider.dart';
import 'webdav_connection_service.dart';
import 'webdav_source_directory_browser.dart';

class WebDavSourceConnectionProvider implements SourceConnectionProvider {
  const WebDavSourceConnectionProvider(this.service);

  final WebDavConnectionService service;

  @override
  LibrarySourceType get type => LibrarySourceType.webDav;

  @override
  Stream<List<SourceManagedResource>> watchResources() {
    return service.watchManagedSources().map(
      (resources) => resources.map(_mapResource).toList(growable: false),
    );
  }

  @override
  Future<SourceManagedResource> probe(String connectionId) async {
    final connection = await service.getManagedSource(connectionId);
    if (connection == null ||
        !WebDavConnectionService.isConnectionSourceId(connection.id)) {
      throw StateError('WebDAV connection is unavailable: $connectionId');
    }
    await service.probeConnection(
      connection,
      allowBadCertificate: connection.allowBadCertificate,
    );
    final updated = await service.getManagedSource(connectionId);
    if (updated == null) {
      throw StateError('WebDAV connection disappeared: $connectionId');
    }
    return _mapResource(updated);
  }

  @override
  Future<SourceDirectoryBrowser> openBrowser(String connectionId) async {
    final connection = await service.getManagedSource(connectionId);
    if (connection == null ||
        !WebDavConnectionService.isConnectionSourceId(connection.id)) {
      throw StateError('WebDAV connection is unavailable: $connectionId');
    }
    return WebDavSourceDirectoryBrowser.forConnection(
      service: service,
      connection: connection,
    );
  }

  @override
  Future<void> remove(String resourceId) =>
      service.removeConnection(resourceId);

  SourceManagedResource _mapResource(WebDavConnectionRecord resource) {
    return SourceManagedResource(
      id: resource.id,
      type: type,
      kind: WebDavConnectionService.isConnectionSourceId(resource.id)
          ? SourceManagedResourceKind.connection
          : SourceManagedResourceKind.catalog,
      displayName: resource.displayName,
      location: resource.url,
      status: switch (resource.status) {
        WebDavConnectionStatus.idle => SourceManagedStatus.idle,
        WebDavConnectionStatus.probing => SourceManagedStatus.working,
        WebDavConnectionStatus.connected => SourceManagedStatus.available,
        WebDavConnectionStatus.authenticationFailed =>
          SourceManagedStatus.authenticationFailed,
        WebDavConnectionStatus.unreachable => SourceManagedStatus.unavailable,
        WebDavConnectionStatus.error => SourceManagedStatus.error,
      },
      errorMessage: resource.lastError,
    );
  }
}
