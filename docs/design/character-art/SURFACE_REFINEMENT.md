# Softer construction on the painted candidates

User2026-11-02: stage39 is much better; reduce angular appearance. Owner
presentation013 / slice013 / milestone008. This refines the same three static
identities. It does not reopen the concept choice or replace runtime characters.

## Review

`assets_src/characters/surface_refinement/2026-11-02/`:

- `comparison.png/.aseprite`: matched before/after body, face/collar and native
 100px/m floor composites for all3 candidates. Ground panels are not gameplay.
- `details.png/.aseprite`: warden bust before/after at original900px resolution.
- `all_views.png/.aseprite`: new front/three-quarter/profile/rear views.
- Each model folder: .blend, static FBX,2048px albedo, editable source parts,
 Ucupaint image layer, six painted views, imported-FBX render and geometry review.

Stage39 under `painted_candidates/2026-11-02/` is preserved byte-for-byte, including
its source tools. New builds preflight its101-file delivery and tool hashes.
The original3 generated multiview references are reused. No new generation,
paid service, installation, visible app launch or desktop input was used here.

## Changes

- Monotone curved loft profiles preserve original radius/centre control points
  while replacing straight profile slope changes in body, boots, cuffs and belt.
- More radial samples remove coarse circumference chords. Head/cloth/shoulder
  cages get one Catmull-Clark level before shell thickness; this changes geometry,
  not just normals. Gloves get a small local relax and hairline boundaries a
  bounded relax. Facial identity/landmarks remain the reference.
- Leather pouch corners have a6mm/four-segment bevel, small hard edges at least
  three segments. Steel retains convex forms and plate boundaries.
- A2.2mm rolled neckline seam finishes the existing fitted collar opening.
- Broader curved cape folds replace evenly spaced pleats. The original cloth
  grain has reduced painted-light contrast, with actual fold lighting providing
  form. The full-contrast and uniform-cloth passes were rejected and saved in
  `review-history/`. No bitmap blur is used.

The builder extends stage39 in memory; it does not modify that builder file.
Its repeated per-UV mesh-bound scans are cached with guarded exact replacements.
The projection math/reference coordinates remain the pinned stage39 recipe.

All colour before/after images use the same pose, exposure and framing: whole
body yaw330/elevation18/ortho2.7m/900px; tactical384px/ortho3.84m=100px/m; bust
yaw330/elevation5/ortho0.64m/900px. Neutral BX geometry reviews auto-frame their
models and are diagnostic views, not the calibrated colour comparator.

## Verification and limits

Actual source reopen/Ucupaint and3 fresh FBX imports passed. Source counts:
92186 /105742 /92826 triangles. These are offline sprite-source studies with a
120000-triangle exploration cap, not optimized runtime3D or production retopology.
Maximum change in overall bounding extremes versus stage39 is4.542mm; that is a
bounding-box check, not a full per-vertex surface-distance claim.

Delivery audits PASS with close disconnected-fragment warnings recorded in each
`model.json`. Geometry/painted views, all boards and imported renders were opened
and reviewed by this agent; no independent reviewer or user acceptance inferred.
Some original painted seams/cuff projection, simple cloth treatment and hair
construction remain prototype limitations. More geometry cannot add missing
paint detail. There is no rig, animation, equipment swapping or game integration.
Existing61 physical cases remain NOT_RUN. See [stage40](../../qa/stages/2026-11-02-stage-40.md).

Repeat from the active repo using the installed owned Blender:

```powershell
$artBlender = "$env:USERPROFILE/.codex/tools/character-art/blender-5.2.3-windows-x64/blender.exe"
foreach ($artId in @('02_warden','01_mercenary','03_wayfarer')) {
  & $artBlender --background --factory-startup --python-exit-code 1 --python tools/blender/build_surface_refinement.py -- --id $artId
  if ($LASTEXITCODE -ne 0) { throw "Refinement failed: $artId" }
}
& $artBlender --background --factory-startup --python-exit-code 1 --python tools/blender/verify_surface_refinement.py
```

Assemble boards with hidden Aseprite batch `tools/aseprite/surface_refinement.lua`
and `--script-param root=<repo>`. Run `tools/validators/validate_all.py` before
handoff. No automatic rigging/roster rollout follows this static refinement;
user review and a separately scoped motion pilot are next.
