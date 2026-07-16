# Slice 025: Dungeon Reusable Event Catalogue V1

Status: implemented
Date: 2026-07-16

## Intent

Prove corridor hazards can be reused through catalogue templates instead of being embedded only in a specific dungeon.

Owner:

```text
docs/specs/dungeon/overview/021_dungeon_reusable_event_catalogue_v1.md
```

## Acceptance

- Reusable corridor hazard templates validate through `dungeon_event.schema.json`.
- `dungeon_old_mine` references reusable templates with `hazard_refs`.
- `DungeonStateModel` materializes hazard refs into the same runtime hazard shape used by inline hazards.
- Existing rubble and trap choices, outcomes, persistence, and combat modifier behavior remain unchanged.
- Dungeon HUD hazard markers work for referenced hazards.
- Validator rejects missing event refs, missing debuff refs, and missing party target refs inside reusable event templates.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
