# Slice 009: Dungeon Exit Completion V1

Status: active
Date: 2026-07-16

## Intent

Prove a visible dungeon completion action on authored exit rooms.

The owning domain rules live in:

```text
docs/specs/dungeon/overview/009_dungeon_exit_completion_v1.md
```

## Acceptance

- Completing outside an exit room is rejected.
- Completing in an exit room sets `completed`.
- Completion records the exit room id.
- The HUD exposes `Finish Expedition` in the exit room.
- The completion action does not replace future world-map or post-run flow.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
