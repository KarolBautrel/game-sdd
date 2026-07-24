# sdd-game

Godot 4.7 project built with Spec Driven Development.

## Current workflow

1. Find the domain spec in `docs/specs/` that owns the rule.
2. Update or add that domain spec before implementation.
3. Add or update data contracts in `resources/schemas/`.
4. Add reference data in `resources/data/`.
5. Add or update executable slices as acceptance scenarios. Slices prove rules; they do not own durable rules.
6. Add or update automated test/validator coverage for the slice. If automation does not exist yet, document the manual verification gap in the slice and milestone.
7. Update the active milestone as a summary and pointer to the owning specs, slices, and tests.
8. Run validation:

```powershell
python tools/validators/validate_all.py
```

9. Implement gameplay only after the spec and data contract pass.

Required SDD chain for behavior changes:

```text
domain/presentation spec -> slice acceptance scenario -> test/validator proof
```

`docs/specs/*/milestones/` summarizes progress. `docs/specs/*/slices/` proves behavior. Durable gameplay, data, AI, UI, and presentation rules belong in domain folders such as `actions/`, `equipment/`, `ai/`, or `presentation/`.

When a milestone defines an ordered queue, work from the first unfinished item. Mark it complete only after its owner spec, slice, implementation, and validation/test proof are all present.

## Manual Commands

Run these commands from the project directory:


Validate all specs, schemas, reference data, and executable slices:

```powershell
python tools\validators\validate_all.py
```

Validate only combat executable slices:

```powershell
python -m tools.validators.validate_combat_slice
```

The current main scene is `scenes/dungeon/DungeonDebug.tscn`.


Debug scene controls:

- Select `move`, then click a neighboring floor tile.
- Select `basic_attack`, then click an enemy tile.
- Select `ranged_attack`, then click an enemy tile up to 3 tiles away.
- Click `defend` to apply the defending status.
- Click `end_turn` to pass control to the next unit.
- Click `enemy_ai` while an enemy is active to let AI v0 choose a command.
- Click `enemy_turn` to advance through a simple enemy turn sequence.
- Click `reset` to reload the debug encounter.
- The active unit is highlighted yellow.
- Legal move and attack targets are highlighted green.
- Blocked terrain is dark.
- Highground terrain is gold.
- The right side shows action buttons, unit HP/AP, and the event log.
- Ranged attacks show hit/miss rolls, unit modifiers, and terrain modifiers in the event log.
- Rejected commands show the rejection reason in the feedback label.
- Read the right-side event log to verify what the domain resolver emitted.

## Tooling

- Godot 4.7 stable
- GDScript
- Python 3.12+ for validators and generators
- Tiled for maps
- Aseprite for sprite sources and sprite sheet export

## Spec Domains

- `docs/specs/combat/` tactical combat specs, organized by domain.
- `docs/specs/combat/STRUCTURE.md` explains combat spec ownership and folder rules.
- `docs/specs/combat/slices/` executable combat acceptance scenarios.
- `docs/specs/dungeon/` dungeon exploration and encounter triggers.
- `docs/specs/world/` world map, towns, travel, and services.
- `docs/specs/data/` shared data contracts and validation rules.


