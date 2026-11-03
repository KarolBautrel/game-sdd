# Slice 048: Pixel-Art Dungeon UI Assets V1

Status: implemented
Date: 2026-07-17

Owner:

```text
docs/specs/dungeon/presentation/017_pixel_art_dungeon_ui_assets_v1.md
```

## Acceptance

- The generated `icons_dungeon.png` sheet is split into non-empty per-icon PNG assets.
- Output files use semantic names for the dungeon resource tray and room markers.
- Processed icon pixels do not include visible green background remnants.
- Dungeon HUD resource icons point at dedicated files for torch oil, pickaxe, trap tools, bandage, camping kit, and food.
- Dungeon HUD room icons point at dedicated files for treasure, combat, exit, locked, and room-event rooms.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
