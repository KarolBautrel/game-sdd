# Original raider acceptance slice

Owner: [presentation008](../008_original_raider.md).

1. Open original reference/model front, side, rear and oblique previews; verify
   hood/face, shoulder overlap, boots, sash, cleaver and grip against the brief.
2. Prove weighted original mesh + UV/textures +65-bone compatible skeleton,
   five action clips and FBX re-import with actual bone movement.
3. Enumerate256 PNG frames (8 directions x32 action frames), Aseprite editable
   sources, alpha edges, no clipping and varying poses. Validate full-direction
   file lookup, fixed pivot, final corpse hold and unchanged legacy artwork paths.
4. Load Ash-road raiders and roadside ambush in Godot; verify the enemy renders,
   movement/facing/attack/hit/death/reset follow the existing event lifecycle and
   no visual update changes domain state.
5. Inspect native GPU output at1920x1080/2560x1440/3840x2160; run affected automated
   checks and release smoke. Record concrete defects/fixes and proof paths.
6. Later, after physical control release, play an ordinary battle against the
   raider, inspect all action transitions/grounding/grip at normal speed, win or
   lose normally, reload and audit the closed log. Mark this gap NOT_RUN now.

Automated proof: original_raider_tests.gd plus character build manifest and Blender
verification. Actual-play registry owns physical results; fixtures are not victory.
