# Corridor Hazard Variety V2

Status: implemented
Owner: dungeon overview

## Purpose

Broaden corridor traversal pressure beyond the first rubble and needle-trap examples while keeping the existing corridor hazard prompt and consequence contract.

## Rules

- Corridor hazard catalogues support these beta hazard families:
  - `rubble`;
  - `trap`;
  - `darkness`;
  - `noise`;
  - `blockage`;
  - `generic`.
- Multiple severities may exist within a family, such as minor rubble and major cave-in.
- Hazard outcomes may block traversal by setting `blocks_traversal`.
- Darkness hazards may consume or reward `lamp_oil` usage through the same `use_supply` choice contract.
- Noise/alarm hazards may apply stress-style debuffs or log-only pressure until ambush encounter selection exists.
- Trap pools may contain multiple trap variants.
- Hazard pools should group entries by theme and danger band so procedural corridors can select from varied outcomes.

## Current Scope

This version adds reusable data and verifies runtime materialization/resolution. It does not yet spawn ambush combats, add map-visible temporary blockade state, or introduce new supply types.

## Proof

- `resources/schemas/dungeon_event.schema.json`
- `resources/schemas/dungeon_event_pool.schema.json`
- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
