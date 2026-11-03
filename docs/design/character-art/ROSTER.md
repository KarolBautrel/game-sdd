# Original tactical roster

Current user rollback2026-11-02: this stage33 PNG roster is again the active
native/headless character renderer. The later modular GLB/weapon/pose refinements
are rejected and disconnected. Keep the independent illustrated portraits and
new environment assets from [the later batch](EQUIPMENT_WORLD.md).

Presentation009/slice009 and milestone004 own the replacement. The user approved
the original-model direction and requested all27 families on2026-11-02. Existing
designs remain references, not orthographic measurements. Hidden surfaces are
inferred. Physical approval of the final roster is still pending.

## Design and camera

`resources/data/presentation/original_roster.json` is the canonical roster,
equipment/palette/scale, camera and frame-count/timing contract. Its JSON schema is
validated by validate_all.py. `references.json` retains the old designs and
hashes. In the calibration comparison, old models are on the left and originals
on the right: Bran, Torin, Ash-road Raider.

Use18-degree elevation, orthographic100pixels/metre and a fixed ground pivot.
The east/west and north diagonal views intentionally show more of the front,
like the old tactical illustrations. North retains a true rear view. All eight directions are rendered independently; shields/weapons
are not mirrored. Standard canvas512×384/pivot256,282. Spear users use640×448/
pivot320,314 for extra margins at the same world scale. Creature/Brute profile
scale changes actual geometry, never the pixel density. The default saved Blender
inspection camera is315degrees; runtime facings are the canonical yaw table.

Bran retains the blue neckcloth/mantle, sword and cross shield; Torin the blue
hood, bow and quiver. Bandits retain red/brown/charcoal cloth, masks, heavy/fur/
spiked armour and their distinct weapons. Skeletons have original bone anatomy;
the wraith has a floating torn shroud and dissolve. Animals/arthropods use their
own anatomy, rigs and clips. Bowstring tips follow the bow and the nock follows
the drawing hand. The spear has a distinct thrust clip.

## Source and reproducibility

Each family has its own folder under `assets_src/characters/roster/` containing
`.blend`, `.fbx`, `textures/*_albedo.png`, and measured `model.json`. All visible
meshes are authored in `tools/blender/roster_geometry.py` or
`roster_creatures.py`. Imported mannequin geometry is deleted. CC0 UAL provides
the compatible humanoid rig/motion; six nonhumanoid species have original rigs
and actions. Reusable weapon, shield and quiver constructors live in the geometry
module and are also preserved as weighted geometry in every relevant model.

The material atlas was generated with built-in imagegen. Its full prompt,
original generated-image path and provenance are saved alongside the atlas in
`MATERIAL-PROMPT.txt` and `provenance.json`. No paid external generation was used.
Baked albedos are portable relative textures. Do not substitute imported visible
mannequins or placeholder meshes for the original geometry.

Run the installed Blender5.2.3 in background mode with factory startup and
`--python-exit-code 1`, using `tools/blender/build_roster.py -- --ids ID,ID`.
`--preview` writes front/side/rear/game/combat/death previews without replacing
runtime art; do not normalize a preview-only delivery. Full renders produce256
frames per model in `artifacts/roster/ID/raw/` plus a portrait. Rebuild only affected
IDs, inspect the previews, then regenerate their full actions. Selective
`--actions`/`--directions` repairs require an existing full raw render and unchanged
geometry/UV/material/camera settings for the other frames; otherwise rebuild the
entire model. A `.rendering` marker blocks normalization of incomplete jobs. Use the watcher
for first deliveries; when rebuilding an existing batch, wait for all selected
Blender jobs to finish before normalizing their IDs.

Normalize using Aseprite batch mode, script `tools/aseprite/roster.lua`, parameters
`root=ABSOLUTE_REPO` and `ids=ID,ID`. It thresholds alpha, quantizes colours,
adds a one-pixel contour, checks all margins and saves40 editable action/facing
files plus an editable portrait per model under `assets_src/aseprite/`.
`roster_timing.lua` reopens saved clips to verify runtime-matching durations.
Stable per-model sprite reports and the aggregate timing proof live beside the
model sources, so validation does not depend on ignored artifacts after a clone. Runtime
PNGs live only in `assets/combat/characters/original/ID/`. Do not edit these pixels
through Python. The per-model contact sheets and normalization reports remain
in artifacts for review.

Reimport FBX using `tools/blender/verify_roster.py -- --ids ID,ID`. This checks
actual delivered mesh counts, UV, weights, textures and motion in all five clips.
It restores authored unconnected joints after Blender's FBX importer auto-connects
coincident joints; connected joints suppress the hand translation keys used by
the fitted long-weapon clips. The FBX contains those translations. Prefer the
native .blend for editing; when reviewing FBX in Blender, preserve unconnected
joints. Godot Skeleton transforms have no such connection constraint. The
verifier samples long-weapon/hand floor clearance in every exported clip and
persists the complete hashed27-model proof as `fbx-check.json` beside the sources.
Run `.venv/Scripts/python.exe tools/qa/check_roster.py --write` for the complete
source/runtime hash manifest, then build the texture catalogue and run project
verification. A partial `--ids` check is evidence for that batch only.

## Runtime and review

CombatUnitArt maps every canonical ID and the three legacy aliases to originals.
It preserves the native canvas and shared ground anchor; it does not normalize
small species to the warrior's height. Measured idle bounds keep resource/status
panels above the actor, targeting feedback above those panels, and board headroom
protects the top row. Imported textures are reused without
duplicating GPU images. Matching hero portraits are used by PartyRoster.

Combat -> Tools -> Character gallery opens a passive paginated viewer with all
27 families, facing/action selectors, pause, and close/Escape. It suspends battle
shortcuts and never changes combat state. The review fixture's `rosterhuman`
view covers stage32; `roster` covers all27 in stage33. Native captures and injected
engine-local clicks do not replace ordinary gameplay or visual approval.

After explicit desktop release, run the pending31..33 cases in
`docs/qa/live-test-scenarios.md` on the larger left DISPLAY1/windowed. Include
normal-speed gait, grip, death, crowded board readability, ordinary victory,
return/restart and a full closed-log audit. Preserve earlier pending cases.
