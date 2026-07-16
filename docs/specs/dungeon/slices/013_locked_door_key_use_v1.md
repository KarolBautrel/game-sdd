# Slice 013: Locked Door Key Use V1

Status: active
Date: 2026-07-16

## Intent

Prove that a claimed key reward can unlock a later dungeon room.

The owning domain rules live in:

```text
docs/specs/dungeon/overview/011_locked_door_key_use_v1.md
```

## Acceptance

- A locked room exists in `dungeon_old_mine`.
- Entering it without `rusty_key` is rejected.
- Claiming `rusty_key` allows entry.
- Entering the locked room records it as unlocked.
- HUD exit labels identify locked destinations.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
