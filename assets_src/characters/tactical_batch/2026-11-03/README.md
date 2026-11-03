# Painted bandits and wolf: production candidate

Authorized stages63..65, presentation025. New art awaits user review; this is not
an approval inherited from the old six actors. English sources/tools accompany
the current game's Polish preview controls.

Three actors: burgundy-hood bandit archer, iron-capped wooden-shield fighter and
adult grey/brown wolf. Seven primary clips each; guard additionally has a shield
brace. SE is drawn, SW is a disclosed reflection that reverses handedness and
costume asymmetry. No extra camera views are invented.42 primary source clips
plus2 block clips /272 runtime cels. Older eight-view families remain archived.

`preview.html` plays actual exported atlases at native1x and enlargement with
pause, frame buttons, speed and ground travel. `comparison.png` shows native
SE above/SW below; Bran reference is the first column. Ground/lighting are the
game's actual materials. New figures are separate from old accepted graphics.

Each actor retains:

- `prompts.json`, nine total built-in imagegen prompts with references and raw
  output paths; `raw/` contains every generated input unchanged.
- `clips_source.json`: segmentation, scale, timing and source pose order.
- `*_cells.json` and `export_report.json`: actual separated component bounds,
  normalization, margins and initial source reopen proof.
- `frames/`, action atlases and `manifest.json`: final SE drawing/measurement.
- `directions/south_west/`: reflected source frames/atlases and disclosure.
- `source_proof.json`: final canonical source hashes, idle contact/reopen proofs.

Editable sources:
`assets_src/aseprite/characters/tactical_batch/2026-11-03/<actor>/<view>/<clip>.aseprite`.
The44 edited animation sources are canonical after registration/contact edits.

Re-export the saved edited cels without regenerating or changing source files:

```powershell
.venv/Scripts/python.exe tools/qa/export_tactical_sources.py
.venv/Scripts/python.exe tools/qa/build_tactical_batch_preview.py
.venv/Scripts/python.exe tools/assets/build_catalogue.py
```

Explicitly rebuilding from generated raw drawings replaces new actor source
edits: `tools/qa/build_tactical_enemy_batch.py`. Existing accepted actors are
never inputs for destructive re-export. `--package-only` refreshes metadata only
after checking the already verified canonical source hashes; it cannot approve
a changed Aseprite file without an explicit source export.

Humans retain171px standing bodies; wolf uses95px standing silhouette on the
same384x320 canvas/pivot192,270 and100px/metre scale. Wolf normalization uses ONE
standing locomotion reference, adjusted for raw sheet cell resolution, throughout
crouch/bite/fall, so a lying animal is not expanded by its shorter bounding box.
Both species retain125msx8 walk/160px stride. Idle registration locks human lower
shins at232 and wolf lower paws at250; the upper body still breathes.

The generated wolf's last ready-idle cell touches the raw sheet edge, so it is
excluded: its four-cel ready loop uses poses13/14/15/14, explicitly holding the
second drawing. Saturated generator edge residue is removed in Aseprite; no
automatic alpha cleanup changes brown/grey material colours. Source segmentation
also excludes a detached arrow in the bow release cell: the game owns its actual
projectile. Bow aim/release is1800ms, release after1260ms; guard blade/wood shield
keep the authored poses and wolf bites at its lunging fourth drawing.

Runtime texture and full animation tests are numerical proofs. The source poses
and static board were inspected; continuous motion and ordinary user gameplay
still await L64/L65 review. No claim of a reusable skeletal rig, eight newly drawn
views, or automatic visual approval is made.
