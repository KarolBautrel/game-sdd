# Slice 085: Debug Force Victory

Status: active
Date: 2026-07-16

## Intent

Make dungeon-combat testing faster by adding a combat sandbox button that ends the current battle as a victory.

The owning presentation rules live in:

```text
docs/specs/combat/presentation/069_combat_presentation_architecture.md
```

## Acceptance

- `CombatDebug.tscn` exposes a debug victory command while combat is in progress.
- Pressing the debug victory command defeats all living enemies in the sandbox state.
- The combat result becomes `victory`.
- The combat result payload remains available through the existing combat result contract.
- When launched from dungeon mode, the existing `Return to Dungeon` command can consume that payload.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_debug_force_victory_tests.gd
```
