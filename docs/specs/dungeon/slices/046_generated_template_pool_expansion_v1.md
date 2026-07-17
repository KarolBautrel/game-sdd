# Slice 046: Generated Template Pool Expansion V1

Status: implemented
Date: 2026-07-17

## Intent

Make generated dungeon profiles choose from a wider curated Old Mine template pool with explicit pacing metadata.

Owner:

```text
docs/specs/dungeon/overview/039_generated_template_pool_expansion_v1.md
```

## Acceptance

- Template schema requires `profile_ids` and `pacing`.
- Existing and new Old Mine templates validate with profile and pacing metadata.
- `short_mine`, `medium_mine`, and `deep_mine` each have at least three selectable templates.
- Generated draft selection prefers profile-specific templates.
- Generated draft output exposes selected template id, display name, and pacing metadata.
- Generated dungeons still include treasure, combat, exit, room-event pool refs, and hazard pool refs.
- Generated dungeons can still enter the state model and reach a combat room.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
```
