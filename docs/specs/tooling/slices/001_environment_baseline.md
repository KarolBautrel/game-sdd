# Slice: environment and baseline verification

Owner: `docs/specs/tooling/001_stage_verification.md`
Date: 2026-11-01

| ID | Setup/action | Expected result | Proof |
| --- | --- | --- | --- |
| E0-01 | Create `.venv`, install `requirements-dev.txt`, run the data validator | Validation passes using local Python | runner `python_validation` |
| E0-02 | Run the workspace Godot executable | Version is 4.7 stable | runner `godot_version` |
| E0-03 | Import project before executing suites | Import exits zero without errors | runner `godot_import` |
| E0-04 | Run every discovered GDScript suite | Every suite exits zero without errors | runner results, individual logs |
| E0-05 | Load all four entry scenes headless | Each reaches the bounded smoke exit without errors | runner `scene_*` results |
| E0-06 | Supply a missing Godot executable | Runner exits nonzero; no PASS report | CLI negative check |
| E0-07 | Child process emits an error with exit code zero, or exceeds timeout | Check fails, diagnostics/logs retained | `tests/test_verify_project.py` |
| E0-08 | Configure local profile with `start_game.ps1 -ConfigureOnly`, then Run in Project Manager | Windowed game fits inside DISPLAY1; configuration does not start or stop processes | launch JSON and visible window observation |
| E0-09 | Observe and operate preparation, movement, an event and combat in actual game | Controls and feedback usable on DISPLAY1; no blocking issue | hands-on log in stage report |
| E0-10 | Launch DungeonDebug with `-TraceInput`, send a real key/click through Computer Use | Actual window geometry and received events appear in stdout; default launch remains quiet | launch stdout plus observed response |

E0-09 is mandatory. Computer Use access now works; actual playthrough found a
combat HUD regression (combat slice 095). Repair and replay acceptance before
stage 1. See the stage report for observed actions.
