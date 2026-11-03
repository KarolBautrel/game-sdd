# Continue development here

Last handoff: 2026-11-03. This is a status/navigation document; owning domain
specs define behavior. This handoff does not authorize additional implementation
when the user has only requested an explanation or plan.

## Next-session entry: read this first

The user ended this session and will resume with:
"Wracamy do tego na czym skonczylismy ostatnio".
Read the complete [2026-11-03 resume handoff](handoffs/2026-11-03-drawn-2d-resume.md)
before acting. It records rejected work, exact Git state/identity, researched vs
installed tools, the proposed small2D art/motion stages and pending permissions.
Do not repeat the whole research, resume historical3D queues or interpret the
resume phrase as approval to rewrite master or pay for external generation.

Current work branch is `2d-art-research`. User explicitly requests these research/
handoff notes committed and pushed there under the verified KarolBautrel identity;
they are now committed on that branch and its publication is verified at session
close. Obtain the current commit SHA from Git/remote, not from a self-reference
in this file. No further art work is requested before tomorrow.

## Current status: 3D archived;2.5D research complete; historical Git scope pending

Latest user2026-11-03 reviewed the motion and rejects the result: crooked-looking
legs, wide/stiff gait, wrist-driven sword twirling instead of a natural cut,
unconvincing hands (gloves desired). Technical checks did not establish convincing
motion. Do not continue the 3D pilot/full-set queue or describe it as accepted.

User explicitly requests a complete current-state commit/push to `3d-models`,
then internet research for detailed drawn/painted2.5D characters and animation,
using BG1/2 and Pillars of Eternity2 as visual references. Preserve all existing
sources and production work. No destructive rollback, new cast/model work,
installation/purchase, runtime change or unreleased desktop input is authorized.
Read [archive/rejection note](qa/2026-11-03-3d-models-archive.md).

Archive push confirmed: `origin/3d-models` initially
`e696d1c4a841c0400d691cd9d8df040677ee5be4`, matching local. LFS fsck,843 source/
staged identities, validator and42 headless style-preview checks PASS. Current
local branch `2d-art-research` descends from the corrected complete checkpoint
540524ed and carries the separately committed/pushed research and handoff notes.
Those notes have not changed the remote3D archive, master or runtime.

Read [drawn2.5D research](design/character-art/DRAWN_25D_RESEARCH.md),
[presentation019](specs/presentation/019_drawn_character_research.md),
[slice019](specs/presentation/slices/019_drawn_character_research.md),
[milestone014](specs/presentation/milestones/014_drawn_character_research.md),
[stage46](qa/stages/2026-11-03-stage-46.md).
Found real Scenario sprite-animation and SPA skills, PixelLab/AutoSprite/Retro
Diffusion MCPs, and deterministic Aseprite tooling. They are researched, not
installed/connected/tested. Existing imagegen and Aseprite remain available.
Recommended future pilot: one detailed drawn knight (pixel/painted candidates),
then short natural walk/whole-body sword action with gloves and a rigid blade.
No new asset production, provider account, paid call or full-set work performed.

Latest user also requests Git author/contribution repair after research. Local
config HAD `karol@example.local`; gh authenticates as KarolBautrel. Configuration
and current archive are now fixed using the account's verified GitHub noreply
address; supplied `karol.bautre@gmail.com` produced unlinked author/committer in
the commit API. Current `origin/3d-models` and local base:
`540524ed32e77f8d1f5219da62759a343ca2058a`, author+committer KarolBautrel confirmed
server-side. Source tree is identical to the initial archive. Default/master
and the original feature branch are unchanged. Read
[Git author repair receipt](qa/2026-11-03-git-author-repair.md).

An explicit scope question is pending for rewriting old history:53-commit local
preview preserves every tree/date/message;45 placeholder commits are on master,
51 on the feature lineage. Remote master/other heads must not be rewritten until
the user approves that broader scope. Old originals and preview refs are local;
the report names the next safe push sequence. Time passing is not approval.
The archive and future commits are attributed; no historical graph repair is
claimed yet. Do not merge rejected3D work into master to gain contributions.

The status below is historical technical evidence, superseded by this rejection.

## Historical source-art pilot (visually rejected)

User2026-11-03 reviewed the stage43 preview and says it is good. The restored
painted outfit/MPFB face/original stance with modestly smaller boots is the
accepted static appearance. Preserve that source/delivery as the next visual
baseline. Stage42's replacement armor remains rejected.

User's subsequent2026-11-03 "No to dawaj" authorizes this proposed source-art
pilot. Owner [presentation018](specs/presentation/018_warden_motion_pilot.md),
[slice018](specs/presentation/slices/018_warden_motion_pilot.md), ordered
[milestone013](specs/presentation/milestones/013_warden_motion_pilot.md).
Stages44–45 are technically delivered, with persisted acceptance and limits:
[stage44](qa/stages/2026-11-03-stage-44.md),
[stage45](qa/stages/2026-11-03-stage-45.md),
[guide](design/character-art/WARDEN_MOTION_PILOT.md).
Open `assets_src/characters/warden_motion_pilot/2026-11-03/preview.html`, or run
`tools/qa/start_warden_motion_preview.ps1` yourself. Three24fps loops, pause/frame
step/timelines/half speed/2x and four angles. The game still shows the existing
runtime roster; this source pilot is intentionally separate.

29 bones; exact five approved rest meshes/maps retained; new sword, idle48/walk32/
sword40 source frames,480 native PNGs,12 Aseprite animations, actual animated FBX.
All123 frames incl. closure measured; complete contact intervals drift<0.002mm,
no blade-path hits, bent knees/pose closure/rigid grip/four-view margins PASS.
Actual FBX six meshes/three clips pose drift<0.000002m after documented Blender
auto-connect flag normalization. Boards/joint/detail/FBX stills opened; validator
PASS. Approved stage43 and8223 roster +215 world hashes retained.

