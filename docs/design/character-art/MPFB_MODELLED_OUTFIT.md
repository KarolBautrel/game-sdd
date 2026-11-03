# Warden: anatomical stance and modelled outfit

USER_REJECTED2026-11-02. Historical experiment only. The user explicitly requests
the stage41 look with a slight existing-boot reduction, governed by presentation017.
Do not use this outfit, its new stance or its rollout queue as the current template.

Owner [presentation016](../../specs/presentation/016_mpfb_warden_modelled_outfit.md),
[slice016](../../specs/presentation/slices/016_mpfb_warden_modelled_outfit.md),
[milestone011](../../specs/presentation/milestones/011_mpfb_modelled_outfit.md).
User2026-11-02 accepted the improved face/direction, requested straighter-looking
legs/smaller boots, actual armor/leather volume and distinct future faces.

Sources: `assets_src/characters/mpfb_warden_outfit/2026-11-02/`. Stage41 and all
earlier models remain exact retained comparisons. The approved head, eye, hair
and brow meshes/UVs/shaders are copied without changing their identity. Repointing
their unchanged texture files into this package is packaging, not a new face.

## Production method

Use the coherent MPFB anatomical master rather than the inherited costume legs.
A saved custom rest-shape key aligns knee/ankle lateral axes and lowers the arms
20 degrees with a blended shoulder region. Anatomical helper positions follow
the same deformation, preserving the data needed for later rig fitting. The
editable master stays in its source coordinate system; apply the recorded
`anatomy_source_to_costume_matrix` when aligning a generated rig with the visible
outfit. This is a static rest-shape preparation, not proof of a functioning rig.

New footwear has rounded toe/vamp/shaft forms, closed actual outsole volume,
separate folded cuffs, ankle straps/buckles and raised toe seams. Lower trouser
geometry is fitted inside the boot shafts/cuffs. Dimensions are measured against
the actual old source boots; see `measurements.json` and verification ratios.
Do not describe a main-boot width as the total width of every buckle/cuff.

The replacement outfit uses physical parts: curved breast/backplate, gorget,
domed shoulder crowns and articulated lames, lower fauld, bracers, leather wrist
seals/gloves, diagonal chest strap, waist belt, framed buckles/tongues, rivets,
sewn skirt panels and draped cloak. Leather strap points are ray-fitted to the
actual armor surface. The inherited painted strap/armor atlas is not used.

Cloth hidden under rigid crowns/gorget is masked as part of normal garment
construction. The visible neckline remains a separate padded collar. The cloak
top follows the actual curved back armor and has attachment studs; its hem and
folds are geometry. These are still unrigged garments; posed clearance needs
later proof before producing animations.

Authoring materials use navy/charcoal fabric, worn blue-gray steel, dark brown
leather and restrained brass. Color and roughness variation are independent of
the lamps. For portable output, bake albedo, roughness and metallic separately
into2048px maps; keep scalar maps Non-Color. Actual geometry carries the plate,
strap and buckle relief. The original skin UV and separate eye/hair/brow textures
remain intact. This is an offline sprite-source budget, not a runtime3D asset.

## Review and reproduction

- `proposal.png`: corrected full body, physical harness/buckles, native100px/m
  before/after ground composition and same-camera footwear comparison.
- `comparison.png`: full old/new bodies and footwear closeups. The rest stance
  deliberately differs; cameras, scale and light recipe are retained.
- `all_views.png`: all body angles plus geometry-only and changed-light evidence.
- All three editable Aseprite boards; actual `warden_outfit.blend`, FBX, textures,
  source parts, reference/provenance and verification reports.

Background commands from the active repo:

```powershell
$env:BLENDER_USER_CONFIG='C:/Users/karol/.codex/tools/character-art/mpfb-2.0.18/config'
$env:BLENDER_USER_EXTENSIONS='C:/Users/karol/.codex/tools/character-art/mpfb-2.0.18/extension-user'
$outfitBlender='C:/Users/karol/.codex/tools/character-art/blender-5.2.3-windows-x64/blender.exe'
& $outfitBlender --background --factory-startup --offline-mode --python-exit-code 1 --python tools/blender/build_warden_outfit.py
& $outfitBlender --background --factory-startup --offline-mode --python-exit-code 1 --python tools/blender/verify_warden_outfit.py
```

Then hidden Aseprite batch `tools/aseprite/warden_outfit.lua`, `root` script
parameter set to this repo, and `tools/validators/validate_all.py`. The builder
stops on source mesh-audit errors before baking. Run only one Blender job at a
time. Preserve a reviewed source delivery before modifying this owned package.

The old `-Scene styles` preview is unrelated to these source proposals. No runtime
assets, game routes, saves or scene controls change. Offline floor compositions
are not game screenshots.61 physical acceptance cases remain NOT_RUN.

Next: user review of this body/outfit correction, fitted rig and short motion
proof, then the [distinct-character plan](CHARACTER_VARIATION_PLAN.md). No full
animation/cast batch is automatically started. Detailed results and known limits
belong in [stage42](../../qa/stages/2026-11-02-stage-42.md).
