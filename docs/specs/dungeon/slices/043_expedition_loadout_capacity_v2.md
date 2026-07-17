# Slice 043: Expedition Loadout Capacity V2

Status: active
Date: 2026-07-17

## Acceptance

- `dungeon_old_mine` defines a packing capacity and per-supply packing costs.
- `DungeonStateModel.default_supply_loadout` returns a loadout inside capacity.
- `DungeonStateModel.clamp_supply_loadout` rejects overpacked loadouts by reducing counts back inside capacity.
- Debug preparation copy shows packing usage.
- Dungeon HUD resource tray uses compact icon/count tiles with tooltip text.
- Visible carried resources are torch oil, pickaxe, trap tools, bandages, camping kit, and food.
- Buying, pricing, and restocking remain outside dungeon mode.

## Proof

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
