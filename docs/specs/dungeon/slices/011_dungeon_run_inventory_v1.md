# Slice 011: Dungeon Run Inventory V1

Status: active
Date: 2026-07-16

## Intent

Prove reward totals for a dungeon run.

The owning domain rules live in:

```text
docs/specs/dungeon/overview/010_dungeon_run_inventory_v1.md
```

## Acceptance

- Claimed treasure increments gold and item totals.
- Claimed guarded treasure increments XP, gold, and item totals.
- HUD progress uses reward totals.
- Post-run summary uses reward totals.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
