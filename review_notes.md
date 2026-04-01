# App Store Review Notes — Sixstrings v1.0.0

## App Description
Sixstrings is a free guitar companion app for learning songs, tuning your guitar, and practicing with a metronome. No account or login required.

## Review Notes

This app does not require a login or account creation. All features are immediately available upon launch. There are no in-app purchases or subscriptions.

The app requires **microphone access** for two features:
1. **Guitar Tuner** — detects pitch from the microphone to help tune each string
2. **Chord Detection** — listens while the user plays guitar and identifies chords in real time on the Song screen

If the reviewer does not have a guitar available, these features can be skipped — the app will show a permission prompt and gracefully handle denial. All other features (song search, chord sheets, metronome, transpose) work without microphone access.

**Speech Recognition** is used for voice search on the Home screen. It can also be skipped — the text search field works without it.

### How to Test

1. **Home Tab** — Type any song name (e.g. "Wonderwall", "Hotel California") in the search bar. Tap a result to view chords.
2. **Song Screen** — Scroll through chord sheet. Use transpose buttons (+/-) to change key. Toggle auto-scroll, chord diagram, and detected chord badge from Settings.
3. **Tuner Tab** — Grant microphone access. Play a guitar string near the device. The tuner shows the detected note, frequency, and cents offset.
4. **Metronome Tab** — Tap play to start. Adjust BPM with slider or +/- buttons. Try "Tap Tempo" by tapping the button rhythmically. Change time signature (4/4, 3/4, 6/8).
5. **Settings Tab** — Switch theme (Light/Dark/System), change language (English, Russian, Romanian), toggle song display options.

### Network Requirements
- Internet connection is required for song search and loading chord sheets.
- The tuner and metronome work fully offline.

### Permissions Used
| Permission | Reason |
|---|---|
| Microphone | Chord detection and guitar tuner |
| Speech Recognition | Voice search for songs |

### Backend
- API: `https://api.6strings.app/api`
- The backend serves song search results and chord sheet data only. No user data is collected or stored on servers.

### Privacy
- No user accounts
- No analytics or tracking SDKs
- No data collection
- All user data (favorites, recent songs, settings) stored locally on device
- Favorites backed up to iOS Keychain for reinstall recovery

### Content
- Song chord sheets are sourced from publicly available guitar tablature
- No user-generated content
- No social features
