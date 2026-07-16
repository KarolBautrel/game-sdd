# Combat Map Editor V1

Status: implemented
Owner: combat presentation tooling

## Purpose

Combat maps need a lightweight authoring tool so map layout can be edited visually instead of by manually writing every `grid.tiles` and `terrain_decorations` entry in JSON.

This is a debug/developer tool, not a player-facing game screen.

## Rules

- The editor lives at `scenes/combat/CombatMapEditor.tscn`.
- The editor loads and saves combat encounter JSON files.
- The editor supports tile painting for:
  - `floor`
  - `blocked`
  - `cover_low`
  - `highground`
- The editor supports decoration placement from `assets/combat/terrain/processed/`.
- Left click or drag applies the selected brush.
- Right click clears decoration from a tile.
- `Tile` brush changes only gameplay tile type.
- `Decoration` brush changes only `terrain_decorations`.
- `Tile + Decoration` changes tile type and decoration together.
- `Erase Decoration` removes decorations while keeping gameplay tile type.
- `Tile + Decoration` is the default brush because it prevents accidental automatic fallback props when a user expects a selected asset to be placed.
- If the user selects a decoration while `Tile` brush is active, the editor switches back to `Tile + Decoration`.
- The editor must show the selected decoration path and a short asset name on decorated cells so users can verify which asset will be saved.
- Saving writes a full `grid.tiles` array for the board.
- Saving writes `terrain_decorations` only when at least one decoration exists.
- Loading must not modify files; only `Save JSON` writes to disk.

## Manual Safety

The editor overwrites the path in the path field when `Save JSON` is clicked. For experiments, copy an encounter first and edit the copy.

## Proof

- `scenes/combat/CombatMapEditor.tscn`
- `scripts/presentation/combat_map_editor.gd`
- `scripts/presentation/combat_map_editor_tests.gd`
- `docs/helper_for_developer.md`
- Headless `CombatMapEditor.tscn` load
