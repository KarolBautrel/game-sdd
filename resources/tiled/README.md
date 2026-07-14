# Tiled Map Sources

Tiled `.tmx` files are the editable source of truth for map layouts.

Current flow:

1. Edit a map in `resources/tiled/maps/`.
2. Use `resources/tiled/tilesets/combat_logic_tiles.tsx` for logic tiles:
   - `floor`
   - `blocked`
   - `highground`
   - `cover_low`
   - visual-only variants may share a gameplay type, for example a boulder and a fallen log can both be `blocked`.
3. Export the engine JSON with:

```powershell
python tools\maps\tiled_to_map_json.py resources\tiled\maps\combat_test_clearing.tmx resources\data\maps\combat_test_clearing.json
```

The generated JSON in `resources/data/maps/` is consumed by validators and future runtime map loading. Do not edit generated map JSON by hand unless the matching `.tmx` is updated too.

## Terrain Art Direction

- Terrain art should read like a tactical 2.5D battlefield, not a flat top-down editor grid.
- Match the current reference direction in `assets/terrain/nature/` and the placeholder direction in `assets/tilesets/combat_logic_tiles.png`: slightly side-on forms, front faces, contact shadows, raised highground, bulky blocked terrain, and low cover with visible volume.
- Keep tile silhouettes readable at 76x76 combat scale.
- Final pixel terrain work should be authored or touched up in Aseprite. Scripted placeholders are allowed only for temporary sandbox work.