Next unfinished gate: M018-01 player controls/layout and M018-02 continuous1x
motion/user approval. The isolated browser host was unavailable; no desktop
input was used. Stills/measurements do not establish watched continuous playback.
Deep squat stress has coarse folds/a small rear skirt opening outside the three
delivered actions. No finger/face rig or full-range deformation claim.
After pilot approval, separately authorize full actions/eight directions and
distinct-face enemy families. No automatic continuation, runtime replacement or
unreleased desktop control; never resume rejected stage42.

Static art approval is not motion or normal-play acceptance.61 accumulated
physical cases remain NOT_RUN. No cast or outfit redesign is authorized.

## Completed rollback: stage42 rejected; stage41 restored with smaller boots only

Latest user2026-11-02 explicitly rejected the modelled armor/outfit and requests
the model from before that prompt, with only slightly smaller existing boots.
This cancels stage42's new body/stance/outfit and its automatic continuation queue.
Owner [presentation017](specs/presentation/017_warden_boots_only_rollback.md),
[slice017](specs/presentation/slices/017_warden_boots_only_rollback.md),
[milestone012](specs/presentation/milestones/012_warden_boots_only_rollback.md),
[stage43](qa/stages/2026-11-02-stage-43.md).

Open `assets_src/characters/mpfb_warden_boots_only/2026-11-02/proposal.png`.
Actual source is the exact stage41 `mpfb_warden.blend`; original painted costume,
MPFB face/eyes/hair/brows, original leg/body pose, UVs and materials retained.
Only the original low boot foot/ankle XY is reduced6%, smoothly returning to
unchanged upper shaft above0.32m. Height/ground and all non-boot vertices match.
There is no stage42 armor, PBR material simplification or rest-stance correction.

Technical PASS:65209 assertions dominated by exact actual-file vertex comparison,
original110384 triangles/5 meshes, all original5 texture files byte-identical,
actual FBX reimport/maps/UV/bounds, audit PASS with known static-assembly warnings.
38 stage41 +44 rejected-stage42 +8223 roster +215 world hashes preserved.
Matched restored/boot review board inspected; validator PASS. Reproduce with
background `tools/blender/restore_warden_boots_only.py` and hidden Aseprite
`tools/aseprite/warden_boots_only.lua`.

User accepted the static result2026-11-03. Do not automatically resume modelled-outfit, full-body
redesign, animation or cast work from historical queues. Stage42 sources remain
only as rejected evidence; do not present them as the selected style. No runtime,
save, visible launch, desktop input, paid generation, installation, commit or push.
61 physical game cases remain NOT_RUN. Preserve all prior dirty work/deliveries.

## Rejected previous task: corrected body and real3D outfit

User2026-11-02 accepted the improved face/direction, requested less crooked-looking
legs, smaller boots, actual armor/strap volume and distinct future faces. Owner
[presentation016](specs/presentation/016_mpfb_warden_modelled_outfit.md),
[slice016](specs/presentation/slices/016_mpfb_warden_modelled_outfit.md),
[milestone011](specs/presentation/milestones/011_mpfb_modelled_outfit.md).
Read [construction guide](design/character-art/MPFB_MODELLED_OUTFIT.md),
[stage42](qa/stages/2026-11-02-stage-42.md) and
[variation plan](design/character-art/CHARACTER_VARIATION_PLAN.md).

Open `assets_src/characters/mpfb_warden_outfit/2026-11-02/proposal.png`,
`comparison.png`, `all_views.png`. These are actual source-model renders and
Aseprite boards. Knee/ankle axes align; main boot footprint depth is about18%
smaller. Whole MPFB body/rest stance,105 modelled costume parts, real armor,
straps/framed buckles and new cloth/leather/metal materials replace the projected
costume. The exact approved head/eye/hair/brow geometry, UV and shaders remain.

Technical PASS:8906 assertions, actual FBX import,5 meshes/194738 offline triangles,
three baked PBR maps plus4 retained face-related maps, correct scalar color spaces,
eye alpha and bounds drift0.000000164m. Source/final mesh audits have zero errors;
5 static-assembly warnings retained.3 Aseprite boards and16 rendered views
inspected.38 stage41 +202 older model +8223 roster +215 world hashes unchanged.
Validator PASS. Source/editable posed master, separate parts, FBX/maps and evidence
are local; old sources/game assets are preserved.

Next: user review of this corrected body/outfit, then rig/weights and a short
normal-speed idle/walk/attack proof before the full set. Use the recorded
`anatomy_source_to_costume_matrix` to align a rig with the visible costume. Future
faces must differ in anatomy/age/skin/hair and gear/body silhouette. No additional
faces or cast batch is delivered yet. Some material/style simplification versus
the old painted costume is intentional and awaits user review.

No runtime replacement, visible app launch, desktop input, paid generation,
installation, commit or push. Existing61 physical game cases remain NOT_RUN.
Do not launch the old `-Scene styles` preview as though it showed this outfit.
Preserve all dirty work and the exact prior deliveries.

## Previous task: MPFB warden pilot delivered

User2026-11-02 selected MPFB/MakeHuman and authorized designing/showing one model
before agreement to animation and new enemies. Owner
[presentation015](specs/presentation/015_mpfb_warden_pilot.md),
[slice015](specs/presentation/slices/015_mpfb_warden_pilot.md),
[milestone010](specs/presentation/milestones/010_mpfb_warden_pilot.md).
Read [pilot guide](design/character-art/MPFB_WARDEN_PILOT.md) and
[stage41](qa/stages/2026-11-02-stage-41.md).

Open `assets_src/characters/mpfb_warden/2026-11-02/proposal.png`,
`comparison.png`, `all_views.png`. These are actual static-model renders with
editable Aseprite boards, not AI concepts or Godot captures. New source
`.blend`/FBX/local texture maps, coherent MPFB head/native skin UV, separate
eyes/hair/brows and retained authored warden costume. No old skin-view blend.
The old `-Scene styles` preview still shows the earlier A/B/C studies.

Official MPFB2.0.18 and system/Skins02/eye01 CC0 packs are installed and tested
with Blender5.2.3 in `~/.codex/tools/character-art/mpfb-2.0.18/`. Sources/hashes:
`tools/assets/mpfb_dependencies.json`; scripts and repeatable commands in guide.
No global Blender preference save. Factory-startup/offline CLI, no desktop input.

