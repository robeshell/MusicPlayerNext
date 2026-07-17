# Local patches

This directory vendors `audio_service` 0.18.19.

On an active Android audio service, notification transport intents are
delivered directly to the existing media session. This avoids an unnecessary
`MediaBrowserCompat` reconnect for every notification tap. Play and pause are
also routed directly because the upstream Android implementation represents
those two notification actions with private bypass key codes.

If the service is not alive, the upstream receiver path is retained so Android
can start and reconnect to it normally.

The Android resource lookup falls back to the application icon only for the
notification small icon. Missing transport controls use the corresponding
Android system icon, so play, pause, previous, and next never collapse into the
same symbol. The app keeps its monochrome small icon and every upstream
`audio_service_*` transport drawable through
`android/app/src/main/res/raw/keep.xml`.

Custom playback actions are mirrored into the notification action list as well
as the media session playback state. This preserves Android 13+ behavior while
also supporting OEM notification panels that ignore custom media-session slots.

The notification body is bound to an explicit no-op broadcast and the
media-session activity is always cleared. OriginOS otherwise recreates a
card-wide activity click target when it sees a null content intent and can open
the app when the user taps near an action button.
