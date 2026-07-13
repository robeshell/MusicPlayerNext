import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/domain/library_models.dart';

void main() {
  test('artist browsing keeps an album together and exposes collaborators', () {
    const leadTrack = Track(
      id: 'lead',
      title: 'Lead Song',
      artist: 'Lead Artist',
      albumTitle: 'Shared Album',
      duration: Duration(minutes: 3),
      source: SourceKind.local,
    );
    const duetTrack = Track(
      id: 'duet',
      title: 'Duet Song',
      artist: 'Guest Artist',
      albumTitle: 'Shared Album',
      duration: Duration(minutes: 4),
      source: SourceKind.local,
    );
    const album = Album(
      id: 'album',
      title: 'Shared Album',
      artist: 'Lead Artist',
      source: SourceKind.local,
      palette: [Colors.indigo, Colors.black],
      tracks: [leadTrack, duetTrack],
    );

    final artists = buildArtistCollections(const [album]);
    final lead = artists.singleWhere(
      (collection) => collection.title == 'Lead Artist',
    );
    final guest = artists.singleWhere(
      (collection) => collection.title == 'Guest Artist',
    );

    expect(lead.albums, [album]);
    expect(lead.tracks, [leadTrack, duetTrack]);
    expect(guest.albums, [album]);
    expect(guest.tracks, [duetTrack]);
  });

  test('genre browsing falls back to album genre and keeps uncategorized', () {
    const inherited = Track(
      id: 'inherited',
      title: 'Inherited Genre',
      artist: 'Artist',
      albumTitle: 'Album',
      duration: Duration(minutes: 3),
      source: SourceKind.local,
    );
    const explicit = Track(
      id: 'explicit',
      title: 'Explicit Genre',
      artist: 'Artist',
      albumTitle: 'Album',
      duration: Duration(minutes: 3),
      source: SourceKind.local,
      genre: 'Jazz',
    );
    const album = Album(
      id: 'album',
      title: 'Album',
      artist: 'Artist',
      genre: 'Rock',
      source: SourceKind.local,
      palette: [Colors.teal, Colors.black],
      tracks: [inherited, explicit],
    );
    const uncategorizedAlbum = Album(
      id: 'unknown',
      title: 'Unknown',
      artist: 'Artist',
      source: SourceKind.webDav,
      palette: [Colors.blueGrey, Colors.black],
      tracks: [
        Track(
          id: 'unknown-track',
          title: 'Unknown',
          artist: 'Artist',
          albumTitle: 'Unknown',
          duration: Duration(minutes: 2),
          source: SourceKind.webDav,
        ),
      ],
    );

    final genres = buildGenreCollections(const [album, uncategorizedAlbum]);
    expect(genres.singleWhere((item) => item.title == 'Rock').tracks, [
      inherited,
    ]);
    expect(genres.singleWhere((item) => item.title == 'Jazz').tracks, [
      explicit,
    ]);
    expect(
      genres.singleWhere((item) => item.title == '未分类').tracks.single.id,
      'unknown-track',
    );
  });
}
