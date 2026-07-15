# Sound design foundation

This document defines Sound's current visual and interaction direction. The
light glass redesign approved in July 2026 replaces the earlier dark-first
foundation; implementation details may evolve, but deviations from these
principles require a deliberate design review.

Reference: [light glass settings concept](screenshots/settings-light-glass-concept.png).

## Product character

Sound is an artwork-first personal music player for local and remote libraries.
It should feel calm, warm and native rather than technical: strong cover art,
quiet metadata, milky glass surfaces, and one vivid coral-red playback accent.

## Approved visual direction

- Light mode is the product default and primary acceptance target.
- The canvas is warm off-white rather than pure white.
- Sidebar, navigation, mini player, menus and dialogs use translucent frosted
  glass. Ordinary list rows and cards use cheaper translucent fills so blur is
  not multiplied through long scrolling surfaces.
- Glass remains subtle: no blue sci-fi tint, strong glow, mirror-like chrome or
  decorative transparency that weakens text contrast.
- Album artwork supplies color. The surrounding chrome stays neutral and does
  not compete with covers.
- macOS uses a transparent, full-size titlebar: the app background continues
  behind the native traffic-light controls, the duplicate window title is
  hidden, and interactive content starts below a 38 px safe region.
- Dark mode remains supported by the same semantic tokens, while the product
  default and primary acceptance target stay light.

## Core screens retained from the prototype

1. Library
   - Desktop: translucent sidebar plus a content canvas.
   - Compact: bottom navigation for library, search, and settings.
   - Primary library views: recent, albums, songs, artists, and genres.
   - Album cards use large square art with compact title, artist, and source.
2. Album detail
   - Large cover on the left, title and metadata on the right.
   - Red primary play action and quiet secondary shuffle action.
   - Dense track table on desktop; simpler rows on compact layouts.
3. Now playing
   - Immersive artwork-led background derived from the current cover palette.
   - Artwork and transport on one side, lyrics or queue on the other.
   - Synchronized lyrics keep the active line near the visual center.
4. Settings and music sources
   - Settings begins with real Playback, Library, Operations and About groups.
   - Music sources are a Library subpage rather than the whole settings area.
   - Connections and indexed folders are separate concepts.
   - Local folder and WebDAV are first-release source types.
   - Scanning, authentication, unavailable, and error states must be explicit.
5. Mini player
   - Desktop uses a full-width 76 px bottom dock: progress runs along its top
     edge, cover and title stay left, transport stays centered on the same row,
     and contextual actions stay right.
   - Compact platforms retain cover, title, play/pause, and next.

## Design tokens

### Color

- Accent: `#FF5A4D`; hover: `#FF7567`; pressed: `#E3483E`.
- Canvas: `#FAF5EE`, with a very soft `#FFFAF4` to `#F6EFE7` diagonal wash.
- Glass surface: white at 72% opacity; strong floating glass: 87%.
- Primary text: `#1C1C22`; secondary text: `#5A5A62`; auxiliary text:
  `#77747D`. Auxiliary text is reserved for short metadata.
- Control border: charcoal at 8%; hairline and internal divider: 5.5%; glass
  border: 7%, plus a restrained white inner highlight where useful.
- Glass blur: 20 px for navigation and menus, 28 px for the mini player and
  modal surfaces. Blur is not applied to every repeated library row.
- Shadow: warm charcoal at 8-14% opacity with a wide, soft radius.
- Album palette colors may tint hero glows and the now-playing backdrop, but
  never replace the playback accent.

### Shape and elevation

- Album artwork: 8-10 px corner radius at normal sizes.
- Cards and settings rows: 14-16 px continuous radius.
- Small controls: 10 px radius; menus: 12 px; sheets: 18 px; dialogs: 20 px.
- Desktop player: square outer corners, soft upward shadow, thin glass border.
- Compact player: 16 px radius above the bottom navigation.
- Source badges: capsule shape with a subtle translucent fill.
- Avoid strong card borders and heavy drop shadows.

### Type

- Page heading: 26 px on compact layouts and 28 px on medium/wide layouts.
- Section heading: 16-20 px, bold.
- Album hero title: 28-34 px, heavy, slightly tight tracking.
- Body/track title: 13-14 px, semibold.
- Secondary metadata: 11-13 px.
- Time values use tabular/monospaced figures.
- Lyrics: 20 px with a 22 px active cue, heavy and rounded where available.

### Spacing

- Desktop content gutter: 32 px.
- Major vertical sections: 28-32 px.
- Album grid gap: 20-22 px.
- Album card artwork: adaptive 150-190 px on desktop.
- Track row vertical padding: approximately 11 px.

## Interaction rules

- Artwork is the strongest visual element on every browsing screen.
- Source identity is visible but quiet; it must not dominate song metadata.
- The UI never fabricates playback progress.
- During scrubbing, the thumb and time labels may show a local preview.
- A seek is sent once on release; the UI then returns to engine-reported time.
- Loading and buffering are distinct from paused playback.
- Track changes snap lyrics to the new position. Only natural adjacent lyric
  transitions animate.
- Desktop and mobile share hierarchy and components, not identical layouts.

## Responsive layout

- Compact mobile/tablet windows (below 820 px or below 600 px tall): 18 px
  gutter, bottom navigation, stacked album detail, compact player, and
  full-screen now playing.
- Medium (820-1099 px): 24 px gutter, 216 px sidebar, two-column detail where
  space permits, and the desktop player dock.
- Wide (1100 px and above): 32 px gutter, 236 px sidebar, flexible content, and
  the full-width desktop player dock.
- macOS, Windows and Linux never switch to phone navigation. Their windows use
  desktop navigation at every supported size and enforce a 900 x 600 logical
  pixel minimum; smaller desktop widths only tighten content density.
- Content should remain useful from 360 px mobile width to wide desktop windows.

## Deliberately excluded from the first release

- SMB
- Online artwork and lyric enrichment
- Cross-device synchronization
- watchOS and tvOS clients
- Visual effects that require platform-specific motion sensors
