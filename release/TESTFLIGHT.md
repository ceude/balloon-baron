# TestFlight builds

Xcode Cloud's "Branch Changes" start condition watches only this folder (`release/`), so the many daily pushes
don't each start a build. To send a new build to TestFlight, add a line below and push, or start the workflow by
hand in Xcode (Report navigator → Cloud → Start Build). Bump `CURRENT_PROJECT_VERSION` in `tools/gen_xcodeproj.py`
only for a manual Archive from Xcode; Xcode Cloud numbers its builds itself.

- 2026-10-25: first TestFlight build (v110)
