# Playback vertical-slice validation

Do not expand the product feature set until this slice passes on both Windows
and Android. Package choice remains provisional until the measurements below
are recorded.

## Evidence recorded so far

- [x] macOS: real MP3 loads, reports a 223.190-second duration, plays, and
      settles at 120.000 seconds after seek.
- [x] macOS: real FLAC loads, reports a 223.453-second duration, plays, and
      settles at 120.000 seconds after seek.
- [x] Android 16 arm64 emulator: debug APK installs and launches without a
      Flutter layout or native crash.
- [x] Android 16 arm64 emulator: real MP3 loads from app-private storage,
      reports a 223.190-second duration, plays, and advances 120.000 -> 121.250
      -> 122.000 seconds after seek without regression.
- [x] Android 16 arm64 emulator: real FLAC reports a 223.453-second duration
      and advances 120.000 -> 121.250 -> 122.000 seconds after seek without
      regression.
- [x] The late 119.861-second native callback observed after a 120.000-second
      macOS seek is filtered by `NativePositionGate` and covered by a unit test.
- [x] The repeatable WebDAV fixture rejects missing credentials, supports
      `PROPFIND`, and returns correct single-range `206` responses.
- [x] Authenticated WebDAV FLAC loads and seeks through non-zero byte ranges on
      macOS and the Android 16 emulator.
- [x] With `JustAudioPlaybackEngine`, authenticated WebDAV MP3 opens a target
      byte range for a 120-second seek on macOS and Android instead of consuming
      only the initial response.
- [x] FFmpeg HTTP options (`seekable`, `multiple_requests`, and bounded request
      sizes) were tested with MediaKit on both platforms and did not change its
      open-ended sequential MP3 behavior; the experiment was removed.
- [ ] Windows, background playback, and system media controls still require
      validation.

## Fixtures

- One local MP3 with ID3 title, artist, album, cover, and embedded lyrics.
- One local FLAC with Vorbis comments, cover, and embedded lyrics.
- One authenticated WebDAV MP3.
- One authenticated WebDAV FLAC.
- A 30-minute or longer file for seek and resume testing.

## Required behavior

- [x] Local MP3 and FLAC load and begin playback on macOS and Android.
- [ ] Local MP3 and FLAC load and begin playback on Windows.
- [x] Authenticated WebDAV FLAC streams and issues non-zero ranges for seek on
      macOS and Android.
- [x] Authenticated WebDAV MP3 settles the recorded remote seek by requesting a
      non-zero byte range with the default just_audio adapter.
- [ ] Play, pause, next, previous, and completion transitions are correct.
- [ ] Dragging previews time locally and sends one seek when released.
- [x] Engine position settles without regression in recorded local MP3/FLAC
      and remote FLAC runs.
- [ ] Rapid track changes never show progress from the previous track.
- [ ] Buffering is visually different from paused playback.
- [ ] Android continues playback with the screen off.
- [ ] Android notification controls and metadata stay synchronized.
- [ ] Windows system media controls and metadata stay synchronized.
- [ ] Relaunch restores the queue and saved position without autoplaying.

## Measurements

Recorded with a local authenticated fixture throttled to 256 KiB/s:

- Android WebDAV MP3: first playable position in about 2.2 seconds; a seek from
  0 to 120 seconds took about 17.6 seconds with MediaKit. With just_audio, the
  server receives `bytes=5090034-` and playback resumes in roughly 0.7-1.0
  seconds.
- macOS WebDAV MP3: the same seek resumes after about 17.6 seconds; a generated
  CBR MP3 still takes about 12.4 seconds with MediaKit. With just_audio, the
  server receives a range starting near byte 5.0 MB and playback resumes in
  roughly 0.04 seconds.
- Android WebDAV FLAC: first playable position in about 3.1 seconds; the server
  opens ranges near byte 26.6 MB for the 120-second seek and playback resumes
  after about 6.9 seconds.
- No progress regression occurred in these runs, but the MP3 settlement time
  fails acceptance.

Record these for local and WebDAV playback on both platforms:

- Time to first audio.
- Seek settlement time at 10%, 50%, and 90%.
- Number of engine position regressions after 20 seeks.
- Bytes transferred before playback starts.
- Memory after scanning 1,000 and 10,000 tracks.
- CPU usage while playing with the now-playing screen visible and hidden.

## Acceptance rule

The media adapter is accepted only when all required behavior passes and no
position regression occurs during the 20-seek test. If a package cannot meet
the system-media-control or authenticated-seek requirements without invasive
forking, replace it behind `PlaybackEngine` rather than leaking workarounds
into UI code.

Current verdict: **just_audio is the default production adapter** based on the
macOS and Android WebDAV MP3 result. MediaKit remains an explicit fallback.
Windows local playback, authenticated proxy behavior, background playback, and
system media controls still block final acceptance of the complete vertical
slice.
