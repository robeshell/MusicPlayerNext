import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../library/scanning/local_library_scanner.dart';
import '../../offline/offline_media_provider.dart';
import '../../playback/playback_controller.dart';
import '../../playback/playback_mode.dart';
import '../../sources/local/local_source_service.dart';
import '../../sources/webdav/webdav_connection_service.dart';
import '../controllers/offline_download_controller.dart';
import '../widgets/sound_components.dart';
import 'source_settings_screen.dart';

enum SettingsDestination { overview, sources, offline }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.playback,
    required this.localSources,
    required this.scanner,
    required this.onShowKeyboardShortcuts,
    this.webDavService,
    this.offline,
    this.initialDestination = SettingsDestination.overview,
    super.key,
  });

  final SoundPlaybackController playback;
  final LocalSourceService localSources;
  final LocalLibraryScanner scanner;
  final WebDavConnectionService? webDavService;
  final OfflineDownloadController? offline;
  final VoidCallback onShowKeyboardShortcuts;
  final SettingsDestination initialDestination;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsDestination _destination = widget.initialDestination;
  bool _playbackModesExpanded = false;

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDestination != widget.initialDestination) {
      _destination = widget.initialDestination;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_destination == SettingsDestination.sources) {
      return SourceSettingsScreen(
        localSources: widget.localSources,
        scanner: widget.scanner,
        webDavService: widget.webDavService,
        onBack: () =>
            setState(() => _destination = SettingsDestination.overview),
      );
    }
    if (_destination == SettingsDestination.offline && widget.offline != null) {
      return OfflineSettingsView(
        offline: widget.offline!,
        onBack: () =>
            setState(() => _destination = SettingsDestination.overview),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([widget.playback, ?widget.offline]),
      builder: (context, _) => ListView(
        key: const ValueKey('settings-overview'),
        padding: EdgeInsets.fromLTRB(
          context.soundPageGutter,
          28,
          context.soundPageGutter,
          context.soundContentBottomPadding,
        ),
        children: [
          Text(
            '设置',
            style: TextStyle(
              fontSize: context.soundPageTitleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '调整播放、资料库和应用操作。',
            style: TextStyle(color: context.soundMutedText, fontSize: 12),
          ),
          const SizedBox(height: 26),
          _SettingsSection(
            title: '播放',
            children: [
              _SettingsRow(
                icon: _playbackModeIcon(widget.playback.playbackMode),
                iconColor: SoundColors.accent,
                title: '播放模式',
                subtitle: '控制队列结束和切歌时的行为',
                value: widget.playback.playbackMode.label,
                expanded: _playbackModesExpanded,
                onTap: () => setState(
                  () => _playbackModesExpanded = !_playbackModesExpanded,
                ),
              ),
              if (_playbackModesExpanded)
                _PlaybackModeSelector(
                  selected: widget.playback.playbackMode,
                  onSelected: (mode) {
                    widget.playback.setPlaybackMode(mode);
                    setState(() => _playbackModesExpanded = false);
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsSection(
            title: '资料库',
            children: [
              _SettingsRow(
                key: const ValueKey('settings-sources-row'),
                icon: Icons.library_music_rounded,
                iconColor: SoundColors.local,
                title: '音乐来源',
                subtitle: '管理本地文件夹、WebDAV 服务器和扫描目录',
                onTap: () =>
                    setState(() => _destination = SettingsDestination.sources),
              ),
              if (widget.offline != null)
                _SettingsRow(
                  key: const ValueKey('settings-offline-row'),
                  icon: Icons.download_for_offline_outlined,
                  iconColor: SoundColors.webDav,
                  title: '离线与缓存',
                  subtitle: '管理远程来源的离线歌曲、临时缓存和存储空间',
                  value: _formatBytes(widget.offline!.stats.totalBytes),
                  onTap: () => setState(
                    () => _destination = SettingsDestination.offline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsSection(
            title: '操作',
            children: [
              _SettingsRow(
                icon: Icons.keyboard_alt_outlined,
                iconColor: context.soundSecondaryText,
                title: '键盘快捷键',
                subtitle: '查看播放、导航和搜索快捷键',
                onTap: widget.onShowKeyboardShortcuts,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SettingsSection(
            title: '关于',
            children: [
              _SettingsRow(
                icon: Icons.graphic_eq_rounded,
                iconColor: SoundColors.webDav,
                title: 'Sound',
                subtitle: '跨平台本地与远程音乐播放器',
                value: '开发版本',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OfflineSettingsView extends StatelessWidget {
  const OfflineSettingsView({
    required this.offline,
    required this.onBack,
    super.key,
  });

  final OfflineDownloadController offline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: offline,
      builder: (context, _) {
        final stats = offline.stats;
        final offlineItems = offline.offlineItems;
        return ListView(
          key: const ValueKey('offline-settings'),
          padding: EdgeInsets.fromLTRB(
            context.soundPageGutter,
            20,
            context.soundPageGutter,
            context.soundContentBottomPadding,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('offline-settings-back'),
                onPressed: onBack,
                tooltip: '返回设置',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '离线与缓存',
              style: TextStyle(
                fontSize: context.soundPageTitleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '主动保存的歌曲不会被临时缓存清理。',
              style: TextStyle(color: context.soundMutedText, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SoundGlassSurface(
              strong: true,
              blur: false,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatBytes(stats.totalBytes),
                      key: const ValueKey('offline-total-size'),
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sound 当前使用的音频存储',
                      style: TextStyle(
                        color: context.soundMutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 520;
                        final cards = [
                          _OfflineStat(
                            icon: Icons.cloud_done_rounded,
                            label: '离线下载',
                            value: _formatBytes(stats.pinnedBytes),
                            detail: '${stats.pinnedEntries} 首',
                            color: SoundColors.webDav,
                          ),
                          _OfflineStat(
                            icon: Icons.bolt_rounded,
                            label: '临时缓存',
                            value: _formatBytes(stats.transientBytes),
                            detail: '${stats.transientEntries} 个文件',
                            color: SoundColors.accent,
                          ),
                        ];
                        return compact
                            ? Column(
                                children: [
                                  cards.first,
                                  const SizedBox(height: 10),
                                  cards.last,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: cards.first),
                                  const SizedBox(width: 12),
                                  Expanded(child: cards.last),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _OfflineDownloadsPanel(
              items: offlineItems,
              onCancel: (item) => _cancelDownload(context, item),
              onRetry: (item) => unawaited(_retryDownload(context, item)),
              onRemove: (item) => unawaited(_removeDownload(context, item)),
            ),
            const SizedBox(height: 22),
            _SettingsSection(
              title: '存储管理',
              children: [
                _SettingsRow(
                  key: const ValueKey('clear-transient-cache'),
                  icon: Icons.cleaning_services_outlined,
                  iconColor: SoundColors.webDav,
                  title: '清理临时缓存',
                  subtitle: '只删除播放时生成的缓存，保留主动离线保存的歌曲',
                  value: _formatBytes(stats.transientBytes),
                  onTap: stats.transientEntries == 0
                      ? null
                      : () => unawaited(_clearTransient(context)),
                ),
                _SettingsRow(
                  key: const ValueKey('clear-all-offline'),
                  icon: Icons.delete_sweep_outlined,
                  iconColor: SoundColors.accent,
                  title: '删除全部音频缓存',
                  subtitle: '同时移除离线下载和临时缓存，不影响来源文件',
                  value: '${stats.totalEntries} 个文件',
                  onTap: stats.totalEntries == 0
                      ? null
                      : () => unawaited(_clearAll(context)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearTransient(BuildContext context) async {
    final removed = await offline.clearTransient();
    if (context.mounted) _showStorageMessage(context, '已清理 $removed 个临时缓存文件');
  }

  void _cancelDownload(BuildContext context, OfflineDownloadItem item) {
    offline.cancelReference(item.reference);
    _showStorageMessage(context, '已取消「${item.title}」的下载');
  }

  Future<void> _retryDownload(
    BuildContext context,
    OfflineDownloadItem item,
  ) async {
    try {
      await offline.retry(item.reference);
      if (context.mounted) {
        _showStorageMessage(context, '「${item.title}」已可离线播放');
      }
    } on OfflineDownloadCancelledException {
      // Explicit cancellation has its own feedback.
    } catch (_) {
      if (!context.mounted) return;
      final error =
          offline.taskForReference(item.reference)?.error ?? '重试失败，请检查网络与来源设置';
      _showStorageMessage(context, error);
    }
  }

  Future<void> _removeDownload(
    BuildContext context,
    OfflineDownloadItem item,
  ) async {
    final failed = item.task?.state == OfflineDownloadTaskState.failed;
    if (!failed) {
      final confirmed = await _confirmRemoveDownload(context, item.title);
      if (!confirmed || !context.mounted) return;
    }
    try {
      await offline.removeReference(item.reference);
      if (context.mounted) {
        _showStorageMessage(
          context,
          failed ? '已移除失败记录' : '已移除「${item.title}」的离线下载',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showStorageMessage(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await _confirmClearAll(context);
    if (!confirmed || !context.mounted) return;
    final removed = await offline.clearAll();
    if (context.mounted) _showStorageMessage(context, '已删除 $removed 个缓存文件');
  }
}

class _OfflineDownloadsPanel extends StatelessWidget {
  const _OfflineDownloadsPanel({
    required this.items,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
  });

  final List<OfflineDownloadItem> items;
  final ValueChanged<OfflineDownloadItem> onCancel;
  final ValueChanged<OfflineDownloadItem> onRetry;
  final ValueChanged<OfflineDownloadItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Text(
                '下载与离线内容',
                style: TextStyle(
                  color: context.soundMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} 项',
                style: TextStyle(color: context.soundMutedText, fontSize: 12),
              ),
            ],
          ),
        ),
        SoundGlassSurface(
          blur: false,
          showShadow: false,
          borderRadius: BorderRadius.circular(SoundRadii.card),
          child: items.isEmpty
              ? const _OfflineDownloadsEmpty()
              : items.length <= 5
              ? Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _OfflineDownloadRow(
                        item: items[index],
                        onCancel: onCancel,
                        onRetry: onRetry,
                        onRemove: onRemove,
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 1,
                          indent: 62,
                          color: context.soundDivider,
                        ),
                    ],
                  ],
                )
              : SizedBox(
                  height: 430,
                  child: ListView.separated(
                    primary: false,
                    itemCount: items.length,
                    itemBuilder: (context, index) => _OfflineDownloadRow(
                      item: items[index],
                      onCancel: onCancel,
                      onRetry: onRetry,
                      onRemove: onRemove,
                    ),
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 62,
                      color: context.soundDivider,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OfflineDownloadsEmpty extends StatelessWidget {
  const _OfflineDownloadsEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Row(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            color: context.soundMutedText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '还没有离线内容',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '在支持离线的专辑或歌曲菜单中选择“离线保存”。',
                  style: TextStyle(color: context.soundMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineDownloadRow extends StatelessWidget {
  const _OfflineDownloadRow({
    required this.item,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
  });

  final OfflineDownloadItem item;
  final ValueChanged<OfflineDownloadItem> onCancel;
  final ValueChanged<OfflineDownloadItem> onRetry;
  final ValueChanged<OfflineDownloadItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final task = item.task;
    final downloading = task?.state == OfflineDownloadTaskState.downloading;
    final failed = task?.state == OfflineDownloadTaskState.failed;
    final subtitle = failed
        ? task?.error ?? '下载失败'
        : [
            item.artist,
            item.albumTitle,
            if (downloading)
              task?.totalBytes == null
                  ? _formatBytes(task?.receivedBytes ?? 0)
                  : '${_formatBytes(task!.receivedBytes)} / ${_formatBytes(task.totalBytes!)}'
            else
              _formatBytes(item.size),
          ].join(' · ');
    final statusColor = failed
        ? SoundColors.accent
        : downloading
        ? SoundColors.webDav
        : SoundColors.local;

    return Padding(
      key: ValueKey('offline-item-${item.reference.storageKey}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: downloading
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      value: task?.progress,
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : Icons.cloud_done_rounded,
                    size: 19,
                    color: statusColor,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: failed ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: failed ? SoundColors.accent : context.soundMutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (downloading)
            IconButton(
              key: ValueKey('offline-cancel-${item.reference.storageKey}'),
              onPressed: () => onCancel(item),
              tooltip: '取消下载',
              icon: const Icon(Icons.close_rounded),
            )
          else if (failed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ValueKey('offline-dismiss-${item.reference.storageKey}'),
                  onPressed: () => onRemove(item),
                  tooltip: '移除失败记录',
                  icon: const Icon(Icons.close_rounded),
                ),
                IconButton(
                  key: ValueKey('offline-retry-${item.reference.storageKey}'),
                  onPressed: item.canRetry ? () => onRetry(item) : null,
                  tooltip: item.canRetry ? '重试下载' : '来源已不在资料库',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            )
          else
            IconButton(
              key: ValueKey('offline-remove-${item.reference.storageKey}'),
              onPressed: () => onRemove(item),
              tooltip: '移除离线下载',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

class _OfflineStat extends StatelessWidget {
  const _OfflineStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.soundMutedText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(detail, style: TextStyle(color: context.soundMutedText)),
        ],
      ),
    );
  }
}

Future<bool> _confirmRemoveDownload(BuildContext context, String title) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SoundGlassSurface(
              strong: true,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '移除离线下载？',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '将删除「$title」的本地副本，不会影响音乐来源中的原文件。',
                      style: TextStyle(color: dialogContext.soundMutedText),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('移除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ) ??
      false;
}

Future<bool> _confirmClearAll(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SoundGlassSurface(
              strong: true,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '删除全部缓存？',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '离线保存的歌曲也会被删除。WebDAV 和本地来源中的原文件不会受到影响。',
                      style: TextStyle(color: dialogContext.soundMutedText),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('全部删除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ) ??
      false;
}

void _showStorageMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(kib >= 100 ? 0 : 1)} KB';
  final mib = kib / 1024;
  if (mib < 1024) return '${mib.toStringAsFixed(mib >= 100 ? 0 : 1)} MB';
  final gib = mib / 1024;
  return '${gib.toStringAsFixed(gib >= 100 ? 0 : 1)} GB';
}

IconData _playbackModeIcon(PlaybackMode mode) => switch (mode) {
  PlaybackMode.sequential => Icons.arrow_right_alt_rounded,
  PlaybackMode.repeatOne => Icons.repeat_one_rounded,
  PlaybackMode.repeatAll => Icons.repeat_rounded,
  PlaybackMode.shuffle => Icons.shuffle_rounded,
};

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: context.soundMutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SoundGlassSurface(
          blur: false,
          showShadow: false,
          borderRadius: BorderRadius.circular(SoundRadii.card),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  Divider(height: 1, indent: 66, color: context.soundDivider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.value,
    this.onTap,
    this.expanded = false,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.soundMutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(
                  value!,
                  style: TextStyle(color: context.soundMutedText, fontSize: 12),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: context.soundMutedText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackModeSelector extends StatelessWidget {
  const _PlaybackModeSelector({
    required this.selected,
    required this.onSelected,
  });

  final PlaybackMode selected;
  final ValueChanged<PlaybackMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        const gap = 8.0;
        final itemWidth =
            (constraints.maxWidth - 28 - gap * (columns - 1)) / columns;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final mode in PlaybackMode.values)
                SizedBox(
                  width: itemWidth,
                  child: _PlaybackModeChoice(
                    key: ValueKey('settings-playback-mode-${mode.name}'),
                    mode: mode,
                    selected: mode == selected,
                    onTap: () => onSelected(mode),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaybackModeChoice extends StatelessWidget {
  const _PlaybackModeChoice({
    required this.mode,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PlaybackMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? SoundColors.accent.withValues(alpha: 0.15)
                : context.soundTint(0.035),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? SoundColors.accent.withValues(alpha: 0.65)
                  : context.soundDivider,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _playbackModeIcon(mode),
                size: 18,
                color: selected
                    ? SoundColors.accent
                    : context.soundSecondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? context.soundPrimaryText
                        : context.soundSecondaryText,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: SoundColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