Technical PASS:8823 assertions, actual FBX import,5 meshes/110384 triangles,
all5 maps and eye alpha, bounds drift0.000000179m; mesh audit zero errors and5
recorded static-assembly warnings.202 earlier model +8223 roster +215 world
hashes unchanged. Three boards/all-view diagnostics inspected; validator PASS.
Clothing retains earlier paint/baked-light and overlap limits; hair is alpha
cards. This is not a rigged/deformation-ready or optimized-runtime3D asset.

Next is **user visual review**, not automatic animation or enemy generation.
After agreement: full-body outfit fit and rig/deformation, short idle/walk/attack
proof, then full actions/directions and varied enemies.61 physical game cases
remain NOT_RUN. No runtime replacement, visible launch, paid calls, commit or
push. Preserve all prior dirty work and source deliveries.

## Previous task: face-quality diagnosis and realistic pipeline research

User2026-11-02 reports stage40 faces are blurred, stretched and apparently
overlaid; asks for causes and external materials/workflows. Read
[realism research](design/character-art/REALISM_PIPELINE_RESEARCH.md),
[presentation014](specs/presentation/014_realistic_character_pipeline.md),
[slice014](specs/presentation/slices/014_realistic_character_pipeline.md),
[milestone009](specs/presentation/milestones/009_realistic_character_pipeline.md).

Read-only actual warden source diagnosis: approximate central face ROI58.3x85.2
pixels in a1536x1024 whole-body sheet; normal-weighted front/back/profile blend;
the same projected material is used for head, eyes and hair. Larger final atlas
or more subdivision cannot recover missing detail or fix view registration.
Source hash and evidence are persisted. Stage39/40 technical PASS remains valid,
but the user has identified insufficient facial quality; do not claim art approval.

Recommended next implementation, when requested: one coherent head/UV/skin pilot,
separate eye/hair materials, neutral/changed-light and native tactical review.
MPFB core/Skins02/eye materials01 is the free feasibility route; licensed HumGen
or Character Creator5 are alternatives. None was installed or tested locally by
this research. Preserve Knight-inspired costume direction and the3D-to-sprite
Godot workflow. Do not start another smoothing or full-roster batch.

Research/diagnostic only: no model changes, visible launch, desktop input,
paid calls, install, commit or push.61 physical cases remain NOT_RUN. Preserve
all previous sources and dirty work. A single approved method/template precedes
outfit, rigging/motion, export/integration and cast expansion.

## Previous task: softer painted candidates delivered

User2026-11-02: stage39 looks much better; make the models less angular. Owner
[presentation013](specs/presentation/013_character_surface_refinement.md),
[slice013](specs/presentation/slices/013_character_surface_refinement.md),
[milestone008](specs/presentation/milestones/008_character_surface_refinement.md).
Read [surface-refinement guide](design/character-art/SURFACE_REFINEMENT.md) and
[stage40 proof](qa/stages/2026-11-02-stage-40.md).

New isolated sources: `assets_src/characters/surface_refinement/2026-11-02/`.
Open `comparison.png` (all3 before/after pairs), `details.png` (warden bust at
original resolution), `all_views.png`. Editable Aseprite, .blend/FBX/2048px atlas,
source parts and Ucupaint layers included. Curved profiles, local subdivision,
rounded leather/cloth edges and softer cape-light treatment refine the same
identities. Stage39's101-file source package and original tools are unchanged.

Technical PASS:8838 assertions,3 actual FBX reimports/renders, source/Ucupaint,
atlas/UV/bounds, all retained roster/world/old-study/stage39 hashes. Bounding
extremes change at most4.542mm; this is not a full per-vertex metric. Source meshes
are92186/105742/92826 triangles for offline sprite exploration, not optimized
runtime3D. Delivery audits PASS with close disconnected-fragment warnings retained.
Project validator PASS. All boards, colour/geometry and imported views inspected.

Follow-up: user reports insufficient facial quality; see current research above.
No rig, actions, equipment swapping, Godot integration, visible launch or desktop
input in stage40.61 physical cases remain NOT_RUN. Some projection/paint/hair/cloth
limits remain documented. Do not automatically replace the roster or start a
rigging batch. No new paid/generation calls or installation. Preserve all earlier
dirty work; stage40 is local/uncommitted, no push requested.

## Previous task: Knight-painted proposals delivered

User2026-11-02 selected Knight's painted technique and authorized stronger tools
and several new actual-model proposals. Owner [presentation012](specs/presentation/012_painted_character_candidates.md),
[slice012](specs/presentation/slices/012_painted_character_candidates.md),
[milestone007](specs/presentation/milestones/007_painted_character_candidates.md).
Read [production guide](design/character-art/PAINTED_CANDIDATES.md) and
[stage39 proof](qa/stages/2026-11-02-stage-39.md).

Installed/tested15 Scenario Blender Expert skills, pinned7f4b801c, and Ucupaint3.0.0
no-auto-update in the owned art profile. Dependencies/smoke evidence:
`tools/assets/painted_character_dependencies.json`. Future agents can use these
installed skills; the existing background Blender MCP is unchanged.

Three actual static sources,25/30/25 authoring parts, .blend/FBX/2048px albedo,
working Ucupaint layers and multi-view/geometry-only reviews live under
`assets_src/characters/painted_candidates/2026-11-02/`.
Open `comparison.png`, `before_after.png`, `all_views.png` (editable Aseprite
sources included). I leather mercenary, II steel warden, III long-coat wayfarer.
`concept.png` files are separately labelled original AI design references.
The old `-Scene styles` preview still displays previous A/B/C; new proposals
are source-art boards, not a runtime replacement.

Technical PASS:8705 assertions,3 actual fresh FBX imports/renders, working paint
layers, source hashes,8223 roster +215 world +27 old-study files unchanged,
project validator and roster check PASS. Audits PASS with non-fatal close
disconnected-fragment warnings retained. Static anatomy/clothing/material
comparison is delivered; no rig/actions/grips/equipment swapping claimed.

