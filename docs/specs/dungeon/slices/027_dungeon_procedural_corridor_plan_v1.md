# Slice 027: Dungeon Procedural Corridor Plan V1

Status: implemented
Date: 2026-07-16

## Intent

Prove generated corridor planning can select reusable hazard pools by tags and danger.

Owner:

```text
docs/specs/dungeon/overview/023_dungeon_procedural_corridor_plan_v1.md
```

Related owner:

```text
docs/specs/dungeon/overview/022_dungeon_event_pools_v1.md
```

## Acceptance

- Event pool data may define optional `danger_min` and `danger_max`.
- The validator rejects event pools with `danger_min > danger_max`.
- A low-danger mine corridor plan selects the rubble pool.
- A high-danger mine corridor plan selects the trap pool.
- Planned `hazard_pool_refs` materialize through the same `DungeonStateModel` corridor hazard path as authored corridors.
- Existing authored Old Mine traversal behavior remains unchanged.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```
