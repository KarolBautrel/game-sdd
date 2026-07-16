# Slice 017: Dungeon Trap Tools V1

Status: implemented
Date: 2026-07-16

## Intent

Prove a trap corridor hazard mitigated by trap tools.

Owner:

```text
docs/specs/dungeon/overview/016_dungeon_trap_tools_v1.md
```

## Acceptance

- A corridor can contain a trap hazard.
- Trap tools mitigate or prevent the trap outcome.
- Without tools, a deterministic target receives a debuff or HP loss under test seed.
- HUD can present the event and result.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
