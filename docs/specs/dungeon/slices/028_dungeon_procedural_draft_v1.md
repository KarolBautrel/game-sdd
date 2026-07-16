# Slice 028: Dungeon Procedural Draft V1

Status: implemented
Date: 2026-07-16

## Intent

Prove a generated dungeon-shaped draft can be used by the existing dungeon state model.

Owner:

```text
docs/specs/dungeon/overview/024_dungeon_procedural_draft_v1.md
```

Related owner:

```text
docs/specs/dungeon/overview/023_dungeon_procedural_corridor_plan_v1.md
```

## Acceptance

- `DungeonStateModel.procedural_dungeon_draft` returns normal dungeon data with rooms, corridors, supplies, party formation, and exit rules.
- The draft starts in the generated entrance room through `initial_state`.
- Low-danger generated corridors receive rubble pool refs through `procedural_corridor_plan`.
- High-danger generated corridors receive trap pool refs through `procedural_corridor_plan`.
- Generated corridor hazards materialize and prompt through the existing traversal flow.
- Generated combat rooms create a normal pending combat request.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
```
