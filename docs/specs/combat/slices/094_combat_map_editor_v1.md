# Slice 094: Combat Map Editor V1

Status: implemented
Owner spec: `docs/specs/combat/presentation/094_combat_map_editor_v1.md`

## Acceptance

- Given the map editor scene is opened, it loads the default combat encounter JSON.
- Given a combat encounter path is entered, `Load` reads the encounter and renders the board grid.
- Given `Tile` brush mode is selected, clicking or dragging changes gameplay tile type.
- Given `Decoration` brush mode is selected, clicking or dragging places the selected processed terrain asset without changing tile type.
- Given `Tile + Decoration` brush mode is selected, clicking or dragging updates both tile type and decoration.
- Given a decoration asset is selected while `Tile` mode is active, the editor switches to `Tile + Decoration` so the selected asset is not silently ignored.
- Given a tile has a decoration, the tile label/tooltip identifies the asset that will be saved.
- Given right click or `Erase Decoration` is used, tile decoration is removed.
- Given `Save JSON` is clicked, the current `grid.tiles` and `terrain_decorations` state is written to the selected encounter path.

## Proof

- `scripts/presentation/combat_map_editor_tests.gd`
- `python tools\validators\validate_all.py`
- Godot headless `CombatMapEditor.tscn` load
- Manual editor smoke test for painting/saving a copied encounter file
