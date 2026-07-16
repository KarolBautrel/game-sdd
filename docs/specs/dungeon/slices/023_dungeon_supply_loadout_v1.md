# Slice 023: Dungeon Supply Loadout V1

Status: implemented
Date: 2026-07-16

## Intent

Prove that a dungeon run can start with an explicit selected supply loadout.

Owner:

```text
docs/specs/dungeon/overview/020_dungeon_supply_loadout_v1.md
```

## Acceptance

- Dungeon data can define `supply_loadout_options`.
- `DungeonStateModel.initial_state` can receive a selected supply loadout.
- The selected loadout becomes run `supplies`.
- Run state records `selected_supply_loadout`.
- Debug HUD exposes loadout controls before expedition start.
- Debug HUD blocks traversal until `Start Expedition`.
- Reset returns the player to the loadout/preparation step.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
