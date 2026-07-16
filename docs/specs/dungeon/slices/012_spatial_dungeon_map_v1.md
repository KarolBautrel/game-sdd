# Slice 012: Spatial Dungeon Map V1

Status: active
Date: 2026-07-16

## Intent

Prove the abstract graph presents authored spatial hints.

The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/011_spatial_dungeon_map_v1.md
```

## Acceptance

- Room labels include room-type markers.
- Detail panel includes authored position.
- Exit labels can include destination state hints.
- Existing graph navigation remains unchanged.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