Next unfinished task is user review of I/II/III or combined qualities. Do not
automatically rig/integrate or replace the27-family roster. A selected pilot
needs a separately scoped topology/paint/motion/native pass. Some projected
side/cuff/overlap seams and plain collar/cape treatment remain documented.
No OS input or visible app launch occurred;61 physical game cases remain NOT_RUN.
No desktop controls were released by this modelling request. Preserve earlier
preview/research dirty work. All stage39 changes are local/uncommitted; no push
was requested for this increment.

## Previous task: A selected; refinement reference research

Latest user choice2026-11-02: A / Painterly veteran is the direction, but its
clay-like finish needs refinement. User asks to review advanced skills/MCP/tools
and examples FIRST. Read [A refinement research](design/character-art/A_REFINEMENT_RESEARCH.md).
Research inspected Scenario Labs' Blender Expert family, Ucupaint, Malt, drawn2D
alternatives and artist-authored painted knight examples. No model edits,
installations or paid calls in this research step. Next is user reference review,
not automatic modelling/rigging/integration or a roster rollout.

Prior follow-up added local `start_game.ps1 -Scene styles` and battle Tools ->
Style A/B/C.42 headless preview assertions, combat slices and validator PASS.
Visible DISPLAY1/windowed preview showed all three bodies. User stopped desktop
control with Escape before full physical controls acceptance; do not resume UI
input from this research request. See [preview evidence](qa/2026-11-02-style-preview-followup.md).
Preserve this uncommitted work. Existing61 normal-play cases remain NOT_RUN.
Study sources were pushed as `de83f87b`; later local preview/research is uncommitted.

## Previous task: static style studies delivered

User2026-11-02 asked to push everything, research art skills/sources, then build
several actual character models to choose a future style. Rollback checkpoint
`619237db` was pushed to `origin/feature/dungeon-eod-checkpoint-2026-07-17`, including
7850 LFS objects/679MB. Preserve the stage37 production state described below.

Owner [presentation011](specs/presentation/011_character_style_studies.md),
[slice011](specs/presentation/slices/011_character_style_studies.md),
[milestone006](specs/presentation/milestones/006_character_style_studies.md).
Three isolated actual 3D studies live under
`assets_src/characters/style_studies/2026-11-02/`: A painterly veteran, B graphic
ink warden, C heroic miniature. Open `comparison.png` or `all_views.png`; editable
Aseprite sources, .blend/FBX/albedo and18 renders are included. Research/source
licenses: [STYLE_RESEARCH](design/character-art/STYLE_RESEARCH.md).

Technical scope: static, not rigged/animated/integrated. Actual fresh-scene FBX
reimports and baseline hash checks PASS; report [stage38](qa/stages/2026-11-02-stage-38.md).
The subsequent user choice is A, with refinement references pending as above.
Do not automatically replace the roster or begin a rigging/animation batch.
No OS input or visible launch used.61 physical cases remain NOT_RUN; use stage37
release for later gameplay tests after explicit control release. No paid service.

## Production status: stage33 characters restored; new environment retained

Latest user instruction2026-11-02: REJECT the recent model/grip/pose/helmet
refinements. Restore OUR complete original stage33 roster, after the general
27-family replacement but before the later weapon refinements. Do not restore
vendor art, regenerate characters or re-enable the modular GLB atlas.
Native/headless battle/gallery now use the exact original animated PNGs; the3D
inventory actor preview is removed. Prior weapon-selected sprite families return.
Keep new terrain/props/contact shadows, illustrated pixel portraits, icons/items,
five-slot save compatibility and the unrelated post-turn input fix. Modular
armour/boots/helmet appearance is deferred, not delivered by the restored sprites.

Source rollback PASS:56/56 project checks,27 models/6912 frames/8223 hashed files;
native261 checks/20 engine-local clicks/41 captures, including all8 distinct walk
frames during real resolver-driven movement. Environment source hashes unchanged.
Final release/export/native proof PASS:
`artifacts/export-smoke/stage37-model-rollback-release-20261102/sdd-game.exe`
with adjacent PCK/windowed App profile/notices. PCK211334940 bytes, SHA-256
`68003d8509e53dd6cc830d95f4f25f7f3c8b276f1d29f328b9230de4762cbfec`.
Final EXE318 native checks/49 engine-local clicks/43 captures PASS, zero diagnostics;
7 distinct walk frames observed during packaged movement (8 in source). Read
[stage37 report](qa/stages/2026-11-02-stage-37.md). Prior stage36 packages contain
the rejected models; do not use them for current review.
No OS input/player save/visible launch was used. Rollback is finished. Next work:
user review/physical tests after explicit desktop release, larger left DISPLAY1/
windowed/protected saves. Source preview: `tools/qa/start_game.ps1 -Scene combat`.
No new features or renewed model refinements without a new user instruction.

## Historical stages34..36 (character changes rejected by user)

User2026-11-02 requested improved grips/bow visibility, dynamic spearman poses,
fully enclosed brute helmet, separate generated pixel portraits, visible equipped
armour/boots/helmet/weapons, and a coherent environment/floor replacement.
Owner [presentation010](specs/presentation/010_equipment_art_world.md),
[slice010](specs/presentation/slices/010_equipment_art_world.md) and
[ordered stages34..36](specs/presentation/milestones/005_equipment_art_world.md).
Stage34 automated/native PASS (54/54 checks,27 models, native226 checks/43 captures).
Stage35 automated/native PASS (55/55 checks, five-slot migration/live preview,
native184 checks/87 clicks/6 captures at1080p/1440p/4K). Reports:
`docs/qa/stages/2026-11-02-stage-34.md` and `2026-11-02-stage-35.md`.
Stage36 automated/native PASS:28 Blender/FBX props,4 seamless painted floors,
textured ledges and contact shadows;255 prop/69 floor routes preserve map/domain.
Final regression56/56 and50 Python tests PASS; strict7849 files,0 diagnostics.
Actual FBX reimports27 actors/28 props and2160 native GPU pose-bounds cases PASS.
Final EXE3181 native checks/168 engine-local clicks/147 captures at1080p/1440p/4K
PASS,0 engine diagnostics. Read [stage36 report](qa/stages/2026-11-02-stage-36.md)
and [production guide](design/character-art/EQUIPMENT_WORLD.md), including the
fixed post-turn pointer/pose-reset race and legacy local-weapon compatibility.

