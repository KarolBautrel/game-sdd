# Dungeon Specs

Dungeon specs describe the exploration layer that connects authored rooms, corridor movement, encounter triggers, rewards, and tactical combat transitions.

## Domain Specs

### Overview

- `overview/000_dungeon_exploration_loop.md`
- `overview/001_dungeon_combat_boundary.md`
- `overview/002_dungeon_data_contract_v1.md`

### Presentation

- `presentation/003_dungeon_debug_view_v1.md`

## Executable Slices

- `slices/001_dungeon_data_contract_v1.md`
- `slices/002_dungeon_debug_view_v1.md`

## Milestones

- `milestones/001_dungeon_exploration_foundation.md`

## Current Status

Dungeon mode has an initial data contract and an abstract debug view.

The next implementation step is a deterministic dungeon state model for current room, visited rooms, cleared rooms, and pending combat requests.
