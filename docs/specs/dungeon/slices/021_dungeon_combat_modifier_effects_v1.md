# Slice 021: Dungeon Combat Modifier Effects V1

Status: implemented
Date: 2026-07-16

## Intent

Prove the first real combat launch effects from dungeon exploration consequences.

Owner:

```text
docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md
```

## Acceptance

- Dungeon launch metadata still carries the raw `dungeon_modifiers` payload.
- Enemy initiative modifiers from dungeon light can change enemy stats before combat starts.
- Dungeon target effects can reduce the resolved party slot unit HP.
- Dungeon `limping` can reduce the resolved party slot unit starting MP.
- Dungeon `bleeding` can apply a supported starting combat status to the first player unit.
- Unsupported future dungeon debuffs are ignored safely.
- Combat result contract remains unchanged.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
```
