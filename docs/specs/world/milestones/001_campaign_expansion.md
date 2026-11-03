# Campaign expansion stages13..22

User authorized background implementation and automated testing, with actual
computer-control tests accumulated later. No GUI activation/input while user
uses the PC. Every stage remains AWAITING_INTERACTIVE until live proof passes.

1. Stage13 world travel: world002/slice002; migration, costs/reserve, map/clock,
   entry gates. Implemented/automated PASS: stage13-headless-20261101,39/39,
   zero diagnostics. Actual L13-01/02 NOT_RUN. Report in docs/qa/stages.
2. Stage14 world003/slice003: implemented/automated PASS, stage14-headless-20261101,
   40/40, zero diagnostics. Road boundary/restart/rewards/HP guards pass; live
   L14-01/02 NOT_RUN. Stage14 report in docs/qa/stages.
3. Stage15 world004/slice004: implemented, stage15-headless-20261101,41/41 PASS,
   zero diagnostics; L15-01 NOT_RUN. Stage15 report persisted.
4. Stage16 world005/slice005 and combat slice102 persistent equipment and
   expedition/combat handoff: implemented, stage16-headless-20261101,42/42 PASS,
   33 Python tests,50 equipment checks, zero diagnostics. Strict scene checker
   1997 files and stage16-release-20261101 export/extended EXE probe PASS.
   L16-01/02 NOT_RUN; final stage16 report records hashes and all acceptance.

5. Stage17 world006/slice006: implemented. User's "DAWAJ DALEJ" extended background
   implementation without desktop-control release. stage17-headless-20261101
   passes43/43 (39 Python tests,48 trade checks), strict scene checker2003 files
   and stage17-release-20261101 extended EXE probe PASS, zero diagnostics.
   L17-01/02 NOT_RUN. Report docs/qa/stages/2026-11-01-stage-17.md.

6. Stage18 world007/slice007, combat slice103: implemented;44/44 automated PASS,
   stage18-headless-20261101,0 diagnostics. Live L18-01/02 NOT_RUN.
7. Stage19 presentation002/slice002: implemented after18 PASS. Shared campaign
   shell/skin/navigation, responsive Region/Town/Stash/Trading/Training layouts,
   bounded inventory scrolling, visible feedback and training/equipment controls.
   stage19-verified-20261101 passes45/45 (45 Python tests,1219 interface checks),
   strict checker2022 files and stage19-release-final-20261101 EXE probe PASS,
   zero diagnostics. Actual L19-01/02 NOT_RUN; stage19 report has build hashes.

8. Stage20 presentation003/slice003: implemented, stage20-headless-20261102,
   46/46 PASS,0 diagnostics. Icon/filter/portrait/slot/retained Equip interactions,
   profile comparisons and full layout regression pass. Actual L20-01/02 deferred.
9. Stage21 presentation004/slice004: implemented; stage21-headless-20261102,
   47/47 PASS,0 diagnostics. Visual stock/free-loot selection, retained trades,
   XP bars/tiers/deltas and hover-refresh lifetime test pass. Live deferred.
10. Stage22 presentation005/slice005: town/region polish and final package,
   implemented after21 PASS. Final stage22-fixed-headless-20261102 passes48/48,
   46 Python tests/2223 UI assertions, strict scene checker2032 files and
   stage22-release-fixed-20261102 EXE probe PASS,0 diagnostics. Preview review
   caught collapsed tile text; explicit text heights and regression assertions
   repaired it before final rebuild. Actual L22-01/02 NOT_RUN.

Next: actual session in docs/qa/live-test-scenarios.md,30 cases all NOT_RUN.
Wait for user to release desktop
controls; no GUI while they use the PC. Further content stages are not authorized
by this milestone. Read docs/CONTINUE_HERE.md and stage22 report to continue.

Latest commands passed: `.venv/Scripts/python.exe tools/qa/verify_project.py --run-id stage22-fixed-headless-20261102`,
skill check_godot_project.py with `--json --strict`, and
`.venv/Scripts/python.exe tools/qa/export_smoke.py --release --run-id stage22-release-fixed-20261102`.
