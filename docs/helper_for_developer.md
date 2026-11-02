# Helper For Developer

This file explains how to manually design combat maps and terrain decoration layouts.

## Add a playable scenario without controller edits

Use `resources/data/combat_encounters/clearing_crossfire.json` as the map-reference
example. It combines `combat_test_clearing.json` (generated from TMX), two heroes,
melee/archer archetypes and item profiles. Choose explicit unique unit starts on
walkable cells; map test-spawn markers do not relocate units automatically.

1. Create/copy the encounter JSON, retaining required id/seed/units/turn_state/
   event_log and valid profiles. For a referenced map, omit an inline grid.
2. Add its id, label and `res://resources/data/combat_encounters/<name>.json` path
   to `resources/data/combat_scenarios/catalogue.json`. Preserve existing rows.
3. Run `.venv/Scripts/python.exe tools/validators/validate_all.py`, then the full
   verifier. It checks catalogue/map/spawns/archetypes/loadout/visual references.
4. Restart the game to refresh the catalogue cache; choose the new label and Load.
   No `combat_debug.gd` or scenario-catalog script edit is needed.
5. F6 from dungeon sandbox opens the workbench. Load the encounter, choose a
   `user://` copy destination, Save JSON, reload, F5 play and F6 return. This
   forks the referenced map inline and does not write back to TMX or its JSON.
6. Perform the live scenarios and record results in `docs/qa/live-test-scenarios.md`.

## Where Combat Maps Live

Combat encounters are JSON files in:

```text
resources/data/combat_encounters/
```

Current terrain showcase examples:

```text
resources/data/combat_encounters/debug_terrain_grass_showcase.json
resources/data/combat_encounters/debug_terrain_dungeon_showcase.json
```

The important sections for map layout are:

- `background_path`
- `terrain_theme`
- `grid`
- `terrain_decorations`
- `units`

## Basic Coordinate Rules

Map coordinates use `x` and `y`.

- `x: 0` is the left side of the board.
- `y: 0` is the top side of the board.
- `x` increases to the right.
- `y` increases downward.

Example on an `18x11` board:

```text
(0,0)                           (17,0)
  +--------------------------------+
  |                                |
  |                                |
  |                                |
  +--------------------------------+
(0,10)                          (17,10)
```

## Grid Size

The board size is defined here:

```json
"grid": {
  "width": 18,
  "height": 11,
  "tiles": []
}
```

For now, keep showcase maps close to:

```json
"width": 18,
"height": 11
```

This size matches the current combat camera/UI scale better than very small boards.

## Tile Types

Tiles define gameplay. They are not just visual.

Allowed tile types:

```text
floor
blocked
cover_low
highground
```

### `floor`

Normal walkable tile.

Use for most of the map.

```json
{ "x": 4, "y": 3, "type": "floor" }
```

### `blocked`

Tile that blocks movement/pathing.

Use for:

- big rocks
- walls
- trees
- large ruins
- heavy rubble
- impassable props

```json
{ "x": 6, "y": 3, "type": "blocked" }
```

### `cover_low`

Walkable or tactical cover tile, depending on current combat rules.

Use for:

- crates
- low walls
- bushes
- logs
- small ruins
- barricades

```json
{ "x": 8, "y": 5, "type": "cover_low" }
```

### `highground`

Elevated tactical tile.

Use carefully. This affects combat bonuses/rules.

Good examples:

- raised stone platform
- small hill
- balcony-like ruin
- stair landing

```json
{ "x": 10, "y": 4, "type": "highground" }
```

## Important: Tiles vs Decorations

There are two separate concepts:

1. `grid.tiles` controls gameplay.
2. `terrain_decorations` controls visible props.

Example:

```json
{
  "x": 5,
  "y": 2,
  "type": "blocked"
}
```

This means tile `(5,2)` blocks movement.

But it does not necessarily say what visual asset appears there. The visible asset comes from either automatic fallback rules or `terrain_decorations`.

## Automatic Asset Selection

If an encounter does not have `terrain_decorations`, the presentation layer can automatically pick a decoration based on tile type and `terrain_theme`.

Example:

