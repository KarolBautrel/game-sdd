# Slice 018: Dungeon Debuff Table V1

Status: implemented
Date: 2026-07-16

## Intent

Prove a structured dungeon debuff catalogue.

Owner:

```text
docs/specs/dungeon/overview/017_dungeon_debuff_table_v1.md
```

## Acceptance

- Dungeon debuff ids are defined in data or code-owned table.
- Hazards apply debuffs by id.
- Debuffs can be summarized in dungeon state.
- Combat bridge mappings are documented or explicitly deferred.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
