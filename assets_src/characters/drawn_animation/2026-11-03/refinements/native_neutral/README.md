# Native neutral pose and calm gait

USER_ACCEPTED_FOR_NOW2026-11-03. The user requests publication to the main game
repo and explicitly defers future posture/locomotion polish. user_acceptance.json
preserves the decision; executable verification keeps that status on reruns.

User newly authorizes a shield-warrior-based neutral stance and slower stepping
after the stage59 rollback. The rejected stage58 model is not reused. User visual
acceptance is temporary and explicit; numeric checks remain separate evidence.

Use existing native character/weapon pixels for bounded pose edits. The Aseprite
script preserves original knight head/boot pixels and keeps combat/walking art
unchanged. Front relaxed arms are composed from native shield-warrior pixels,
rear from the knight's accepted draw pose, with the rigid existing sword master.
No whole-body interpolation or generative model replacement. Only24 neutral idle
PNGs change. Source masks/transforms and final editable sources are retained.

Cadence:8x125ms=1000ms cycle,160px stride,160px/s. This reduces five foot contacts
per second to two, with a moderate20% reduction from57's travel speed. The old
initial100px/s was too slow; the new travel remains60% faster. All768 walk drawing
pixels remain exact. Camera-scale locomotion must still be judged in continuous
normal-speed gameplay; the preview floor follows declared distance/cadence.

301 files are backed up with SHA256 in before/identities.json; all2304 old runtime
PNG identities in before/runtime_pixels.json. Verification/report files retain
source, protected pixel, scope, timing and local-player results.

Reproduce from the game root with installed Aseprite:

```powershell
.venv/Scripts/python.exe tools/qa/refine_native_neutral.py --step all
.venv/Scripts/python.exe tools/qa/package_drawn_roster.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/build_drawn_animation_preview.py
.venv/Scripts/python.exe tools/qa/build_native_neutral_preview.py
.venv/Scripts/python.exe tools/qa/verify_native_neutral.py
.venv/Scripts/python.exe tools/assets/build_catalogue.py
.venv/Scripts/python.exe tools/qa/run_drawn_godot_checks.py --import-assets --require-all --regression
```

`--step neutral` rebuilds only the native neutral pose; `--step timing` retimes
walk sources and metadata. Existing raw-sheet export needs the recorded neutral
postprocess afterwards. The source manifest records that postprocess. Preview has
28 samples: direct reference, previous/current neutral, and gait comparisons.
The published reusable workshop is not modified by this game-specific candidate.
