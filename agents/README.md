# Agent Notes

## Pixel Art Workflow

- All pixel-art asset creation or pixel-level edits must be done in Aseprite.
- Prefer Aseprite CLI scripts for generated UI sprites, debug sprites, tiles, and animation-frame exports so the operation is repeatable.
- Do not use general image editors or ad hoc raster scripts for final pixel-art assets unless Aseprite is unavailable and the user explicitly approves the fallback.
- Keep source scripts for generated pixel assets under `tools/aseprite/` when practical.
- Terrain tiles and terrain objects must follow the current `assets/terrain/nature/` reference direction and the `assets/tilesets/combat_logic_tiles.png` sandbox direction: tactical 2.5D/oblique pixel art, slightly viewed from the side rather than flat top-down.
- Terrain forms should have readable volume: front faces, contact shadows, height cues, and silhouettes that make blocked tiles, cover, and highground understandable at combat zoom.
- Do not make final terrain as simple flat-color debug tiles. Debug placeholders are acceptable only when clearly documented as temporary.
