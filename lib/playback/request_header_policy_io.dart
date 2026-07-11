import 'dart:io';

/// just_audio_windows does not pass custom request headers to WinRT
/// MediaPlayer. On Windows, just_audio's loopback proxy supplies those headers
/// and preserves byte-range requests made by the native player.
bool get useProxyForPlaybackRequestHeaders => Platform.isWindows;
