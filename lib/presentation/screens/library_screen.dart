import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../domain/library_models.dart';
import '../controllers/library_catalog_controller.dart';
import '../widgets/album_art.dart';
import '../widgets/source_badge.dart';

enum LibraryBrowseMode { albums, artists, genres, songs }

extension LibraryBrowseModePresentation on LibraryBrowseMode {
  String get label => switch (this) {
    LibraryBrowseMode.albums => '专辑',
    LibraryBrowseMode.artists => '艺人',
    LibraryBrowseMode.genres => '流派',
    LibraryBrowseMode.songs => '歌曲',
  };

  IconData get icon => switch (this) {
    LibraryBrowseMode.albums => Icons.album_outlined,
    LibraryBrowseMode.artists => Icons.person_outline_rounded,
    LibraryBrowseMode.genres => Icons.grid_view_rounded,
    LibraryBrowseMode.songs => Icons.music_note_outlined,
  };
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.catalog,
    required this.mode,
    required this.onModeChanged,
    required this.onOpenAlbum,
    required this.onOpenCollection,
    required this.onPlayTrack,
    required this.onManageSources,
    super.key,
  });

  final LibraryCatalogController catalog;
  final LibraryBrowseMode mode;
  final ValueChanged<LibraryBrowseMode> onModeChanged;
  final ValueChanged<Album> onOpenAlbum;
  final ValueChanged<LibraryCollection> onOpenCollection;
  final void Function(Track track, List<Track> queue) onPlayTrack;
  final VoidCallback onManageSources;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catalog,
      builder: (context, _) {
        final albums = catalog.albums;
        final albumByTrackId = {
          for (final album in albums)
            for (final track in album.tracks) track.id: album,
        };
        final tracks = catalog.tracks;
        final artists = buildArtistCollections(albums);
        final genres = buildGenreCollections(albums);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 34, 32, 20),
              sliver: SliverToBoxAdapter(
                child: _LibraryHeader(
                  mode: mode,
                  onModeChanged: onModeChanged,
                  albumCount: albums.length,
                  trackCount: tracks.length,
                ),
              ),
            ),
            if (catalog.status == LibraryCatalogStatus.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogMessage.loading(),
              )
            else if (catalog.status == LibraryCatalogStatus.error)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogMessage.error(
                  message: catalog.errorMessage ?? '无法读取资料库。',
                  onAction: catalog.refresh,
                ),
              )
            else if (albums.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogMessage.empty(onAction: onManageSources),
              )
            else
              ...switch (mode) {
                LibraryBrowseMode.albums => _albumSlivers(albums),
                LibraryBrowseMode.artists => _collectionSlivers(
                  artists,
                  emptyMessage: '资料库中没有可浏览的艺人。',
                ),
                LibraryBrowseMode.genres => _collectionSlivers(
                  genres,
                  emptyMessage: '资料库中没有流派信息。',
                ),
                LibraryBrowseMode.songs => _songSlivers(tracks, albumByTrackId),
              },
          ],
        );
      },
    );
  }

  List<Widget> _albumSlivers(List<Album> albums) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 140),
        sliver: SliverGrid.builder(
          itemCount: albums.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisExtent: 280,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemBuilder: (context, index) {
            final album = albums[index];
            return _AlbumCard(album: album, onTap: () => onOpenAlbum(album));
          },
        ),
      ),
    ];
  }

  List<Widget> _collectionSlivers(
    List<LibraryCollection> collections, {
    required String emptyMessage,
  }) {
    if (collections.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CatalogMessage._(
            icon: Icons.category_outlined,
            title: '暂无内容',
            message: emptyMessage,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 140),
        sliver: SliverGrid.builder(
          itemCount: collections.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 300,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemBuilder: (context, index) {
            final collection = collections[index];
            return _CollectionCard(
              collection: collection,
              onTap: () => onOpenCollection(collection),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _songSlivers(
    List<Track> tracks,
    Map<String, Album> albumByTrackId,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
        sliver: SliverToBoxAdapter(
          child: _SongHeader(
            trackCount: tracks.length,
            onPlayAll: () => onPlayTrack(tracks.first, tracks),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 140),
        sliver: SliverPrototypeExtentList.builder(
          itemCount: tracks.length,
          prototypeItem: _LibraryTrackRow(
            track: tracks.first,
            album: albumByTrackId[tracks.first.id]!,
            onTap: () {},
            onOpenAlbum: () {},
          ),
          itemBuilder: (context, index) {
            final track = tracks[index];
            final album = albumByTrackId[track.id]!;
            return _LibraryTrackRow(
              track: track,
              album: album,
              onTap: () => onPlayTrack(track, tracks),
              onOpenAlbum: () => onOpenAlbum(album),
            );
          },
        ),
      ),
    ];
  }
}

class _LibraryTrackRow extends StatelessWidget {
  const _LibraryTrackRow({
    required this.track,
    required this.album,
    required this.onTap,
    required this.onOpenAlbum,
  });

  final Track track;
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onOpenAlbum;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        onTap: onTap,
        leading: SizedBox.square(
          dimension: 48,
          child: AlbumArt(album: album, borderRadius: 6),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${track.artist} · ${track.albumTitle}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SourceBadge(track.source),
            IconButton(
              onPressed: onOpenAlbum,
              tooltip: '打开专辑 ${album.title}',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.mode,
    required this.onModeChanged,
    required this.albumCount,
    required this.trackCount,
  });

  final LibraryBrowseMode mode;
  final ValueChanged<LibraryBrowseMode> onModeChanged;
  final int albumCount;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '资料库',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$albumCount 张专辑 · $trackCount 首歌曲',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final candidate in LibraryBrowseMode.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('library-mode-${candidate.name}'),
                    avatar: Icon(candidate.icon, size: 17),
                    label: Text(candidate.label),
                    selected: mode == candidate,
                    onSelected: (_) => onModeChanged(candidate),
                    selectedColor: SoundColors.accent.withValues(alpha: 0.24),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage._({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  const _CatalogMessage.loading()
    : this._(
        icon: Icons.library_music_outlined,
        title: '正在读取资料库',
        message: '正在加载已索引的专辑和歌曲。',
        loading: true,
      );

  const _CatalogMessage.empty({required VoidCallback onAction})
    : this._(
        icon: Icons.create_new_folder_outlined,
        title: '资料库还是空的',
        message: '添加一个本地音乐文件夹，扫描完成后歌曲会显示在这里。',
        actionLabel: '管理音乐来源',
        onAction: onAction,
      );

  const _CatalogMessage.error({
    required String message,
    required VoidCallback onAction,
  }) : this._(
         icon: Icons.error_outline_rounded,
         title: '无法读取资料库',
         message: message,
         actionLabel: '重试',
         onAction: onAction,
       );

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 150),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 48, color: Colors.white38),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, height: 1.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: SoundColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({required this.trackCount, required this.onPlayAll});

  final int trackCount;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$trackCount 首歌曲',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onPlayAll,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('播放全部'),
          style: FilledButton.styleFrom(
            backgroundColor: SoundColors.accent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumArt(album: album),
          const SizedBox(height: 10),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  album.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              SourceBadge(album.source),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final LibraryCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final album = collection.albums.first;
    return InkWell(
      key: ValueKey('library-collection-${collection.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AlbumArt(album: album),
              Positioned(
                right: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      collection.kind == LibraryCollectionKind.artist
                          ? Icons.person_rounded
                          : Icons.grid_view_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            collection.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            '${collection.albums.length} 张专辑 · ${collection.tracks.length} 首歌',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