Use `artifacts/export-smoke/stage36-final-release-20261102/sdd-game.exe` with its
adjacent PCK, owned windowed App profile and notices. PCK211336044 bytes, SHA-256
`8457ce277fb27b264b70d9bb6df83c5e4c16a94326ba87b2ebb4a87fd2585c3b`.
Older stage30/33/36 candidate packages are superseded for this batch.
Source preview: `tools/qa/start_game.ps1 -Scene combat` (or `-Scene app` for gear).

All stages remain AWAITING_INTERACTIVE. Next unfinished work is explicit desktop
release, protected saves, larger left DISPLAY1/windowed and all61 NOT_RUN cases
in `docs/qa/live-test-scenarios.md`: physical input, normal-speed animation/grips,
gear/environment readability, ordinary campaign victory/defeat/settlement/restart
and closed-log audit. Native engine-local fixtures do not constitute hands-on play
or user visual approval. No visible launch/OS input until release. No paid services.
Do not automatically begin another feature batch; continue only requested scope.
Preserve all dirty work; no commit/push requested for this batch.

## Previous baseline: all27 original models implemented; physical acceptance pending

User2026-11-02 authorized replacement of ALL configured characters, retaining
old design identities and improving tactical exposure. Presentation009/slice009
and milestone004 own stages31..33. All three stages have automated/native PASS;
physical status remains AWAITING_INTERACTIVE. Read
[the final report](qa/stages/2026-11-02-stage-33.md) and
[the production guide](design/character-art/ROSTER.md).

Complete delivery:27 Blender/FBX/baked-texture models,6912 action PNGs,27 matching
portraits and1107 editable Aseprite files. Eight real views/five clips per family;
all old IDs/three aliases route to originals. Lower camera/front-biased diagonals,
stable ground pivots and fitted long-weapon tracks improve exposure. Tools ->
Character gallery shows every family/action; legacy artwork remains as references.

Final proof:53/53 project checks,48 Python tests, strict7743 files and27 actual
FBX reimports PASS. Persistent8223-file source manifest, sprite bounds, saved
clip timings and hashed FBX proof validate without ignored artifacts after clone.
The final packaged play fixture passed699 checks/81 engine-local clicks/162
captures at1080p/1440p/4K; campaign portraits/equipment fixture40 checks/20 clicks/
3 captures PASS. Zero engine diagnostics. All hosts were minimized/unfocused,
without desktop input or player saves. Normal physical play is not established.

Use only the final review build:
`artifacts/export-smoke/stage33-roster-release-fixed-20261102/sdd-game.exe`
with its adjacent PCK, owned App/windowed profile and notices. Earlier stage33
builds are superseded after the long-weapon floor-clearance correction. The final
report records exact hashes and all failure/retest evidence.

Source preview from this repository:
`tools/qa/start_game.ps1 -Scene combat`, then Tools -> Character gallery.
Do not launch a visible GUI while the user uses the computer. Next unfinished
work: explicit desktop control release, larger left DISPLAY1/windowed, protected
saves, all55 NOT_RUN cases in `docs/qa/live-test-scenarios.md`, normal-speed gait/
grip/readability, ordinary victory/defeat, return/restart and closed-log audit.
The user has not yet approved the final roster's look/feel in physical play.

Preserve all existing dirty launcher/tooling/art/gameplay work. No commit/push
requested for this baseline batch. The environment/prop batch is now explicitly
authorized by the newer task above.

## Previous task: visual production tools prepared

User reprioritized2026-11-02: prepare visual tools, skills, libraries and MCP before
the physical test session, including our own enemies/models/animations. Tooling005/
slice005 and tooling milestone001 own this preparation. Read
[the production guide](design/character-art/TOOLING.md) and
[setup proof](qa/2026-11-02-character-art-tooling.md) before character work.

Installed/tested Blender5.2.3 LTS, Rigify, Retarget5.2.0, background Blender MCP
(9 tools; actual edit/save/query), two free CC0 Quaternius Standard libraries
(43 actions each), godot-animation and meshy-3d-generation skills. Meshy MCP0.6.7
(28-tool discovery) and CLI0.7.3 installed without account/paid calls. PixelLab and
Tripo researched; no cloud key/credit authorization. Existing integrations preserved.

Recommended next production step: one original raider pilot -> fitted rig/motion
-> eight-direction renders -> Aseprite export -> opt-in actual Godot preview.
This pilot/roster integration has NOT been implemented by the tooling task.
Use the current eight-direction renderer; no full3D engine migration. Follow the
guide's art acceptance checklist and specs before implementation. No GUI/input
release;46 previous live cases stay NOT_RUN. Stage29 game/export unchanged.
Preserve the uncommitted preview launcher fix and these tooling/docs changes;
no new commit/push was requested.

## Previous task: stages27..29 implemented; physical acceptance still pending

User resumed2026-11-02 and requested completing outstanding work and the earlier
repository push. Stage26 campaign appearance was approved. Presentation007/slice007
and milestone002 own the completed dungeon/battle extension. Read
[stage29 report](qa/stages/2026-11-02-stage-29.md):51/51 source checks, strict2094 files,
final release and packaged native play/campaign104 clicks/51 captures all PASS.
Runtime catalogue1889 PNGs;91-file editable/source/export art manifest.

Follow-up: user could not see the supplied preview launch. The local interactive
launcher now uses Normal window state and reports early exits (it had used Hidden).
AST/configure-only/direct headless combat startup PASS; physical visibility still
unverified. Read [preview-launch fix](qa/2026-11-02-preview-launch-fix.md). These local
launcher/docs changes follow the pushed1636318 checkpoint; game/PCK are unchanged.