```json
"terrain_theme": "nature"
```

Then:

- `blocked` may show a tree, boulder, or fallen log.
- `cover_low` may show a bush, stump, or low prop.
- `highground` may show a raised/natural accent.

For dungeon:

```json
"terrain_theme": "dungeon"
```

Then:

- `blocked` may show rubble, wall fragments, gates, or large dungeon props.
- `cover_low` may show crates, coffins, small rubble, or chest-like cover.
- `highground` may show raised stone/pillar/platform style props.

Automatic selection is deterministic, not truly random. It depends on tile coordinates and local presentation rules. It is useful for quick prototypes, but it can look illogical.

## Recommended: Handmade Decorations

For real combat maps, use `terrain_decorations`.

When `terrain_decorations` exists, only the listed decorations are shown. Empty tiles stay empty. This is intentional, because handmade maps should not get random extra props.

Example:

```json
"terrain_decorations": [
  {
    "x": 0,
    "y": 2,
    "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_00.png",
    "kind": "tree"
  },
  {
    "x": 5,
    "y": 2,
    "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_08.png",
    "kind": "boulder"
  }
]
```

Fields:

- `x` - tile X coordinate.
- `y` - tile Y coordinate.
- `path` - exact PNG asset to render.
- `kind` - human-readable label; useful for future tooling and AI agents.

## Where Terrain Assets Live

Processed terrain assets live here:

```text
assets/combat/terrain/processed/
```

Nature:

```text
assets/combat/terrain/processed/nature/
```

Dungeon:

```text
assets/combat/terrain/processed/dungeon/
```

Use paths in JSON like this:

```json
"path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_00.png"
```

Godot paths must start with:

```text
res://
```

## Recommended Manual Workflow

1. Pick encounter file to edit, for example:

```text
resources/data/combat_encounters/debug_terrain_grass_showcase.json
```

2. Decide board size in `grid.width` and `grid.height`.

3. Fill `grid.tiles`.

4. Put gameplay blockers first:

```json
{ "x": 4, "y": 3, "type": "blocked" }
```

5. Add tactical cover:

```json
{ "x": 7, "y": 5, "type": "cover_low" }
```

6. Add rare highground:

```json
{ "x": 10, "y": 4, "type": "highground" }
```

7. Add visible props in `terrain_decorations`.

8. Match decoration and gameplay tile logically.

Good:

```json
{ "x": 5, "y": 2, "type": "blocked" }
```

```json
{
  "x": 5,
  "y": 2,
  "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_08.png",
  "kind": "boulder"
}
```

This means a boulder is visible and also blocks movement.

Bad:

```json
{ "x": 5, "y": 2, "type": "floor" }
```

```json
{
  "x": 5,
  "y": 2,
  "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_08.png",
  "kind": "boulder"
}
```

This would show a boulder, but the tile may still be walkable. Use this only if the asset is meant to be purely decorative and not blocking.

## Practical Design Rules

- Do not place many large props next to each other unless it is intended as a wall or blocked area.
- Keep at least a few open movement lanes.
- Avoid blocking all direct routes between teams.
- Use `cover_low` to create tactical choices, not random clutter.
- Use `highground` sparingly, because it affects combat balance.
- Large props should usually be on `blocked`.
- Small props can be on `floor` if they are only visual.
- Cover props should usually be on `cover_low`.
- Try to make maps readable from gameplay perspective first, then decorate.

## Unit Placement

Units are placed in the `units` section.

Example:

```json
{
  "id": "hero_001",
  "team": "player",
  "position": { "x": 3, "y": 5 }
}
```

Avoid placing units on:

- `blocked`
- the same tile as another unit
- tiles occupied by very large decorative props

## Nature Map Suggestions

Good nature layout ideas:

- trees around board edges as `blocked`
- rocks/logs as central blockers
- bushes as `cover_low`
- one small raised hill as `highground`
- open center lane with side cover

Example:

```json
"terrain_theme": "nature",
"grid": {
  "width": 18,
  "height": 11,
  "tiles": [
    { "x": 0, "y": 2, "type": "blocked" },
    { "x": 5, "y": 2, "type": "blocked" },
    { "x": 7, "y": 5, "type": "cover_low" },
    { "x": 10, "y": 4, "type": "highground" }
  ]
}
```

