# Slice 016: Dungeon Rubble And Pickaxe V1

Status: implemented
Date: 2026-07-16

## Intent

Prove a rubble corridor hazard mitigated by pickaxe.

Owner:

```text
docs/specs/dungeon/overview/015_dungeon_rubble_pickaxe_v1.md
```

## Acceptance

- A corridor can contain a rubble hazard.
- Pickaxe resolves rubble safely.
- Without pickaxe, forcing passage can produce a deterministic negative outcome under test seed.
- Resulting consequence is recorded in dungeon state.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```
