# Slice 088: Combat Terrain Asset Showcase V1

Status: implemented
Owner spec: `docs/specs/combat/presentation/088_combat_terrain_asset_showcase_v1.md`

## Acceptance

- Given terrain atlas PNGs exist under `assets/combat/terrain/to_process/`, the extraction script creates transparent processed props under `assets/combat/terrain/processed/`.
- Given processed terrain props exist, the manifest records at least one nature and one dungeon set.
- Given combat debug loads a nature themed encounter, blocked/cover/highground/floor decoration choices use processed nature props.
- Given combat debug loads a dungeon themed encounter, blocked/cover/highground/floor decoration choices use processed dungeon props.
- Given an encounter defines `terrain_decorations`, those handmade placements are used exactly and automatic fallback props are skipped for unlisted tiles.
- Given showcase nature/dungeon encounters are loaded, their props should read as intentional handmade map dressing rather than random repeated clusters.
- Given the scenario picker is opened, grass and dungeon terrain showcase encounters are selectable.
- Existing combat movement, targeting, and terrain gameplay rules remain unchanged.

## Proof

- `scripts/presentation/combat_terrain_asset_pipeline_tests.gd`
- `python tools\validators\validate_all.py`
- Godot headless `CombatDebug.tscn` load
- Manual visual review of `New terrain grass` and `New terrain dungeon`
