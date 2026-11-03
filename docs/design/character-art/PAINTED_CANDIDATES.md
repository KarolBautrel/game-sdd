# Painted character candidates

Follow-up2026-11-02: user requested less angular construction. See
[surface refinement](SURFACE_REFINEMENT.md) and stage40 for the separately saved
before/after variants. This original source package is preserved unchanged.

Authorized2026-11-02 after the A refinement research. The user selected Knight's
painted finish and asked for better model construction, useful skill/tool packs
and several new proposals. Owner presentation012, slice012, milestone007.

## Review files

Source root: `assets_src/characters/painted_candidates/2026-11-02/`.

- `comparison.png`: three actual model renders, faces/profiles and100px/m ground
  composites. These bottom composites are not gameplay screenshots.
- `before_after.png`: retained A and three new candidates at common200px/m
  close scale and100px/m tactical scale,18-degree elevation/yaw330. A retains its
  original weapon pose; new candidates use empty-handed standing poses.
- `all_views.png`: actual front, three-quarter, profile and rear views.
- Each board has an editable `.aseprite` source. Each candidate has `.blend`,
  static FBX,2048px albedo, separate authoring parts, Ucupaint image layer and
  geometry-only silhouette/matcap/wire inspection views.

| ID | Proposal | Distinction |
| --- | --- | --- |
|01_mercenary|I / Najemnik|Leather brigandine, quilted navy wool, asymmetric half cloak|
|02_warden|II / Straznik|Convex steel halfplate, overlapping shoulder lames, short cape/tabard|
|03_wayfarer|III / Wedrowiec|Long indigo coat, lighter reinforced leather, softer silhouette|

These are static source candidates for choosing the next pilot. None has a rig,
actions, weapon grips or runtime integration. Current27-family animations and
world assets remain the production baseline. No GUI/desktop input was used.
The existing `-Scene styles` preview still shows the previous A/B/C studies;
open these new PNG boards to review this increment.

## What changed in the production method

Installed the15-member [Scenario Labs Blender Expert family](https://github.com/scenario-labs/skills/tree/main/skills/dcc/blender)
with the official skill-installer, pinned to
`7f4b801c7248d51b093ec365aceb114bd06139e6`. Keep the family together because
specialists import common Expert helpers. They become automatically discoverable
in a fresh agent turn; this session read the installed files directly.

Installed [Ucupaint3.0.0](https://github.com/ucupumar/ucupaint/releases/tag/3.0.0),
no-auto-update variant, in the owned character-art profile. Registration,
emission paint setup, real image layer creation and save/reopen were tested on
Blender5.2.3. This does not enable it in the user's unrelated Blender profile or
save global preferences. Dependency URLs, licences, hashes and smoke evidence:
`tools/assets/painted_character_dependencies.json`.

Used the new sculpt helper for a small cheek-plane adjustment and continuous
SDF gloves; the hard-surface helper for fitted plate edges/buckle; painted-light
materials for solid surfaces; delivery audit and geometry review helpers.
`bx_uvbake` import was smoke-tested; the actual atlas uses Blender's bake operator.
No new MCP connection was needed: the existing background Blender MCP remains
configured, while these longer builds use the owned Blender CLI.

The anatomical scaffold is Blender Studio Human Base Meshes1.4.1, CC0, already
cached and credited in the prior style studies. Face/eyes/limb anatomy are derived
from this scaffold; they are not claimed as sculpted from scratch. New authored
garments/boots/gloves/armour/cloth/belt geometry replace the previous studies'
rounded hair tubes and bulky mantle treatment. Actual neutral geometry renders
are retained alongside painted renders so texture does not stand in for topology.

## Paint sources and limitations

[Knight by Tommy Gunardi Teguh](https://tommygt.artstation.com/projects/EEv98)
is a diffuse-painted technique reference. The author's page credits the concept
to Kyoung Hwan Kim/Tahra. No Knight artwork or mesh was copied into these models.
The three new design plates were generated using the built-in image tool;
`concept-prompts.json` records exact prompts/provenance. `concept.png` is reference
art, never substituted for a model render.

Aseprite derives a connected-background matte,48px texture bleed and per-row
silhouette data. The model projects matching front/back paint and selected side
regions onto actual geometry, then bakes a portable atlas. Paint values include
designed lighting and some brush/detail information. This is AI-painted reference
projection and baking, not a claim of live GUI hand-painting or finished manual
retopology. Hidden `PAINT_WORKSPACE_*` meshes contain an actual Ucupaint image
layer for later editing; the portable FBX does not require the addon.

Capes use a dedicated cloth patch with a controlled navy tint instead of sampling
other garments from occluded turnaround regions. Their drape clears the body's
rear surface. Trousers use a lit wool material over the fitted geometry rather
than accidentally projecting upper coat paint onto the legs.

Projection stretches remain at some side panels/cuffs and overlapping equipment;
front/back designs are inferred where the generated references disagree. Some
seams/folds are painted detail rather than modelled depth. Flat source patches,
hairline/eye alignment and large garment deformation still need a selected-model
paint/topology pass before rigging. Static render/audit success does not prove
animation, crowd readability, equipment swapping or user art approval.

## Repeat without opening windows

From the active repo, use Aseprite hidden batch for
`tools/aseprite/prepare_painted_references.lua`, with `--script-param root=<repo>`.
Then run one Blender process at a time:

```powershell
$artBlender = "$env:USERPROFILE/.codex/tools/character-art/blender-5.2.3-windows-x64/blender.exe"
& $artBlender --background --factory-startup --python-exit-code 1 --python tools/blender/smoke_painted_tools.py
foreach ($artId in @('01_mercenary','02_warden','03_wayfarer')) {
  & $artBlender --background --factory-startup --python-exit-code 1 --python tools/blender/build_painted_candidates.py -- --id $artId
  if ($LASTEXITCODE -ne 0) { throw "Candidate failed: $artId" }
}
& $artBlender --background --factory-startup --python-exit-code 1 --python tools/blender/verify_painted_candidates.py
```

The verifier reopens actual source files with Ucupaint, imports each FBX into a
fresh scene, checks atlas/UV/bounds and renders the imported diffuse. It also
checks all retained roster/world and old-study source hashes. Afterwards assemble
the boards with `tools/aseprite/painted_candidates.lua` in hidden batch and run
`tools/validators/validate_all.py`. The persistent stage39 report records results.

User choice precedes a separately scoped rigged pilot. Existing61 physical game
cases remain NOT_RUN; computer controls were not released by this request.
