# Dungeon Specs

Dungeon specs describe the exploration layer that connects authored rooms, corridor movement, encounter triggers, rewards, and tactical combat transitions.

## Domain Specs

### Overview

- `overview/000_dungeon_exploration_loop.md`
- `overview/001_dungeon_combat_boundary.md`
- `overview/002_dungeon_data_contract_v1.md`
- `overview/004_dungeon_state_model_v1.md`
- `overview/005_dungeon_combat_transition_v1.md`

### Presentation

- `presentation/003_dungeon_debug_view_v1.md`
- `presentation/006_dungeon_exploration_scene_v1.md`

## Executable Slices

- `slices/001_dungeon_data_contract_v1.md`
- `slices/002_dungeon_debug_view_v1.md`
- `slices/003_dungeon_state_model_v1.md`
- `slices/004_dungeon_combat_transition_v1.md`
- `slices/005_dungeon_exploration_scene_v1.md`

## Milestones

- `milestones/001_dungeon_exploration_foundation.md`

## Current Status

Dungeon mode has an initial data contract, an abstract debug view, a deterministic state model, and the first domain-level combat result transition.

The next implementation step is the first usable exploration scene flow: moving through rooms, launching combat scenes from pending requests, and returning after combat.
