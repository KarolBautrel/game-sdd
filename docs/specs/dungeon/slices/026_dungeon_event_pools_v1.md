# Slice 026: Dungeon Event Pools V1

Status: implemented
Date: 2026-07-16

## Intent

Prove corridors can materialize reusable hazards from weighted event pools.

Owner:

```text
docs/specs/dungeon/overview/022_dungeon_event_pools_v1.md
```

## Acceptance

- Event templates may define tags.
- Event pool data validates through `dungeon_event_pool.schema.json`.
- Dungeon corridors may define `hazard_pool_refs`.
- `DungeonStateModel` selects an event from the pool and materializes it as a runtime hazard.
- Existing Old Mine rubble/trap behavior remains unchanged.
- Validator rejects missing pool ids and pool entries referencing missing event ids.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
