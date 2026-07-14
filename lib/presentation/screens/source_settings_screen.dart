import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../library/library_records.dart';
import '../../library/scanning/local_library_scanner.dart';
import '../../library/scanning/scan_cancellation.dart';
import '../../sources/local/local_source_service.dart';
import '../../sources/webdav/webdav_connection_service.dart';
import '../../sources/webdav/webdav_discovery.dart';
import '../../library/scanning/artwork_store.dart';
import '../../sources/webdav/webdav_folder_scanner.dart';
import '../widgets/sound_components.dart';
import 'webdav_add_dialog.dart';
import 'webdav_folder_picker.dart';

class SourceSettingsScreen extends StatefulWidget {
  const SourceSettingsScreen({
    required this.localSources,
    required this.scanner,
    this.webDavService,
    super.key,
  });

  final LocalSourceService localSources;
  final LocalLibraryScanner scanner;
  final WebDavConnectionService? webDavService;

  @override
  State<SourceSettingsScreen> createState() => _SourceSettingsScreenState();
}

class _SourceSettingsScreenState extends State<SourceSettingsScreen> {
  bool _addingSource = false;
  final Set<String> _scanningSourceIds = {};
  WebDavFolderScanner? _webDavFolderScanner;

  WebDavFolderScanner get _folderScanner {
    final webDav = widget.webDavService;
    if (webDav == null) {
      throw StateError('WebDAV service is unavailable.');
    }
    return _webDavFolderScanner ??= WebDavFolderScanner(
      repository: webDav.repository,
      artworkStore: FileArtworkStore(),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(widget.localSources.restoreLocalFolders());
  }

  Future<void> _addLocalSource() async {
    if (_addingSource) return;
    setState(() => _addingSource = true);
    try {
      final source = await widget.localSources.addLocalFolder();
      if (source != null && source.status == LibrarySourceStatus.available) {
        await _scanLocalSource(source);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法添加文件夹：$error')));
    } finally {
      if (mounted) setState(() => _addingSource = false);
    }
  }

  Future<void> _removeLocalSource(LibrarySourceRecord source) async {
    try {
      await widget.localSources.removeLocalFolder(source);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法移除文件夹：$error')));
    }
  }

  Future<void> _scanLocalSource(LibrarySourceRecord source) async {
    if (!_scanningSourceIds.add(source.id)) return;
    setState(() {});
    try {
      final report = await widget.scanner.scan(source);
      if (!mounted) return;
      final skipped = report.skippedFiles == 0
          ? ''
          : '，跳过 ${report.skippedFiles} 个文件';
      final changes = [
        if (report.addedTracks > 0) '新增 ${report.addedTracks}',
        if (report.modifiedTracks > 0) '更新 ${report.modifiedTracks}',
        if (report.movedTracks > 0) '移动 ${report.movedTracks}',
        if (report.removedTracks > 0) '移除 ${report.removedTracks}',
      ];
      final changeSummary = changes.isEmpty
          ? '，没有文件变化'
          : '，${changes.join('、')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已索引 ${report.indexedTracks} 首歌曲$changeSummary$skipped',
          ),
        ),
      );
    } on ScanCancelledException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('扫描已取消，原资料库保持不变')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('扫描失败：$error')));
    } finally {
      _scanningSourceIds.remove(source.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _addWebDavSource() async {
    final webDav = widget.webDavService;
    if (webDav == null) return;
    final result = await showDialog<WebDavDiscoveryResult>(
      context: context,
      builder: (_) => WebDavAddDialog(service: webDav),
    );
    if (result != null && mounted) {
      final fileCount = result.files.where((f) => !f.isCollection).length;
      final dirCount = result.files.where((f) => f.isCollection).length;
      var msg = 'WebDAV 服务器已连接';
      if (fileCount > 0) msg += '，发现 $fileCount 个文件、$dirCount 个目录';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _removeWebDavSource(WebDavConnectionRecord connection) async {
    final webDav = widget.webDavService;
    if (webDav == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SoundDialog(
        maxWidth: 460,
        title: const Text('移除 WebDAV 服务器'),
        content: Text('确定要移除「${connection.displayName}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await webDav.removeConnection(connection.id);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败：$error')));
      }
    }
  }

  Future<void> _editWebDavSource(WebDavConnectionRecord connection) async {
    final webDav = widget.webDavService;
    if (webDav == null) return;
    final result = await showDialog<WebDavDiscoveryResult>(
      context: context,
      builder: (_) => WebDavAddDialog(service: webDav, connection: connection),
    );
    if (result != null && mounted) {
      final message = result.error == null
          ? 'WebDAV 连接已更新'
          : '连接信息已保存：${result.errorMessage ?? '探测失败'}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _probeWebDav(WebDavConnectionRecord connection) async {
    final webDav = widget.webDavService;
    if (webDav == null) return;
    try {
      final result = await webDav.probeConnection(
        connection,
        allowBadCertificate: connection.allowBadCertificate,
      );
      if (!mounted) return;
      if (result.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('连接失败：${result.errorMessage}')));
      } else {
        final fileCount = result.files.where((f) => !f.isCollection).length;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('连接成功，发现 $fileCount 个文件')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('探测失败：$error')));
    }
  }

  Future<void> _browseWebDavFolders(WebDavConnectionRecord connection) async {
    final webDav = widget.webDavService;
    if (webDav == null || !mounted) return;

    final credentials = await webDav.readCredentials(connection.id);
    if (!mounted) return;
    if (credentials == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法读取连接凭据')));
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) => WebDavFolderPicker(
        url: connection.url,
        credentials: credentials,
        allowBadCertificate: connection.allowBadCertificate,
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    try {
      final result = await _folderScanner.scan(
        connectionId: connection.id,
        folderUrls: selected,
        baseUrl: connection.url,
        credentials: credentials,
        allowBadCertificate: connection.allowBadCertificate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_webDavScanSummary(result))));
    } on ScanCancelledException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WebDAV 扫描已取消，原资料库保持不变')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('扫描失败：$error')));
    }
  }

  String _webDavStatus(WebDavConnectionRecord connection) {
    return switch (connection.status) {
      WebDavConnectionStatus.idle => '未探测',
      WebDavConnectionStatus.probing => '正在探测',
      WebDavConnectionStatus.connected => '已连接',
      WebDavConnectionStatus.unreachable => '无法连接',
      WebDavConnectionStatus.authenticationFailed => '认证失败',
      WebDavConnectionStatus.error => connection.lastError ?? '错误',
    };
  }

  Color _webDavStatusColor(WebDavConnectionRecord connection) {
    return switch (connection.status) {
      WebDavConnectionStatus.idle ||
      WebDavConnectionStatus.probing ||
      WebDavConnectionStatus.connected => SoundColors.webDav,
      WebDavConnectionStatus.authenticationFailed => Colors.orangeAccent,
      WebDavConnectionStatus.unreachable ||
      WebDavConnectionStatus.error => Colors.redAccent,
    };
  }

  String _folderSourceStatus(WebDavConnectionRecord source) {
    return switch (source.status) {
      WebDavConnectionStatus.idle => '未扫描',
      WebDavConnectionStatus.probing => '正在扫描',
      WebDavConnectionStatus.connected => '已索引',
      WebDavConnectionStatus.unreachable => '无法连接',
      WebDavConnectionStatus.authenticationFailed => '认证失败',
      WebDavConnectionStatus.error => source.lastError ?? '错误',
    };
  }

  String _webDavScanSummary(WebDavFolderScanResult result) {
    final changes = [
      if (result.addedTracks > 0) '新增 ${result.addedTracks}',
      if (result.modifiedTracks > 0) '更新 ${result.modifiedTracks}',
      if (result.movedTracks > 0) '移动 ${result.movedTracks}',
      if (result.removedTracks > 0) '移除 ${result.removedTracks}',
    ];
    final changeSummary = changes.isEmpty ? '，没有文件变化' : '，${changes.join('、')}';
    final skipped = result.skippedFiles == 0
        ? ''
        : '，跳过 ${result.skippedFiles} 个文件';
    return '已索引 ${result.indexedTracks} 首歌曲$changeSummary$skipped';
  }

  Future<void> _removeWebDavFolderSource(WebDavConnectionRecord source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SoundDialog(
        maxWidth: 460,
        title: const Text('移除 WebDAV 文件夹'),
        content: Text(
          '确定要移除「${source.displayName}」吗？\n'
          '资料库中对应的歌曲也会被移除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await widget.webDavService!.removeConnection(source.id);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败：$error')));
      }
    }
  }

  Future<void> _rescanWebDavFolderSource(WebDavConnectionRecord source) async {
    final webDav = widget.webDavService;
    if (webDav == null || !mounted) return;
    if (!_scanningSourceIds.add(source.id)) return;
    setState(() {});
    try {
      final parent = await webDav.resolveParentConnection(source);
      if (!mounted) return;
      if (parent == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('找不到父级 WebDAV 连接')));
        return;
      }

      final credentials = await webDav.readCredentials(parent.id);
      if (!mounted) return;
      if (credentials == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法读取连接凭据')));
        return;
      }

      final result = await _folderScanner.scan(
        connectionId: parent.id,
        folderUrls: [source.url],
        baseUrl: parent.url,
        credentials: credentials,
        allowBadCertificate: parent.allowBadCertificate,
        existingSourceId: source.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_webDavScanSummary(result))));
    } on ScanCancelledException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WebDAV 扫描已取消，原资料库保持不变')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('扫描失败：$error')));
    } finally {
      _scanningSourceIds.remove(source.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 140),
      children: [
        const Text(
          '来源',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '管理纳入资料库的本地文件夹和 WebDAV 音乐来源。',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Expanded(
              child: Text(
                '音乐来源',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: _addingSource ? null : _addLocalSource,
              icon: _addingSource
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('添加本地文件夹'),
              style: FilledButton.styleFrom(
                backgroundColor: SoundColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<LibrarySourceRecord>>(
          stream: widget.localSources.watchLocalSources(),
          builder: (context, snapshot) {
            final sources = snapshot.data ?? const [];
            if (snapshot.hasError) {
              return _SourceMessage(
                icon: Icons.error_outline_rounded,
                message: '无法读取本地来源：${snapshot.error}',
              );
            }
            if (sources.isEmpty) {
              return const _SourceMessage(
                icon: Icons.create_new_folder_outlined,
                message: '尚未添加本地音乐文件夹。',
              );
            }
            return Column(
              children: [
                for (var index = 0; index < sources.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final source = sources[index];
                      final scanning = _scanningSourceIds.contains(source.id);
                      return _SourceCard(
                        icon: Icons.folder_rounded,
                        iconColor: SoundColors.local,
                        title: source.displayName,
                        subtitle: source.rootUri,
                        status: _sourceStatus(source),
                        statusColor: _sourceStatusColor(source),
                        folders: [source.displayName],
                        onRemove: scanning
                            ? null
                            : () => _removeLocalSource(source),
                        onRescan: scanning
                            ? () => widget.scanner.cancel(source.id)
                            : () => _scanLocalSource(source),
                        rescanLabel: scanning ? '取消扫描' : '重新扫描',
                      );
                    },
                  ),
                  if (index != sources.length - 1) const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        if (widget.webDavService != null) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'WebDAV 服务器',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: _addWebDavSource,
                icon: const Icon(Icons.cloud_download_rounded),
                label: const Text('添加服务器'),
                style: FilledButton.styleFrom(
                  backgroundColor: SoundColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<WebDavConnectionRecord>>(
            stream: widget.webDavService!.watchManagedSources(),
            builder: (context, snapshot) {
              final connections = snapshot.data ?? const [];
              if (snapshot.hasError) {
                return _SourceMessage(
                  icon: Icons.error_outline_rounded,
                  message: '无法读取 WebDAV 连接：${snapshot.error}',
                );
              }
              if (connections.isEmpty) {
                return const _SourceMessage(
                  icon: Icons.cloud_outlined,
                  message: '尚未添加 WebDAV 服务器。',
                );
              }
              final serverConnections = connections
                  .where((c) => !c.id.startsWith('webdav-folder:'))
                  .toList();
              final folderSources = connections
                  .where((c) => c.id.startsWith('webdav-folder:'))
                  .toList();
              return Column(
                children: [
                  for (var i = 0; i < serverConnections.length; i++) ...[
                    _SourceCard(
                      icon: Icons.cloud_rounded,
                      iconColor: SoundColors.webDav,
                      title: serverConnections[i].displayName,
                      subtitle: serverConnections[i].url,
                      status: _webDavStatus(serverConnections[i]),
                      statusColor: _webDavStatusColor(serverConnections[i]),
                      folders: [serverConnections[i].url],
                      onEdit: () => _editWebDavSource(serverConnections[i]),
                      onRemove: () => _removeWebDavSource(serverConnections[i]),
                      onRescan: serverConnections[i].isAvailable
                          ? () => _browseWebDavFolders(serverConnections[i])
                          : () => _probeWebDav(serverConnections[i]),
                      rescanLabel: serverConnections[i].isAvailable
                          ? '选择文件夹'
                          : '重新探测',
                    ),
                    if (i != serverConnections.length - 1 ||
                        folderSources.isNotEmpty)
                      const SizedBox(height: 14),
                  ],
                  for (var i = 0; i < folderSources.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final source = folderSources[i];
                        final scanning =
                            _scanningSourceIds.contains(source.id) ||
                            (_webDavFolderScanner?.isScanning(source.id) ??
                                false);
                        return _SourceCard(
                          icon: Icons.folder_rounded,
                          iconColor: SoundColors.webDav,
                          title: source.displayName,
                          subtitle: source.url,
                          status: _folderSourceStatus(source),
                          statusColor: _webDavStatusColor(source),
                          folders: [source.url],
                          onRemove: scanning
                              ? null
                              : () => _removeWebDavFolderSource(source),
                          onRescan: scanning
                              ? () => _folderScanner.cancel(source.id)
                              : () => _rescanWebDavFolderSource(source),
                          rescanLabel: scanning ? '取消扫描' : '重新扫描',
                        );
                      },
                    ),
                    if (i != folderSources.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  String _sourceStatus(LibrarySourceRecord source) {
    return switch (source.status) {
      LibrarySourceStatus.idle => '等待扫描',
      LibrarySourceStatus.scanning => '正在扫描',
      LibrarySourceStatus.available =>
        source.scanRevision == 0
            ? '已授权 · 等待扫描'
            : '已索引 · 已扫描 ${source.scanRevision} 次',
      LibrarySourceStatus.permissionRequired => '需要重新授权',
      LibrarySourceStatus.unavailable => '文件夹不可用',
      LibrarySourceStatus.error => source.lastError ?? '来源错误',
    };
  }

  Color _sourceStatusColor(LibrarySourceRecord source) {
    return switch (source.status) {
      LibrarySourceStatus.idle ||
      LibrarySourceStatus.scanning ||
      LibrarySourceStatus.available => SoundColors.local,
      LibrarySourceStatus.permissionRequired => Colors.orangeAccent,
      LibrarySourceStatus.unavailable ||
      LibrarySourceStatus.error => Colors.redAccent,
    };
  }
}

class _SourceMessage extends StatelessWidget {
  const _SourceMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.folders,
    this.statusColor = SoundColors.local,
    this.onEdit,
    this.onRemove,
    this.onRescan,
    this.rescanLabel = '重新扫描',
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final List<String> folders;
  final Color statusColor;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onRescan;
  final String rescanLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    _StatusDot(color: statusColor),
                    const SizedBox(width: 7),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        status,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      tooltip: '编辑此来源',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  IconButton(
                    onPressed: onRemove,
                    tooltip: onRemove == null ? null : '移除此来源',
                    icon: Icon(
                      onRemove == null
                          ? Icons.more_horiz_rounded
                          : Icons.delete_outline_rounded,
                    ),
                  ),
                ],
              ),
              if (compact)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      _StatusDot(color: statusColor),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
              Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
              const SizedBox(height: 12),
              for (final folder in folders)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: compact ? 0 : 58),
                      const Icon(
                        Icons.folder_open_rounded,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          folder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(onPressed: onRescan, child: Text(rescanLabel)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
