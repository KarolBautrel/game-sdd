# Slice011: compare actual character styles

Owner: [presentation011](../011_character_style_studies.md).

1. Current rollback checkpoint is committed and remote hash verified.
2. Primary-source research and CC0 scaffold provenance/hash are persisted.
3. Three distinct complete models have .blend/FBX/albedo and measured bounds.
4. Reimport each FBX in a fresh Blender scene; verify mesh, dimensions, UVs and
   image texture references. Verify source scenes reopen and renders have alpha.
5. Matched front/side/rear/three-quarter/face and100px/m tactical images exist.
   Inspect silhouettes, visible face, grips, layer intersections and floor contact.
6. Aseprite comparison source/export show close views and native-size world samples.
7. Repository validators and production baseline manifest checks pass. No active
   production art/routing is changed. Commit/push studies and verify remote hash.

Proof: the study manifest and `tools/blender/verify_style_studies.py`, plus the
persisted QA report. User art choice remains pending; these static prototypes
cannot establish animation or interactive acceptance. Existing61 physical cases
remain NOT_RUN.

## Live preview follow-up

1. Export12 native100px/m full-body views +3 face PNGs through Aseprite.
2. Preview scene loads all three cards, synchronized direction/zoom/floor/face
   controls work, and the battle Tools entry opens/closes without state mutation.
3. Headless UI assertions and project validation PASS, then launch visibly via
   `start_game.ps1 -Scene styles` on larger left DISPLAY1/windowed. Observe actual
   window placement and exercise the normal controls; persist evidence/limits.
4. Leave the preview open for the user's A/B/C selection. Production character
   animation/routing and existing61 gameplay acceptance cases remain unchanged.
