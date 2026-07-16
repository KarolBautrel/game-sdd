# Slice 015: Dungeon Light And Oil V1

Status: implemented
Date: 2026-07-16

## Intent

Prove the first light pressure mechanic.

Owner:

```text
docs/specs/dungeon/overview/014_dungeon_light_and_oil_v1.md
```

## Acceptance

- Dungeon run state tracks light.
- Corridor traversal reduces light.
- Lamp oil can restore light.
- Low light affects hazard or combat risk through a structured modifier.
- HUD shows light and oil state.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
