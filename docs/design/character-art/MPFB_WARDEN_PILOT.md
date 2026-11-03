# MPFB warden: static visual proposal

Owner [presentation015](../../specs/presentation/015_mpfb_warden_pilot.md),
[slice015](../../specs/presentation/slices/015_mpfb_warden_pilot.md),
[milestone010](../../specs/presentation/milestones/010_mpfb_warden_pilot.md).
User chose MakeHuman/MPFB on2026-11-02 and requested a model preview before
agreeing to animation and new enemies. The quality target is readable tactical
2.5D, not cinematic portrait detail.

## Review files

Source directory: `assets_src/characters/mpfb_warden/2026-11-02/`, excluded from
Godot by the existing character-source `.gdignore`.

- `proposal.png`: actual full-body and bust renders plus retained/new100px/m
  ground compositions and a2x native-sprite enlargement.
- `comparison.png`: the previous projected face and coherent MPFB face, using
  the same source camera, pose, framing, exposure and light recipe.
- `all_views.png`: front, three-quarter, profile, rear and changed-light face.
- Editable `.aseprite` versions of all three boards.
- `mpfb_warden.blend`: actual static model and hidden editable MPFB human master.
- `mpfb_warden.fbx`, `textures/`: portable static geometry and separate local maps.
- `renders/face_uv_checker.png`, `face_albedo.png`, `fbx_face.png`, `fbx_body.png`:
  diagnostics and actual fresh-import evidence, not concepts.
- `reference.json`, `model.json`, `verification.json`, `mesh-audit.json`,
  `licenses/`: exact identities, parameters, provenance and test evidence.

No screenshot is presented as a game capture. The old `-Scene styles` preview
still contains the earlier A/B/C models and does not display this pilot.

## Design and construction

Retain the stage39/40 warden's authored steel/navy/leather costume and the approved
Knight-inspired paint direction. Reference readiness records the original front,
profile and rear concept; its face paint is no longer the skin source.

Actual MPFB2.0.18 creates a masculine adult base with moderate square-jaw/age/brow
targets. Its continuous native UV and a matching CC0 Skins02 texture supply the
face. Eyes use their own CC0 brown iris/sclera texture with the required cornea
mask alpha; short hair and brows have their own meshes, UVs and alpha materials.
Skin has restrained subsurface response and no old front/profile/back shader.

The static head is cropped below the collar, with the lower neck fitted inside
the garment. It is not yet a deformation-ready full-body assembly. The hidden
editable base supports later approved work. Existing armor/clothing is isolated
from the old head material and uses its retained baked costume atlas in simple
portable materials. Thus the costume still carries earlier painted lighting;
this pilot does not claim a complete physically based armor rebuild.

Source hair cards initially contained nearly coplanar skin/card surfaces. Small
normal offsets and a targeted component repair separate demonstrated overlapping
planes. The delivery-audit thresholds are unchanged. Record warnings and inspect
the hair silhouette; a future hairstyle upgrade is separate from skin coherence.

## Repeat without opening windows

Use the repo root. `setup_mpfb.py` pins archive hashes and installs official source
and three CC0 packs under `~/.codex/tools/character-art/mpfb-2.0.18/`. The addon is
registered as an isolated local extension; no global Blender preferences are saved.
Package origins and checksums: `tools/assets/mpfb_dependencies.json`. Upstream
code is GPL; core/output and selected assets have the recorded CC0 terms.

```powershell
& .venv/Scripts/python.exe tools/blender/setup_mpfb.py
$env:BLENDER_USER_CONFIG='C:/Users/karol/.codex/tools/character-art/mpfb-2.0.18/config'
$env:BLENDER_USER_EXTENSIONS='C:/Users/karol/.codex/tools/character-art/mpfb-2.0.18/extension-user'
$artBlender='C:/Users/karol/.codex/tools/character-art/blender-5.2.3-windows-x64/blender.exe'
& $artBlender --background --factory-startup --offline-mode --python-exit-code 1 --python tools/blender/smoke_mpfb.py
& $artBlender --background --factory-startup --offline-mode --python-exit-code 1 --python tools/blender/build_mpfb_warden.py
& $artBlender --background --factory-startup --offline-mode --python-exit-code 1 --python tools/blender/verify_mpfb_warden.py
```

Run Aseprite in hidden batch mode with `tools/aseprite/mpfb_warden.lua` and the
`root` script parameter pointing to the active repo, then run the project validator.
Do not run overlapping Blender jobs. Rebuild commands intentionally replace only
this owned pilot's outputs; retain a reviewed pilot backup before later revisions.

## Next gate

The user reviews this **static** design. No animation set, new-enemy batch or
production replacement is authorized until agreement. After agreement, first prove
the whole-body fit, rig, grips and a short idle/walk/attack pilot at normal speed
before generating all actions/directions. Preserve normal-game acceptance as a
separate step; all61 physical cases remain NOT_RUN.

See the [stage41 report](../../qa/stages/2026-11-02-stage-41.md) for measured final
results, visual observations, rejected experiments and remaining limitations.
