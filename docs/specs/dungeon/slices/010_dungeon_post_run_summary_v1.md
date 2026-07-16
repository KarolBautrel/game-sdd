# Slice 010: Dungeon Post-Run Summary V1

Status: active
Date: 2026-07-16

## Intent

Prove a first post-run summary in the dungeon HUD.

The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/010_dungeon_post_run_summary_v1.md
```

## Acceptance

- Completed dungeon state produces summary lines.
- Summary lines include completion room, visited rooms, secured rooms, gold, XP, and items.
- `Finish Expedition` remains hidden after completion.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
