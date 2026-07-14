# Agent Notes

## Pixel Art Workflow

- All pixel-art asset creation or pixel-level edits must be done in Aseprite.
- Prefer Aseprite CLI scripts for generated UI sprites, debug sprites, tiles, and animation-frame exports so the operation is repeatable.
- Do not use general image editors or ad hoc raster scripts for final pixel-art assets unless Aseprite is unavailable and the user explicitly approves the fallback.
- Keep source scripts for generated pixel assets under `tools/aseprite/` when practical.
