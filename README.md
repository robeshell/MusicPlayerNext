# Reverie

A clean, artwork-first cross-platform music player built with Flutter.

| Platform | Status |
|----------|--------|
| Android  | ✓      |
| iOS/iPadOS | ✓    |
| macOS    | ✓      |
| Windows  | ✓      |
| Web      | Preview |

## Features

- **Artwork-first UI** — library, album detail, now playing with lyrics, and a responsive mini player
- **Local playback** — MP3 and FLAC via `JustAudioPlaybackEngine` (ExoPlayer on Android, AVPlayer on Apple, WinRT on Windows)
- **Remote playback** — authenticated WebDAV sources with byte-range seeking
- **Library management** — albums, artists, genres, songs, favorites, recent plays, playback history, and editable playlists
- **Smart scanning** — local folder and WebDAV scanners with shared release grouping, multi-disc merging, and deletion-aware rescanning
- **Persistence** — Drift/SQLite v3 repository; user state survives catalog rescans via stable track IDs
- **Desktop shortcuts** — keyboard focus, media keys, Tab/arrow/Enter navigation, and a built-in shortcut reference (`Cmd/Ctrl + /`)
- **Session resilience** — playback position checkpoints, background flush, and restoration without autoplay

## Quick Start

```sh
flutter pub get
flutter run -d macos
```

Add a local folder or WebDAV source in Settings, scan it, and play from the library.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build macos --debug
flutter build apk --debug
flutter build web
flutter build ios --simulator --debug
```

> macOS Keychain requires a development-signed app — sign in with an Apple developer account in Xcode first.

## Website

The project site is served via GitHub Pages at [robeshell.github.io/MusicPlayerNext](https://robeshell.github.io/MusicPlayerNext/), with the Flutter Web app under `/MusicPlayerNext/app/`.

```sh
flutter build web --release --base-href /MusicPlayerNext/app/
bash tool/build_pages.sh
```

## Documentation

- [Kanban](docs/KANBAN.md)
- [Design Foundation](docs/DESIGN_FOUNDATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Playback Validation](docs/PLAYBACK_VALIDATION.md)
- [Audio Format Matrix](docs/AUDIO_FORMAT_MATRIX.md)
- [WebDAV Fixture](docs/WEBDAV_FIXTURE.md)

## Screenshots

| Desktop Library | Desktop Now Playing |
|:---:|:---:|
| ![Desktop Library](docs/screenshots/library-desktop.png) | ![Desktop Now Playing](docs/screenshots/now-playing-desktop.png) |

| Mobile Library | Mobile Now Playing |
|:---:|:---:|
| ![Mobile Library](docs/screenshots/library-mobile.png) | ![Mobile Now Playing](docs/screenshots/now-playing-mobile.png) |

| Android Library | Android Now Playing | Android Sources |
|:---:|:---:|:---:|
| ![Android Library](docs/screenshots/android-library.png) | ![Android Now Playing](docs/screenshots/android-now-playing.png) | ![Android Sources](docs/screenshots/android-sources.png) |
