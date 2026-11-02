# Refined actors, equipment and environment production

Current override2026-11-02: user rejected the character/weapon refinements.
Playable characters are restored to stage33 animated PNGs. Do not enable the
modular atlas or3D equipment preview again without a new explicit request.
The world/terrain/rekwisites, icons, illustrated portraits and save-compatible
five slots remain. Visible modular armour/boots/helmet is deferred; prior native
PASS proved execution/bounds, not acceptable animation or appearance. The model
sections below document an inactive experiment; environment production remains
current. Read the stage37 rollback report/handoff before continuing.

Owner presentation010, world005, combat equipment053/terrain088. Stages34..36
extend the accepted original-roster direction. No paid generator/account is used.
Original models/reference identities remain in `ROSTER.md` and its manifest.

Runtime actors are now rigged GLBs rendered into one transparent GPU atlas per
battle/gallery/equipment host. The game grid, hit testing and resolver remain2D.
Eight front-biased facings,18-degree camera,100px/metre and640x448 atlas cells
with ground pivot320,314 are shared. Updates occur when presentation poses change;
atlas dimensions grow with actual occupants. Source `.blend`, default-look FBX,
baked texture and per-weapon action maps live in `assets_src/characters/modular/`.
The GLB includes alternate hero parts. Six creature exports reuse their original
source rigs; wraith keeps its authored collapse. Aliases remain compatible.

The renderer selects body/armour/boots/headwear/weapon/off-hand components.
Heroes keep their identity when exchanging weapons. Null armour/boot slots retain
tunic/trousers/soft shoes; a closed helmet hides the default headwear. Bow quiver
and shield selection are independent. Item `appearance` data is presentation
metadata; only trusted combat profiles affect the resolver. New boots/headwear
are cosmetic. World005 documents three-slot-save migration and snapshot safety.
Inventory pairs an independent128px illustrated portrait with the live actor.

Portrait prompt/source/provenance: `assets_src/portraits/`; final crops and editable
sources: `tools/aseprite/hero_portraits.lua`. They are not low-poly head renders.
Gear icons render actual authored meshes and pass through Aseprite as well.

Environment:28 original models, matching materials and18-degree renders in
`assets_src/environment/props/`, four painted material swatches with saved prompt,
34 floor/prop/ledge sprites plus a shared contact shadow. Aseprite normalizes
sprites, matches opposing floor edges and adds bounded contact shadows. Do not
use a Cycles shadow-catcher plane for these cutouts: it polluted the whole alpha
canvas. Props carry physical-scale sizes/ground pivots in `world_art.json`.
255 retained prop IDs and69 floor/background IDs route through one semantic
adapter. Editor previews share this mapping; serialization retains authored IDs.
Logical blocked/low-cover tiles without a placed prop have a terrain silhouette,
and elevation uses a textured30px front face matching the existing actor offset.
No authored placements, passability, cover rules or costs are changed.

Rebuild from the active repository, using background Blender5.2.3 and hidden
Aseprite1.3.17.2 (paths/toolchain details in `TOOLING.md`):

1. `tools/blender/build_modular_actors.py -- --ids <comma-separated roster IDs>`
2. `python tools/assets/build_modular_manifest.py`
3. `tools/blender/verify_modular.py` and `verify_refined_fbx.py` via Blender
   `--background --factory-startup --python-exit-code 1 --python <script>`.
   FBX checks intentionally disable importer auto-connected bones, preserving
   authored hand translations. Both Blender and actual FBX clearance are tested.
4. `tools/blender/render_equipment_icons.py`, then hidden Aseprite batch with
   `--script-param root=<repo> --script tools/aseprite/equipment_icons.lua`.
5. `tools/blender/build_world_props.py` (optional `-- --ids arch,chest,...`), then
   hidden Aseprite `world_art.lua` with the same root parameter. Re-run FBX checks
   after geometry changes.
6. `python tools/assets/build_catalogue.py`,
   `python tools/assets/build_world_manifest.py`, Godot headless import, then
   `python tools/qa/verify_project.py --run-id <fresh-id>`.
7. Native minimized/no-focus fixtures via `tools/qa/render_campaign.py`: play
   views `environment,roster,combat,dungeon`, campaign view `gear`, at1080p/1440p/4K.
   Export and repeat against the final EXE/PCK after gameplay/runtime changes.

Persistent proofs: modular `verification.json`/`fbx-check.json`, environment
`fbx-check.json`/`manifest.json`, `modular_actor_tests.gd`4403 checks,
`equipment_appearance_tests.gd`31 checks, `environment_art_tests.gd`2400 checks,
Python delivery tests and named stage reports. Headless uses the established PNG
actor fallback and cannot prove the modular GPU art. Native fixtures use actual
GPU rendering/engine-local clicks, not physical desktop input or ordinary play.
Physical acceptance is in `docs/qa/live-test-scenarios.md` and remains deferred.
