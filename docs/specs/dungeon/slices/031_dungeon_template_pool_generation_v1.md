# Slice 031: Dungeon Template Pool Generation V1

Status: implemented
Date: 2026-07-16

## Intent

Prove generated dungeons come from curated templates while corridor hazards remain generated.

Owner:

```text
docs/specs/dungeon/overview/026_dungeon_template_pool_generation_v1.md
```

## Acceptance

- Template data validates through `dungeon_template.schema.json`.
- Generated dungeon selection is deterministic for the same seed and difficulty.
- Different seeds can select different templates.
- Difficulty filters available template layouts.
- Selected generated dungeons have finite authored room/corridor graphs.
- Seed selects which marked corridors receive hazard pool refs.
- Seed assigns whether each selected hazard is rubble or trap.
- Not every marked candidate receives a hazard in a generated instance.
- Different seeds can move rubble/trap refs to different corridors and can swap which selected corridor receives trap versus rubble.
- Generated template dungeons can enter the existing dungeon state model and reach combat rooms.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```