Latest build: artifacts/export-smoke/stage29-release-20261102/sdd-game.exe plus
adjacent PCK/owned windowed App profile/notices. Native previews and commands:
[play UI notes](design/play-ui/README.md). Includes named-room parchment dungeon,
scrolling preparation/events and board-preserving battle portrait/resources/action
inspector/chronicle/costed actions/Tools; fixed actors vanishing after scenario reload.

Next unfinished work is46 NOT_RUN [live cases](qa/live-test-scenarios.md). Wait for
explicit physical mouse/keyboard/focus release, then windowed larger left DISPLAY1,
protected saves, physical input/resize, ordinary battles, normal return/settlement/
restart and closed-log audit. Native fixtures do not count as ordinary play.
The user's newer visual-tool preparation priority above supersedes the former
instruction to do physical acceptance first. The user authorized
commit/push after checks; exact checkpoint is in Git/tracking and final handoff audit.

## Prior task: dark fantasy UI stages23..26 implemented; live acceptance pending

The latest user request on2026-11-02 authorizes the complete research proposal:
install the two UI skills, add useful libraries, create/choose inventory concepts,
ship a coherent art family, implement inventory and parchment map, extend the
style to campaign screens, verify and export. Read
[the ordered UI milestone](specs/presentation/milestones/001_dark_fantasy_ui.md),
presentation006 and slice006 before continuing. The dark fantasy inventory and
parchment map are the user's selected visual references. Background work and
deferred physical desktop tests still apply; no mouse/keyboard/focus release.

Implementation: game-ui-ux/godot-ui-control installed and read, Godot MCP75 tools
configured/tested, Kenney/Shikashi/ThemeGen/fonts integrated. Three concepts saved;
A selected. Coherent Aseprite art, inventory, parchment map, town/trade/training
and native GPU review are implemented. Read [stage26 report](qa/stages/2026-11-02-stage-26.md)
for final evidence and build hashes. Latest build:
`artifacts/export-smoke/stage26-release-final-20261102/sdd-game.exe` with adjacent
PCK and owned windowed App profile. Starts in the campaign map on DISPLAY1.

Next unfinished work is physical acceptance:38 NOT_RUN cases in
[live registry](qa/live-test-scenarios.md). Preserve existing dirty work and saves.
Wait for control release, then actual pointer/keyboard/hover/focus, resize, ordinary
equipped victory/return/trade/train/restart and closed-log audit. Do not start
another UI rewrite or claim user visual approval from native fixture PASS.
Future campaign UI changes follow [the recorded tool/art workflow](design/campaign-ui/TOOLING.md).

## Research baseline: current appearance rejected

On2026-11-02 the user rejected the current UI appearance and requested thorough
internet research into references, assets, generators, skills and MCP. Read
[the UI research and proposed sequence](qa/2026-11-02-ui-design-research.md).
That research preceded the implementation authorization above. Its proposed
concept/material/tool sequence has now been executed. Earlier technical proofs
remain historical; physical acceptance is still pending. No GUI control was
released, and the desktop/save policy remains in force.

## Technical baseline: UI polish stages20..22 implemented; actual acceptance pending

User authorized the full UI polish plan on2026-11-02. Owners shared
presentation003/004/005 and slices003/004/005. In order: stage20 visual inventory/
portrait-slot editor and compact shell46/46;21 visual trading/training47/47;
22 town/service tiles/interactive landmarks/final review48/48. All automated PASS,
all actual acceptance AWAITING_INTERACTIVE. Existing campaign v4/domain rules
unchanged. The latest [stage22 report](qa/stages/2026-11-02-stage-22.md) records
acceptance, review defects/fixes, exact commands and build identity.

Use `artifacts/export-smoke/stage22-release-fixed-20261102/sdd-game.exe` plus
adjacent PCK/owned window profile. Source
`artifacts/qa-runs/stage22-fixed-headless-20261102/report.json`:48/48,46 Python
tests,2223 UI assertions,0 diagnostics; strict checker2032 files and fresh corrected
EXE probe PASS. Earlier stage22-release is superseded (collapsed tile labels).
Final proof includes actual tile purchases/equipping/retained Torin selection and
map-marker travel to pending Cart, in-memory only. Start EXE, F7 / World-Ravenford.

Next unfinished task: [live registry](qa/live-test-scenarios.md),30 NOT_RUN cases
across stages8..22. No GUI activation/input while user uses PC. When they release
controls, use windowed larger left DISPLAY1 and safe saves, native UI/pointer/
focus/motion review plus ordinary battle/trade/train/return/restart/log audit.
Do not count offline reconstructed previews or headless geometry as native visual
acceptance. Fix/retest/re-export observed defects. No commit/push without request.
Further game content is outside this completed UI batch.

Current UX: inventory category tabs/icon grid, portrait hero picker, named slots,
authored metadata comparisons and persistent local hero/item/filter; trading uses
visual stock/free-loot grids; training shows tier/delta/XP bars. Compact counters,
region-only party rail, warm heading typography/existing ornament frame, city
supply tiles and guarded landmark travel. No legacy form dropdowns were kept.

## Prior technical baseline: stages18 progression/19 campaign interfaces

User authorized further code/automation and specifically reprioritized polished
campaign interfaces. Implemented18 party advancement and19 shared UI (the earlier
second-location proposal is still future scope). Owner world007/slice007/combat103,
shared presentation002/slice002. [Stage19 report](qa/stages/2026-11-01-stage-19.md)
records final build and all acceptance. Source
`artifacts/qa-runs/stage19-verified-20261101/report.json`:45/45 PASS,45 Python
tests/1219 UI checks/33 progression checks,0 diagnostics. Strict checker2022 files
and final extended EXE probe PASS. Historical stage19 build:
`artifacts/export-smoke/stage19-release-final-20261101/sdd-game.exe` plus adjacent
PCK and owned local windowed DISPLAY1 profile. Earlier stage19-release is superseded.

