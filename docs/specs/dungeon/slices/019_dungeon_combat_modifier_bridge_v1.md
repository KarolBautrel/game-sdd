# Slice 019: Dungeon Combat Modifier Bridge V1

Status: implemented
Date: 2026-07-16

## Intent

Prove that dungeon consequences can affect combat launch through structured data.

Owner:

```text
docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md
```

## Acceptance

- Dungeon launch metadata can include light/debuff/ambush modifiers.
- Combat scene consumes only supported modifier fields.
- Unsupported future fields fail safely or are ignored with validation.
- Combat result contract remains unchanged.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
```
