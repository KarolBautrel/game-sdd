# Natural cadence and two-handed knight stances

Stage58 supersedes the stage57 cadence candidate, which the user found frantic.
Keep root speed and gait frequency separate: cycle stride / cycle time determines
travel speed. Current calibration is800ms/160px =200px/s; the rejected candidate
was400ms/80px at the same speed. Natural cadence still requires continuous visual
review; numeric consistency alone does not establish natural movement.

Knight combat stance is broader/staggered; neutral idle and walking carry a lowered
drawn sword. Five drawn views plus three disclosed reflections. Only three knight
actions are redrawn (128 runtime frames); all other2176 PNGs are unchanged from the
post57 baseline. Non-walk timings and the previous shield-warrior correction remain.

`before/identities.json`:861 preserved files. `before/runtime_pixels.json`:2304
runtime identities. `jobs.json`: exact built-in imagegen prompts and output paths.
The raw images and Aseprite reference boards are retained. Canonical edited sources
remain under assets_src/aseprite; temporary source exports are ignored artifacts.

Reproduction from game root, using installed Aseprite and Python:

```powershell
.venv/Scripts/python.exe tools/qa/balance_drawn_motion.py --step all
.venv/Scripts/python.exe tools/qa/package_drawn_roster.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/build_drawn_animation_preview.py
.venv/Scripts/python.exe tools/qa/build_drawn_motion_balance_preview.py
.venv/Scripts/python.exe tools/qa/verify_drawn_motion_balance.py
.venv/Scripts/python.exe tools/assets/build_catalogue.py
.venv/Scripts/python.exe tools/qa/run_drawn_godot_checks.py --import-assets --require-all --regression
```

Preview36 native/2x before/after samples at preview.html. Walking floor displacement
uses declared stride in both panes; root speed is equal while cadence differs.
Planted combat bases are measured in stance_report.json; source/scope proof is
verification.json. Visual retest remains pending. The published English workshop
baseline is not modified by these game-specific corrections.
