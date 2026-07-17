# Slice 047: Dungeon Combat Encounter Selection V1

Status: implemented
Date: 2026-07-17

## Intent

Make generated dungeon combat rooms select encounter refs from a validated pool instead of every room using one hardcoded debug encounter.

Owner:

```text
docs/specs/dungeon/overview/040_dungeon_combat_encounter_selection_v1.md
```

## Acceptance

- `combat_encounter_pool_id` is valid on dungeon/template combat content.
- Encounter pool data validates through schema.
- Encounter pool entries reference existing presentation-ready combat encounters.
- Generated templates use an Old Mine encounter pool for combat rooms.
- Generated dungeon output materializes a concrete `combat_encounter_path` for every combat content entry.
- Generated combat content carries encounter selection metadata for debugging.
- Same seed/profile gives stable selected encounters.
- Different generated seeds/rooms can select different encounter refs.
- Authored dungeons with explicit `combat_encounter_path` keep their pinned encounter.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
```
