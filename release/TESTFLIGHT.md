# TestFlight builds

Xcode Cloud's "Branch Changes" start condition watches only this folder (`release/`), so the many daily pushes
don't each start a build. To send a new build to TestFlight, add a line below and push, or start the workflow by
hand in Xcode (Report navigator → Cloud → Start Build). Bump `CURRENT_PROJECT_VERSION` in `tools/gen_xcodeproj.py`
only for a manual Archive from Xcode; Xcode Cloud numbers its builds itself.

- 2026-10-25: first TestFlight build (v110)
- 2026-10-25: second TestFlight build: clouds and basket swing in flight, night scene switch, holding board fixes, antitrust fine fix
- 2026-10-25: third TestFlight build: price sheet, bankrupt fleet card, launch field (designs first, tap opens balloons), workshop label, 3D balloon picker and studio, clouds move with the balloon, app icon, licence pilots-only, localization review, boarding animation switch, game-style switches, inspector Ekin Demir
- 2026-10-26: fourth TestFlight build: temporary flagship, rename balloons and fly any balloon yourself, Balloon Show (booking card, crashed balloons drop out, max 30 shown, figures), first-flight coach and price lesson, wind tags and layer lean, landing column, hazy far fairy chimneys, store v113 (Egypt unlock for Luxor, Founder Pack, four new decorations, five show figures), region chip always on top
