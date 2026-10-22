# Balloon Baron: Cappadocia

iOS hot-air-balloon company tycoon. Solo developer (Turkish speaker) + Claude. All code, art and sound are made in code.

## Layout
- `Packages/BalloonBaronCore`: pure-Swift game logic (no UIKit/SwiftUI). Builds and tests on Linux.
- `BalloonBaron/`: iOS app (SwiftUI menus, SpriteKit flight scene). The developer's Mac only runs **Xcode 15.2** (Swift 5.9, iOS 17.2 SDK), so `project.pbxproj` is the classic format listing every file. After adding, removing or renaming files in `BalloonBaron/`, run `python3 tools/gen_xcodeproj.py`. Don't use Swift 5.10+ features (e.g. `nonisolated(unsafe)`) or SwiftUI APIs newer than iOS 17.2.
- `prototype/balloon-baron.html`: the playable HTML prototype. It is the reference for behaviour and balance numbers.
- `docs/GAME_DESIGN.md`: mechanics and numbers. Keep it in sync when balance changes.

## Workflow
- Design changes we discuss are made **only in the HTML prototype** (`prototype/balloon-baron.html`) and published to the artifact https://claude.ai/artifact/9LyVDNN1dngsGGydyFuNYt. Do not touch the Swift code for them.
- Every prototype change that the Swift app doesn't have yet goes into `docs/PORT_QUEUE.md`. When the user decides, port the queue to Swift in one batch and clear it.

## Rules
- The core never contains player-facing text. It emits ids and enums (`DayEvent`, `HezMessage`, `Review`), and the app localizes them.
- Every player-facing string lives in `BalloonBaron/Localizable.xcstrings` with all six languages: en (source), tr, de, es, ja, ko. The catalog is generated: edit `tools/strings/*.py`, then run `python3 tools/strings/build.py` (it checks placeholders match across languages). Use `loc("key", args…)` with `%@` / `%1$@` placeholders. Avoid plurals by writing "Label: N". In Turkish, never put a suffix directly after a name placeholder.
- Money is shown with `eur()`, which formats for the player's locale.
- Port prototype behaviour faithfully; balance changes are the user's call. When balance changes, update the prototype, the core and `docs/GAME_DESIGN.md` together.
- Minimum iOS 17, portrait only.

## Testing in the cloud
```
tools/install-swift-linux.sh && export PATH=/opt/swift/usr/bin:$PATH
cd Packages/BalloonBaronCore && swift test
```
The app target itself (SwiftUI, SpriteKit) only builds on a Mac with Xcode. GitHub Actions (`.github/workflows/ci.yml`) does both on every push to `main`: core tests on Swift 5.9 and the app built with Xcode 15.2, the developer's version. Errors and the result are on the run's summary page.

New fields in saved state (`GameState`, `RegionState`, `Holding`, `Design`, …) must be optional or have a type old JSON still decodes into, because saves use the synthesized `Codable` and a missing key would make an existing save fail to load.
