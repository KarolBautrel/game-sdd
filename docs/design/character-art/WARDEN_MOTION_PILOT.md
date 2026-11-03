# Approved warden: rig and three-motion source pilot

Owner [presentation018](../../specs/presentation/018_warden_motion_pilot.md),
slice018 / milestone013. User2026-11-03 authorized this after approving stage43.

The accepted stage43 costume/face/boot reduction remains the immutable rest
appearance. The isolated package is
`assets_src/characters/warden_motion_pilot/2026-11-03/`; it is excluded from Godot
by the existing characters `.gdignore`. No production art or runtime code changes.

## Open the preview

From the active repository:

```powershell
& .\tools\qa\start_warden_motion_preview.ps1
```

This user-run command opens `preview.html` in the default browser. No server,
internet account or installation is needed. Three clips loop simultaneously at
24fps. Four angle buttons, pause, frame step, per-clip timeline, half speed and2x
inspection are available.1x is the existing100px/metre tactical camera at18degrees.
The displayed grid and contact shadows are viewer aids derived from measured
foot positions; the character itself is the actual unchanged Blender render.

Open `warden_motion.blend` for editable source. `warden_bound.blend` is the clean
rest binding checkpoint. The actual animated FBX has three clips and six meshes:
the original five plus one original sword,110926 total offline triangles.

## Construction and range

29 fitted FK bones with explicit weights, at most2 per vertex. The old separate
costume source identifies semantic parts using nearest rest coordinates; none
of that source's old head replaces the selected MPFB face. All approved rest
coordinates, topology, UVs and material graphs remain exact.5 texture bytes match.
Rigid cuirass/pauldrons/cuffs/fists; rigid boot sole and shaft with a flexible ankle
band. Cloth bends at elbows/knees; coat follows legs and cape has restrained lag.

Analytic two-bone posing produces standard FK keys. Idle48frames/2s; walk32frames/
1.333s with0.64m forward root travel; sword40frames/1.667s with anticipation,
cut, follow-through and recovery. Cycles include a duplicate closure key which
is omitted from preview renders. The weapon's grip crosses the closed fist;
forearm pronation and a limited wrist bend orient it outside the body. A periodic
five-frame quaternion filter removes projection-induced forearm/wrist jerks.
Legs are never filtered: contact targets remain planted in world coordinates.

This is a limited-range pilot, not a full combat/creature rig. No finger/facial
controls, live IK UI, physics cloth or extreme-pose correctives. Deep squat stress
renders still expose coarse trouser folds/a small rear skirt opening. Those are
outside the delivered walk/attack range; inspect that range separately.

## Reproduce in order

Use Blender5.2.3 from the pinned user-local tooling, background/factory/offline,
one owned Blender process at a time. Do not attach to a user's interactive file.
Every Blender command uses `--python-exit-code 1`.

1. `tools/blender/build_warden_motion.py -- --phase bind`
2. `tools/blender/verify_warden_motion.py -- --phase bind`; inspect rig_review.
3. `tools/blender/build_warden_motion.py -- --phase animate`
4. `tools/blender/verify_warden_motion.py -- --phase motion`
5. `tools/blender/build_warden_motion.py -- --phase render --view all`
6. `tools/blender/build_warden_motion.py -- --phase detail`
7. Aseprite batch, `--script-param root=<absolute repo> --script tools/aseprite/warden_motion.lua`
8. `python tools/qa/build_warden_motion_preview.py`
9. Inspect the boards/detail renders; update the honest visual review. Run
   `python tools/qa/finalize_warden_motion.py` and project validator.

All native384px frames are retained. Aseprite stores integer millisecond frame
durations (42ms here); HTML and Blender/FBX are the exact24fps timing reference.
No native game or browser playback acceptance is inferred from stills/numbers.

## FBX round-trip detail

Blender's FBX importer guesses tail lengths and auto-connects some children,
including the pelvis to its root. Connected bones suppress their valid location
curves. The verifier imports with `anim_offset=0`, clears those guessed connect
flags without changing joint/rest matrices, then evaluates the actual curves.
This compatibility normalization is recorded in `motion_verification.json`.
The .blend files are the authoritative editable source. Do not quietly approve
an import with suppressed pelvis motion. FBX poses compare complete point clouds
in both directions because material sections may reorder vertices.

## Acceptance and continuation

Stage44: rig/rest/weight gate and opened placement/joint/deformation renders.
Stage45: every-frame sole contact, floor, grip, quaternion continuity, leg reach,
blade centre/edge paths, cycle closure; actual FBX, four-view PNGs and Aseprite.
Source preservation checks cover the stage43 delivery and8223 roster +215 world
entries. Full body/cloth collisions are also a visual review item; sampled blade
rays are not a claim of an exhaustive collision solver.

The isolated browser host was unavailable in this session. Browser controls,
layout and continuous normal-speed viewing await manual review; native game
acceptance also remains deferred. All61 physical cases stay NOT_RUN. After user
motion approval, separately plan hit/death/block/other weapons, eight directions,
then distinct-face/body/gear enemy families. Do not automatically resume stage42
or overwrite the accepted source/runtime roster.
