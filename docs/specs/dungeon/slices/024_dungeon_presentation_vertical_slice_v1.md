# Slice 024: Dungeon Presentation Vertical Slice V1

Status: implemented
Date: 2026-07-16

## Intent

Prove the dungeon debug scene now has a stronger playable exploration presentation without changing dungeon rules.

Owner:

```text
docs/specs/dungeon/presentation/013_dungeon_presentation_vertical_slice_v1.md
```

## Acceptance

- Dungeon scene exposes a resource tray with light, oil, pickaxe, trap tools, and active effects.
- Resource tray reflects loadout changes before expedition start and run-state changes after start.
- Dungeon scene exposes a map legend for room markers and danger.
- Corridors with hazards expose readable marker labels such as `Rubble` or `Trap`.
- Current route/state copy distinguishes preparation, corridor event resolution, and active exploration.
- Existing room traversal, event, combat, reward, and exit behavior remains unchanged.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
```
