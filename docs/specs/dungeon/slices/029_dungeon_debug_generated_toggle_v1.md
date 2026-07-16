# Slice 029: Dungeon Debug Generated Toggle V1

Status: implemented
Date: 2026-07-16

## Intent

Prove the dungeon debug scene can switch between authored and generated dungeon data.

Owner:

```text
docs/specs/dungeon/presentation/014_dungeon_debug_generated_toggle_v1.md
```

Related owner:

```text
docs/specs/dungeon/overview/024_dungeon_procedural_draft_v1.md
```

## Acceptance

- The debug scene defaults to authored Old Mine data.
- A preparation-only source toggle changes the active dungeon to the generated draft.
- The generated draft title, start room, room count, and loadout defaults appear through existing HUD helpers.
- Toggling back returns to authored Old Mine data.
- A generated run can start from the debug scene and still use the existing state model.
- Presentation HUD tests cover the toggle helper behavior.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
