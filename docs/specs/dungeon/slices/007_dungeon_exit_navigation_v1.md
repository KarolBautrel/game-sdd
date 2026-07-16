# Slice 007: Dungeon Exit Navigation V1

Status: active
Date: 2026-07-16

## Intent

Prove player-facing exit commands and number-key traversal in the dungeon HUD.

The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/008_dungeon_exit_navigation_v1.md
```

## Acceptance

- The HUD can produce stable exit command labels for connected rooms.
- Exit commands use the same movement path as graph clicks.
- Number-key navigation targets the same connected-room slots.
- Existing graph click navigation remains available.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
