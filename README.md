# Reverie

A clean, artwork-first cross-platform music player built with Flutter.
一个简洁、以封面为先的跨平台音乐播放器，基于 Flutter 构建。

| Platform 平台 | Status 状态 |
|---------------|-------------|
| Android       | ✓           |
| iOS/iPadOS    | ✓           |
| macOS         | ✓           |
| Windows       | ✓           |
| Web           | Preview 预览 |

## Features · 功能特性

- **Artwork-first UI · 封面优先界面** — library, album detail, now playing with lyrics, and a responsive mini player. 包含音乐库、专辑详情、正在播放（含歌词）和响应式迷你播放器。
- **Local playback · 本地播放** — MP3 and FLAC via `JustAudioPlaybackEngine` (ExoPlayer on Android, AVPlayer on Apple, WinRT on Windows). 通过 `JustAudioPlaybackEngine` 支持 MP3/FLAC 播放。
- **Remote playback · 远程播放** — authenticated WebDAV sources with byte-range seeking. 支持带认证的 WebDAV 源，具备字节范围寻址能力。
- **Library management · 音乐库管理** — albums, artists, genres, songs, favorites, recent plays, playback history, and editable playlists. 专辑、艺术家、流派、歌曲、收藏、最近播放、播放历史和可编辑播放列表。
- **Smart scanning · 智能扫描** — local folder and WebDAV scanners with shared release grouping, multi-disc merging, and deletion-aware rescanning. 本地文件夹和 WebDAV 扫描支持发行分组、多碟合并和感知删除的重新扫描。
- **Persistence · 持久化存储** — Drift/SQLite v3 repository; user state survives catalog rescans via stable track IDs. 基于 Drift/SQLite v3，用户状态通过稳定曲目 ID 在目录重新扫描后保持不变。
- **Desktop shortcuts · 桌面快捷键** — keyboard focus, media keys, Tab/arrow/Enter navigation, and a built-in shortcut reference (`Cmd/Ctrl + /`). 键盘焦点、媒体键、Tab/方向键/Enter 导航及内置快捷键参考。
- **Session resilience · 会话恢复** — playback position checkpoints, background flush, and restoration without autoplay. 播放位置检查点、后台刷新及无自动播放的恢复。

## Quick Start · 快速开始

```sh
flutter pub get
flutter run -d macos
```

Add a local folder or WebDAV source in Settings, scan it, and play from the library.
在设置中添加本地文件夹或 WebDAV 源，扫描后即可从音乐库播放。

## Verify · 验证

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
> macOS 钥匙串需要开发签名应用 — 请先在 Xcode 中登录 Apple 开发者账号。

## Versioned releases · 版本发布

`pubspec.yaml` is the single version source. The user-facing version always has
three parts (`MAJOR.MINOR.PATCH`); the value after `+` is an internal store build
number and is not shown in the app.

`pubspec.yaml` 是唯一的版本来源。用户可见版本始终为三段式（`MAJOR.MINOR.PATCH`），`+` 后的值为内部构建号，不会在应用中显示。

Use the release wrapper instead of calling `flutter build ... --release`
directly. A successful invocation increments the patch and internal build
numbers once, then writes versioned packages to `dist/`. If a build fails, the
version change is rolled back.

请使用发布包装工具而非直接调用 `flutter build ... --release`。成功执行后会自动递增补丁版本号和内部构建号，并将版本化包写入 `dist/`。若构建失败，版本变更将自动回滚。

```sh
# Preview the next version without changing files. 预览下个版本号，不修改文件
dart run tool/release.dart --dry-run

# Build every release target supported by the current host. 构建当前主机支持的全部目标
dart run tool/release.dart

# Or build selected targets with one shared version bump. 或选择目标构建，共享一次版本升级
dart run tool/release.dart android macos web
```

For a rebuild of the current version, pass `--no-bump`. GitHub releases require
a three-part tag such as `v1.0.2`; the workflow uses that tag as the package
version and uploads names such as `reverie-1.0.2-android.apk`.

如需重新构建当前版本，请使用 `--no-bump`。GitHub Releases 要求三段式标签（如 `v1.0.2`），工作流将以此标签作为包版本并上传 `reverie-1.0.2-android.apk` 等文件。

## Website · 网站

The project site is served via GitHub Pages at [robeshell.github.io/MusicPlayerNext](https://robeshell.github.io/MusicPlayerNext/), with the Flutter Web app under `/MusicPlayerNext/app/`.
项目网站通过 GitHub Pages 部署，Flutter Web 应用位于 `/MusicPlayerNext/app/` 路径下。

```sh
flutter build web --release --base-href /MusicPlayerNext/app/
bash tool/build_pages.sh
```

## Documentation · 文档

- [Kanban · 看板](docs/KANBAN.md)
- [Design Foundation · 设计基础](docs/DESIGN_FOUNDATION.md)
- [Architecture · 架构](docs/ARCHITECTURE.md)
- [Playback Validation · 播放验证](docs/PLAYBACK_VALIDATION.md)
- [Audio Format Matrix · 音频格式矩阵](docs/AUDIO_FORMAT_MATRIX.md)
- [WebDAV Fixture · WebDAV 测试夹具](docs/WEBDAV_FIXTURE.md)

