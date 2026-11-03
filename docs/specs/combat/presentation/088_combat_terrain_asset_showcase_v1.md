# Combat Terrain Asset Showcase V1

Status: implemented
Owner: combat presentation

## Purpose

Combat terrain props should use the new scale-matched terrain atlases instead of the older tiny placeholder decorations. These assets establish the practical prop scale relative to the current 2.5D combat characters and `140x104` board tiles.

## Rules

- Raw terrain atlas inputs live under `assets/combat/terrain/to_process/`.
- Processed transparent PNG terrain props live under `assets/combat/terrain/processed/`.
- The terrain extraction workflow must remove green-screen backgrounds and write a manifest for validation.
- Combat presentation can select terrain decoration sets by explicit encounter `terrain_theme`.
- `terrain_theme: "nature"` uses processed nature props for grass/clearing boards.
- `terrain_theme: "dungeon"` uses processed dungeon props for underground/stone boards.
- Showcase encounters use explicit `terrain_decorations` entries for handmade prop placement. When this list is present, presentation must not add automatic fallback props to other tiles.
- Future battle maps should prefer a pool of handmade logical layouts per biome/difficulty over fully automatic prop scattering. Randomness can choose a layout variant, enemy setup, and encounter parameters, but prop composition should avoid nonsensical clusters such as repeated statues side by side unless the layout intentionally describes that scene.
- Processed props are scaled in presentation by prop kind so tall trees/statues/torches can be taller than one tile while small props remain readable.
- Existing terrain rules remain unchanged: `blocked`, `cover_low`, `highground`, and `floor` keep their current gameplay meaning.

## Proof

Presentation010/stage36 supersedes the displayed art through a central semantic
adapter. Authored IDs/placements, themes and logical terrain remain unchanged;
legacy resources stay as references. Displayed floors use original painted ground
swatches and every displayed prop family routes to original Blender renders with
the characters' material palette,18-degree camera and consistent contact shadows.
Raised terrain uses an actual stone/earth ledge sprite rather than yellow debug
plates/labels. The editor preview uses the same adapter while serializing the
original authoring identifiers. Validate domain equality, mapping coverage and
native nature/dungeon boards before export.
The newer semantic terrain layer supplies a solid silhouette on a blocked or
cover tile with no authored decoration; explicit empty floor tiles remain empty
and `_tile_decoration_path`/saved placement data still has no fallback entry.

- `tools/terrain/extract_combat_terrain_assets.gd`
- `assets/combat/terrain/processed/processed_terrain_manifest.json`
- `resources/data/combat_encounters/debug_terrain_grass_showcase.json`
- `resources/data/combat_encounters/debug_terrain_dungeon_showcase.json`
- `scripts/presentation/combat_terrain_asset_pipeline_tests.gd`
- Headless `CombatDebug.tscn` load

## Manual Review

Open the combat debug scene and select:

- `New terrain grass`
- `New terrain dungeon`

Verify that props read at the same world scale as the warrior and enemies, and that large props do not hide important unit/resource information during normal play.

The scenario picker is only available when `CombatDebug.tscn` is opened directly. If combat is launched from dungeon flow, the debug picker is intentionally locked to the launched encounter.
