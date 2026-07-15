import '../../library/scanning/audio_format_registry.dart';
import '../source_provider.dart';
import 'webdav_connection_service.dart';
import 'webdav_credentials.dart';
import 'webdav_discovery.dart';

typedef WebDavBrowseProbe =
    Future<WebDavDiscoveryResult> Function(
      String url,
      WebDavCredentials credentials,
    );

class WebDavSourceDirectoryBrowser implements SourceDirectoryBrowser {
  WebDavSourceDirectoryBrowser({
    required this.baseUrl,
    required this.credentials,
    bool allowBadCertificate = false,
    WebDavBrowseProbe? probe,
  }) : _root = Uri.parse(baseUrl),
       _probe =
           probe ??
           ((url, credentials) => WebDavDiscoveryService(
             allowBadCertificate: allowBadCertificate,
           ).probe(url, credentials: credentials));

  final String baseUrl;
  final WebDavCredentials credentials;
  final Uri _root;
  final WebDavBrowseProbe _probe;

  static Future<WebDavSourceDirectoryBrowser> forConnection({
    required WebDavConnectionService service,
    required WebDavConnectionRecord connection,
  }) async {
    final credentials = await service.readCredentials(connection.id);
    if (credentials == null) {
      throw const SourceBrowseException('无法读取连接凭据');
    }
    return WebDavSourceDirectoryBrowser(
      baseUrl: connection.url,
      credentials: credentials,
      allowBadCertificate: connection.allowBadCertificate,
    );
  }

  @override
  String get rootId => _root.path.isEmpty ? '/' : _root.path;

  @override
  Future<List<SourceDirectoryEntry>> browse(String directoryId) async {
    final result = await _probe(
      _root.resolve(directoryId).toString(),
      credentials,
    );
    if (result.error != null) {
      throw SourceBrowseException(result.errorMessage ?? '无法读取目录');
    }

    final selfId = directoryId.length > 1 && directoryId.endsWith('/')
        ? directoryId.substring(0, directoryId.length - 1)
        : directoryId;
    return result.files
        .map((entry) {
          final id = _resourceId(entry.href);
          if (id == null || id == directoryId || id == selfId) return null;
          if (!entry.isCollection && !isSupportedAudioPath(entry.displayName)) {
            return null;
          }
          return SourceDirectoryEntry(
            id: id,
            displayName: entry.displayName,
            isDirectory: entry.isCollection,
          );
        })
        .nonNulls
        .toList(growable: false);
  }

  String? _resourceId(String href) {
    if (href.isEmpty) return null;
    final hrefUri = Uri.tryParse(href);
    if (hrefUri == null) return null;
    final resolved = hrefUri.hasScheme ? hrefUri : _root.resolveUri(hrefUri);
    if (resolved.scheme.toLowerCase() != _root.scheme.toLowerCase() ||
        resolved.host.toLowerCase() != _root.host.toLowerCase() ||
        resolved.port != _root.port) {
      return null;
    }
    return resolved.path.isEmpty ? '/' : resolved.path;
  }
}