## Dungeon Map Suggestions

Good dungeon layout ideas:

- broken walls as `blocked`
- crates/coffins as `cover_low`
- platforms or stair landings as `highground`
- torches/candles as decorative `floor`
- rubble piles as either `blocked` or `cover_low`, depending on size

Example:

```json
"terrain_theme": "dungeon",
"grid": {
  "width": 18,
  "height": 11,
  "tiles": [
    { "x": 3, "y": 1, "type": "blocked" },
    { "x": 5, "y": 2, "type": "blocked" },
    { "x": 9, "y": 5, "type": "cover_low" },
    { "x": 12, "y": 8, "type": "highground" }
  ]
}
```

## Quick Answer: Do I Only Mark `cover`, `blocked`, etc.?

There are two options.

### Option A - quick prototype

Yes. You define only tile types:

```json
{ "x": 5, "y": 2, "type": "blocked" }
```

If there is no `terrain_decorations` list, the game can pick a matching visual asset automatically based on `terrain_theme` and tile type.

This is fast, but less controlled.

### Option B - proper handmade map

No. For a good-looking map, define both:

```json
{ "x": 5, "y": 2, "type": "blocked" }
```

and:

```json
{
  "x": 5,
  "y": 2,
  "path": "res://assets/combat/terrain/processed/nature/nature_1/nature_1_08.png",
  "kind": "boulder"
}
```

This is the recommended workflow.

## Future Tooling Plan

The current format is ready for a simple Godot map editor.

## Current Godot Map Editor

There is now a first debug editor scene:

```text
scenes/combat/CombatMapEditor.tscn
```

Run it from PowerShell:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" "res://scenes/combat/CombatMapEditor.tscn"
```

Basic usage:

1. Put an encounter JSON path in the path field.
2. Click `Load`.
3. Pick brush mode:
   - `Tile + Decoration` changes tile type and places the selected prop. This is the default because it is the safest mode when designing real maps.
   - `Tile` changes only gameplay tile type.
   - `Decoration` places only the selected visual prop.
   - `Erase Decoration` removes decoration from clicked tiles.
4. Pick tile type:
   - `floor`
   - `blocked`
   - `cover_low`
   - `highground`
5. Pick decoration asset if needed.
6. Left click or drag on the board to paint.
7. Right click a tile to clear only its decoration.
8. Click `Save JSON` to write the encounter file.

Important:

- `Load` does not modify files.
- `Save JSON` overwrites the path currently in the path field.
- If you use `Tile` brush mode, selected assets are ignored. Use `Decoration` or `Tile + Decoration` when you want a specific asset to appear.
- If you only paint tile types and do not save any `terrain_decorations`, CombatDebug may choose automatic fallback assets based on tile type. That can look like the "wrong asset" was loaded.
- For experiments, copy an encounter JSON first and edit the copy.
- The editor writes full `grid.tiles` for every tile on the board.
- If there are no decorations, it removes `terrain_decorations`.
- If at least one decoration exists, it writes explicit `terrain_decorations`, which disables automatic fallback props for unlisted tiles.

Target editor behavior:

- choose biome/theme: `nature` or `dungeon`
- choose tile type: `floor`, `blocked`, `cover_low`, `highground`
- choose decoration asset from processed terrain folder
- click tile to place tile/decor
- right-click tile to remove decoration
- save encounter JSON

V2 workflow (tooling003): F6 from DungeonDebug opens the workbench. Load an
encounter with map_path to materialize its TMX-generated grid and visual defaults.
Unit start brush moves the selected existing unit. Put a copy path (for example
user://my_encounter.json) in the path field, Save JSON, then Load to check it.
Save forks inline data without map_path and never rewrites TMX. Blocked/overlapping
starts block Save/Play. F5 runs the in-memory draft with ordinary combat rules;
F6 in draft combat returns to the same copy and save destination. F6 in the
workbench returns to the retained dungeon session. Tile and decoration brushes
still work independently. TMX object origins must be aligned top-left cells.
