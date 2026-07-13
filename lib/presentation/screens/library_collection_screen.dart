import 'package:flutter/material.dart';

import '../../core/sound_theme.dart';
import '../../domain/library_models.dart';
import '../../playback/playback_controller.dart';
import '../widgets/album_art.dart';
import '../widgets/progress_scrubber.dart';
import '../widgets/source_badge.dart';

class LibraryCollectionScreen extends StatelessWidget {
  const LibraryCollectionScreen({
    required this.collection,
    required this.playback,
    required this.onBack,
    required this.onOpenAlbum,
    super.key,
  });

  final LibraryCollection collection;
  final SoundPlaybackController playback;
  final VoidCallback onBack;
  final ValueChanged<Album> onOpenAlbum;

  @override
  Widget build(BuildContext context) {
    final albumByTrackId = {
      for (final album in collection.albums)
        for (final track in album.tracks) track.id: album,
    };
    return Material(
      color: Colors.transparent,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CollectionHero(
              collection: collection,
              onBack: onBack,
              onPlay: collection.tracks.isEmpty
                  ? null
                  : () => playback.playTrack(
                      collection.tracks.first,
                      queue: collection.tracks,
                    ),
            ),
          ),
          if (collection.albums.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(32, 8, 32, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '专辑',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
              sliver: SliverGrid.builder(
                itemCount: collection.albums.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 238,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemBuilder: (context, index) {
                  final album = collection.albums[index];
                  return _CollectionAlbumCard(
                    album: album,
                    onTap: () => onOpenAlbum(album),
                  );
                },
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${collection.tracks.length} 首歌曲',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (collection.tracks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 140),
              sliver: SliverPrototypeExtentList.builder(
                itemCount: collection.tracks.length,
                prototypeItem: _CollectionTrackRow(
                  track: collection.tracks.first,
                  album: albumByTrackId[collection.tracks.first.id]!,
                  onTap: () {},
                  onPlayNext: () {},
                  onOpenAlbum: () {},
                ),
                itemBuilder: (context, index) {
                  final track = collection.tracks[index];
                  final album = albumByTrackId[track.id]!;
                  return _CollectionTrackRow(
                    track: track,
                    album: album,
                    onTap: () =>
                        playback.playTrack(track, queue: collection.tracks),
                    onPlayNext: () => playback.playNext(track),
                    onOpenAlbum: () => onOpenAlbum(album),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.collection,
    required this.onBack,
    required this.onPlay,
  });

  final LibraryCollection collection;
  final VoidCallback onBack;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              collection.kind == LibraryCollectionKind.artist ? '艺人' : '流派',
              style: TextStyle(
                color: collection.palette.first,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              collection.title,
              style: TextStyle(
                fontSize: compact ? 30 : 40,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${collection.albums.length} 张专辑 · ${collection.tracks.length} 首歌曲',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('播放全部'),
              style: FilledButton.styleFrom(
                backgroundColor: SoundColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ],
        );
        final artwork = collection.albums.isEmpty
            ? const SizedBox.square(dimension: 220)
            : AlbumArt(
                album: collection.albums.first,
                size: compact ? 210 : 230,
              );

        return Container(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 34),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.65, 0.8),
              radius: 1.2,
              colors: [
                collection.palette.first.withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 18),
              if (compact) ...[
                Center(child: artwork),
                const SizedBox(height: 28),
                details,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    artwork,
                    const SizedBox(width: 30),
                    Expanded(child: details),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CollectionAlbumCard extends StatelessWidget {
  const _CollectionAlbumCard({required this.album, required this.onTap});

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
          const SizedBox(height: 9),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _CollectionTrackRow extends StatelessWidget {
  const _CollectionTrackRow({
    required this.track,
    required this.album,
    required this.onTap,
    required this.onPlayNext,
    required this.onOpenAlbum,
  });

  final Track track;
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onPlayNext;
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
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
          '${track.artist} · ${album.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SourceBadge(track.source),
            Text(
              formatDuration(track.duration),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '歌曲操作',
              onSelected: (value) {
                if (value == 'play-next') onPlayNext();
                if (value == 'open-album') onOpenAlbum();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'play-next', child: Text('下一首播放')),
                PopupMenuItem(value: 'open-album', child: Text('打开专辑')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
