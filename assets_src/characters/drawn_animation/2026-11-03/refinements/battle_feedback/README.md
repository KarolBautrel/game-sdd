# Battle feedback correction

Stage57 / presentation022. User requests faster walking, a wider standing base
for the exactly rear-facing sword/shield warrior, and a sword more occluded by
the torso. Current candidate awaits visual retest; the remaining animation was
described positively. No terminal battle result was reported.

`before/identities.json` preserves313 baseline files; `before/runtime_pixels.json`
records all2304 original runtime PNG identities. Only36 warrior/north drawings
change. The existing north death source/atlas/frames are byte-identical. Every
walk source uses50ms cels:400ms cycles/80px stride; all non-walk timings remain.

`jobs.json` and warrior/north/prompts.json contain the exact built-in imagegen edit
prompt and original output path. Raw output is copied to warrior/north/raw.
`sequence_rear_stance_clean.png` is derived only through the recorded Aseprite
sheet cleanup. The input has one touching boot/blade pair; two transparent pixel
rows separate their components before extraction. Original generated data is kept.
Canonical final Aseprite sources retain source roundtrip and planted idle layers.

Reproduce from the retained raw source, from the game repository:

```powershell
.venv/Scripts/python.exe tools/qa/apply_drawn_battle_feedback.py
.venv/Scripts/python.exe tools/qa/package_drawn_roster.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/build_drawn_animation_preview.py
.venv/Scripts/python.exe tools/qa/build_drawn_battle_feedback_preview.py
.venv/Scripts/python.exe tools/qa/verify_drawn_battle_feedback.py
.venv/Scripts/python.exe tools/assets/build_catalogue.py
.venv/Scripts/python.exe tools/qa/run_drawn_godot_checks.py --import-assets --require-all --regression
```

`--backup-only` preserves the original baseline once; it verifies existing hashes
on later runs. `--metadata-only` resumes manifest updates after an already passing
Aseprite retiming report. Raster work always uses Aseprite. The complete recipe
does not generate more images or modify the published reusable workshop baseline.

`verification.json`, `walk_timing_report.json`, `idle_contact_report.json` and
`rear_pose_report.json` retain source/scope proofs. `preview.html` has18 native/2x
before/after samples. Static comparison PNGs show previous on left/current on right.
Continuous visual acceptance remains separate from source/numerical checks.
