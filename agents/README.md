# Agent Notes

## Pixel Art Workflow

- All pixel-art asset creation or pixel-level edits must be done in Aseprite.
- Prefer Aseprite CLI scripts for generated UI sprites, debug sprites, tiles, and animation-frame exports so the operation is repeatable.
- Do not use general image editors or ad hoc raster scripts for final pixel-art assets unless Aseprite is unavailable and the user explicitly approves the fallback.
- Keep source scripts for generated pixel assets under `tools/aseprite/` when practical.
- Terrain tiles and terrain objects must follow the current `assets/terrain/nature/` reference direction and the `assets/tilesets/combat_logic_tiles.png` sandbox direction: tactical 2.5D/oblique pixel art, slightly viewed from the side rather than flat top-down.
- Terrain forms should have readable volume: front faces, contact shadows, height cues, and silhouettes that make blocked tiles, cover, and highground understandable at combat zoom.
- Do not make final terrain as simple flat-color debug tiles. Debug placeholders are acceptable only when clearly documented as temporary.

## Terrain Art Contract

- Treat `assets_src/aseprite/terrain/combat_logic_tiles.aseprite` as the editable source for the current combat terrain atlas.
- Export terrain atlas updates to `assets/tilesets/combat_logic_tiles.png` through Aseprite, preferably with `tools/aseprite/combat_terrain_tiles.lua` or a similarly repeatable Aseprite script.
- Preserve the combat tile scale and readability target: the atlas currently uses 76x76 tiles for the sandbox and Tiled map pipeline.
- Terrain should read like a tactical RPG board in the direction of Battle Brothers, Wartales, or The Iron Oath: slightly side-on, chunky silhouettes, strong contact shadows, readable height, and painterly pixel texture.
- Do not use clean vector shapes, smooth gradients, noisy AI leftovers, or single-color logic squares as final terrain.
- Every gameplay tile type must be visually distinct at combat zoom:
  - `floor` should be calm ground that does not fight the units;
  - `blocked` should have a clear solid obstacle silhouette;
  - `highground` should visibly rise above the floor with a front face or ledge;
  - `cover_low` should look like partial cover, not a full wall.
- If Tiled terrain types or atlas order changes, update the Tiled tileset/source map and run map validation before finishing.