New shell gives Region/Town/Stash/Trading/Training navigation, fixed resource/
location header and feedback footer, responsive cards, party rail and bounded
inventory scrolling. Campaign save v4 migrates valid v1..v3 in memory without
rewriting on load; advancement levels allocate shared earned XP, never heal or
change max HP. Managed dungeon/road snapshots freeze both gear and training;
sandbox stays isolated. Train at Ravenford, after resolving active events/runs.

At stage19 handoff the registry held24 NOT_RUN cases; it now has30 for stages8..22. No GUI/input while user uses PC. When released, use windowed
larger left DISPLAY1, safe saves, ordinary battles/trades/training/return/restart
and closed-log audit. Stage18/19 remain AWAITING_INTERACTIVE. Offline preview PNGs
are labelled reconstructions of geometry/art, not native screenshots or acceptance.
Fix/retest/re-export defects before recording live PASS. Further location/quest
content needs new scope; do not restart completed implementation.

## Prior technical baseline: stage17

User's "DAWAJ DALEJ" authorized the next background increment after stage16:
Ravenford Trading Post, world006/slice006. Buying equipment and selling only free
Valuable/Equipment copies now work through CampaignSession's atomic transactions.
No sale of quest/legacy/assigned items; purchases never auto-equip. Save remains
v3. [Stage17 report](qa/stages/2026-11-01-stage-17.md) records acceptance and build.
Source `artifacts/qa-runs/stage17-headless-20261101/report.json` passes43/43,
39 Python tests/48 trade assertions,0 diagnostics. Strict checker2003 files and
fresh extended release EXE probe PASS. Historical stage17 build:
`artifacts/export-smoke/stage17-release-20261101/sdd-game.exe` with adjacent PCK
and owned local windowed DISPLAY1 profile. Use the newer stage19 build above for current acceptance.

At stage17 handoff the live registry held20 NOT_RUN cases across stages8..17;
it now has30 and uses the stage22 corrected build above. Wait for mouse/keyboard/focus release; no GUI while
they use the PC. Play on larger left DISPLAY1, windowed; protect player save,
test ordinary combat/return/trade/equip/restart and audit the closed log. No stage
is finally accepted by headless checks. Fix/retest/re-export observed defects.
This section is historical; progression and interfaces above are implemented.

## Prior technical baseline: stages13..16

The authorized package is implemented in order with per-stage automated PASS:
13 travel39/39,14 persisted events/road combat40/40,15 stash41/41,16 equipment42/42.
Specs world002..005/slices002..005, combat slice102 and
[campaign expansion milestone](specs/world/milestones/001_campaign_expansion.md)
own the changes. Final checker1997 files and extended release EXE probe pass,
zero diagnostics. [Stage16 report](qa/stages/2026-11-01-stage-16.md) records all
acceptance, hashes, commands and limits. Source run:
`artifacts/qa-runs/stage16-headless-20261101/report.json`; final build:
`artifacts/export-smoke/stage16-release-20261101/sdd-game.exe` plus adjacent PCK.

At stage16 handoff actual computer-control acceptance covered stages8..16:
18 cases, all NOT_RUN; the registry now includes stage17 and20 cases. Do not activate
windows/inject input while user uses PC; wait until they release controls. Test
windowed on larger left DISPLAY1, preserve player save, normal victories/returns,
restart and closed-log audit. Technical PASS is not final acceptance; every new
stage remains AWAITING_INTERACTIVE. Do not restart completed implementation.
Fix any live defect, rerun affected automated
checks and export before retesting.

Campaign save is now v3 at the same user://campaign_v1.json path. Valid v1/v2
migrate without load-time rewrite; new starters are added only if missing.
F7 opens campaign from direct sandbox. Travel to Old Mine before managed packing,
keep return food; pending road events block travel/services/gear. Open Stash
contains the equipment UI; gear locks/snapshots during expeditions and ambushes.
Combat resumes at encounter entry/seed, never mid-turn. Existing source direct
dungeon remains free sandbox. Stages8..12 below are historical technical evidence.

## Prior technical baseline: stages8..12

Stages8..12 implementation/technical review is complete. Final source run
`artifacts/qa-runs/stage12-final-headless-20261101/report.json` passes38/38,
strict scene checker1973 files and final release/probe PASS, zero errors/warnings.
Build: `artifacts/export-smoke/stage12-release-20261101/`. The exported EXE also
loads Clearing crossfire through its data catalogue and performs ordinary
confirmed movement with correct MP/input unlock. Read the
[stage12 readiness/build report](qa/stages/2026-11-01-stage-12.md).

The user explicitly changed the order on2026-11-01: continue stages9..12 with
automated tests, collect actual gameplay scenarios and perform them in one later
session. Do not activate Godot/game windows or inject desktop input until the
user releases controls. All stages8..12 remain AWAITING_INTERACTIVE. Next action
was their accumulated live session before the later13..16 authorization above.
[Live-test registry](qa/live-test-scenarios.md) now lists30 NOT_RUN scenarios and
the newer stage22 build/setup; the original stage12 subset had11. No deferred
scenario counts as PASS.

## Accepted baseline

Stages0..7 of the Fallout FPP comparison/adaptation task are complete. Read the
[stage index](qa/README.md) and [final acceptance](qa/stages/2026-11-01-stage-7.md)
for every acceptance scenario, observed gameplay, defects and build identity.

Delivered: repeatable QA and DISPLAY1 placement; combat injury return; imported
asset catalogue; reusable passive HUD; TMX/map-v2 and playable workbench;
generation quality gates; durable campaign, Ravenford market/inn, checkpoint and
single-application expedition settlement. These are foundations, not a claim
that every historical combat roadmap item or the whole game is complete.

Final source run: `artifacts/qa-runs/stage7-fixed-20261101/report.json`,34/34 PASS,
zero errors/warnings. Export: `artifacts/export-smoke/stage7-release-fixed-20261101/`,
with EXE/PCK, reports, `interactive-acceptance.json`, closed runtime log and
archived campaign. Normal three-enemy victory,6/6 expedition and restart passed.
The campaign created during QA ended at75g/16XP/nine items, Bran7/14,Torin10/10.
This is historical evidence; inspect current state before further play.

