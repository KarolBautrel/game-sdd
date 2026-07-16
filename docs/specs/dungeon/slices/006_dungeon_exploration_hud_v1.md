# Slice 006: Dungeon Exploration HUD V1

Status: active
Date: 2026-07-16

## Intent

Prove the first cleaner player-facing dungeon exploration HUD.

The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/007_dungeon_exploration_hud_v1.md
```

## Acceptance

- The dungeon scene loads without errors.
- The main status text is player-facing, not a state-debug instruction.
- The detail panel does not show raw state lists or pending combat paths.
- The header shows compact expedition progress.
- Entering a pending combat room exposes a single visible `Enter Combat` command.
- Manual `Resolve Victory` and `Resolve Defeat` controls are not visible in the HUD.
- Existing dungeon movement, pending combat creation, and dungeon session bridge behavior remain intact.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Manual Verification Gap

Visual polish is still manually verified in the running Godot scene. This slice adds a headless UI contract test for labels and visible commands, but it does not capture screenshots.
