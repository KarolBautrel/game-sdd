# User-approved dungeon checkpoint and game publication

The user approves the current dungeon appearance for now and explicitly requests
publication to the game repository, followed by a reminder of the earlier review
queue. Visual state: USER_APPROVED_FOR_CURRENT_STAGE. Detailed physical full-flow
actions are not inferred from this feedback. Preserve existing native/model proofs.

Publication target: existing `origin/master` at
https://github.com/KarolBautrel/game-sdd. This is a public repository. Author identity
was verified as Karol Bautrel / GitHub KarolBautrel id93617105, using the approved
`93617105+KarolBautrel@users.noreply.github.com` address. Local/remote history was
equal before publication; no force push or history rewrite is needed.

Checkpoint includes the coherent dungeon work: 59 runtime components, editable
Aseprite sources/exports, approved/rejected art history, native dynamic UI,
typography/whole portraits/HP, legal route preview/confirm, packing/event fixes,
research, owning specs, native evidence and the updated acceptance/review queue.
The full optional local skill package is ignored, preserved locally and published
separately in its private workshop repository. It is not duplicated into this
public game repository. Existing game content/pool/seeds/saves remain unchanged.

Pre-publication proof:

```powershell
.venv/Scripts/python.exe tools/qa/verify_project.py --run-id ashen-publication --timeout 90
git diff --cached --check
```

PASS: all 69 verification checks, zero diagnostic errors; validator, Python tests,
Godot import, all discovered GDScript suites and all six scene boots. Native
review proof remains in `2026-11-04-ashen-native-ui.md`. All17 historical snapshot
hashes match both working files and staged payloads, including LFS object ids.
Staged publication was checked to contain no full private skill copy or ZIPs.
Exact push/ref/LFS receipt is saved under ignored `artifacts/ui-workshop-review/`.

Next: step2 equipment, then world journey, forest battle, mine battle and courtyard
review. See `2026-11-04-player-review-checklist.md`. The15-layout adapter remains
backlog. No additional feature implementation was requested in this turn.
