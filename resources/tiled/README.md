# Tiled Map Sources

Tiled `.tmx` files are the editable source of truth for map layouts.

Current flow:

1. Edit a map in `resources/tiled/maps/`.
2. Use `resources/tiled/tilesets/combat_logic_tiles.tsx` for logic tiles:
   - `floor`
   - `blocked`
   - `highground`
   - `cover_low`
3. Export the engine JSON with:

```powershell
python tools\maps\tiled_to_map_json.py resources\tiled\maps\combat_test_clearing.tmx resources\data\maps\combat_test_clearing.json
```

The generated JSON in `resources/data/maps/` is consumed by validators and future runtime map loading. Do not edit generated map JSON by hand unless the matching `.tmx` is updated too.