Raw artifacts, `.venv` and local `override.cfg` are ignored by Git. Written stage
reports/specs are source files. A different checkout must regenerate artifacts.
Changes are local and uncommitted on `feature/dungeon-eod-checkpoint-2026-07-17`,
based on `f4f4546d7305ce98bde58a5dba91ef703be71ce7`. Verify current Git status;
do not reset, clean, commit or push this work without the appropriate user request.

Earlier documentation-only handoff verification (before stage8): `.venv/Scripts/python.exe tools/validators/validate_all.py`
PASS, `git diff --check` PASS,19 local Markdown link targets and both workspace/repo
entry points checked. No gameplay changed or new runtime acceptance claimed in
this documentation update.

## Current queue and acceptance

The existing [Ordered Combat Queue](specs/combat/milestones/001_combat_core_debug_loop.md#ordered-combat-queue),
items15..19, maps to the historical stages8..12 below. All are implemented and
technically reviewed with automated PASS; actual-play acceptance stays pending.
Authorized world/presentation stages13..22 are also implemented; the next task is live testing.

| Next stage | Existing queue item | Scope and acceptance focus |
| --- | --- | --- |
| 8 | 15: Combat Board Frame And Panel Skin V1 | Consistent battle frame/panels/feed/tooltips; readable layout and asset fallback. Review actual movement/target overlays and panel bounds. |
| 9 | 16: Combat Unit And Resource Icon Pass V1 | Audit already implemented sprites/icons/meters, complete remaining readability/state/fallback gaps. Test active, hovered, wounded, dead and status-bearing units. |
| 10 | 17: Combat Feedback Polish V2 | Consistent action/target/chance/damage/cost/rejection/result feedback, driven by resolver events. Play normal victory and defeat/return cases. |
| 11 | 18: Combat Encounter Authoring V1 | Add a new encounter from map/archetypes without controller edits; validate starts/assets/loadouts and test editor -> save/reload -> actual combat. Stage4 tooling is already available. |
| 12 | 19: Combat Readiness Review For Dungeon | Reconcile all roadmap requirements with existing proofs, explicitly list any deferrals, then full regression, fresh export and actual dungeon/combat/return acceptance. Stage7 is a baseline, not automatic proof of future changes. |

Stage8 owns presentation089/slice097, stage9 presentation090/slice098, stage10
presentation091/slice099, stage11 overview092/slice100 and stage12 overview093/
slice101. Accepted actual-play evidence still ends at stage7/slice096. New future
slices must use the next unused number (currently104); check before allocating.
Do not duplicate working stage3 HUD helpers
or mark partially implemented historical items complete without a requirements
audit and the missing proofs. Pixel-art creation must follow `agents/README.md`
and the Aseprite pipeline; reuse processed assets where suitable.

World travel/events/stash/equipment/trade/progression are now in world002..007,
shared presentation002 owns campaign UI. Further candidates after live acceptance
are additional town services/more
locations and encounters; these need user scope, owning specs and slices first.
[world001](specs/world/001_campaign_boundary.md) retains the accepted historical
hub/town/campaign boundary and links these extensions.

## Required stage loop

1. Read AGENTS.md, this handoff, the active milestone and owning specs. Inspect
   Git status and affected source/data. Do not replay completed stages by default.
2. Write/update the owning spec, schema/reference data as needed, chronological
   slice and meaningful automated acceptance checks before implementation.
3. Implement one complete playable increment. Combat legality/outcomes stay in
   `scripts/domain/combat_resolver.gd` and its Python mirror; UI sends commands.
4. Run targeted checks, then the required project verifier. Inspect exit codes
   and diagnostics. For a release gate, make a fresh export after the last fix.
5. Actually operate the visible game window on larger left DISPLAY1. Cover the
   stage scenarios, affected screens and return flow. Normal combat victory is
   required when that is the acceptance scenario; Debug Win/state injection do
   not count. Use isolated test saves; preserve current player progress.
6. Audit the closed session log, fix defects, and repeat relevant automated and
   actual tests on the final code/build. If UI access is unavailable, document
   the missing proof and leave acceptance open. Current batch exception permits
   the next implementation stage after automated PASS, with live tests deferred.
7. Persist the acceptance matrix, exact commands/build, results and remaining
   limits under `docs/qa/stages/`; update the index, milestone and this handoff.
   Record automated progress separately from final acceptance. After stages9..22
   automation, wait for the accumulated live session. No automatic commit/push.

## Commands and entry points

Run from `C:\Users\karol\Desktop\Gierka\game_dir\sdd-game` using Godot4.7 stable
and the existing Python3.12 `.venv`. Do not change engine version as a side effect.

```powershell
.\.venv\Scripts\python.exe tools\qa\verify_project.py
.\tools\qa\start_game.ps1 -ConfigureOnly
.\.venv\Scripts\python.exe tools\qa\export_smoke.py --release
```

The verifier includes data validation, discovered Godot test suites and five scene
smokes. The default source entry is DungeonDebug sandbox. F7 opens campaign;
managed runs use owned supplies and durable settlement. F6 opens the workbench
from sandbox; F5 plays its isolated draft, F6 returns. Combat saves resume from
encounter entry/seed, not the middle of a tactical turn.

On this workstation mixed DPI/elevated shell input caused problems. The verified
workflow is ConfigureOnly, then Run from ordinary Godot Project Manager, or the
exported EXE with the owned local profile beside it. Confirm the actual window
and input before acceptance. See [launcher contract](specs/tooling/001_stage_verification.md)
and README commands. The old pre-fix `stage7-release-20261101` is superseded by
`stage7-release-fixed-20261101`.

Fallout source reference: `C:\Users\karol\Documents\vibe-modding\fallout2-fpp-vibe-mod`.
It had unrelated user changes and was left untouched. Adapted ideas were tooling,
catalogues, checkpoints and candidate quality gates; no renderer/assets import.
