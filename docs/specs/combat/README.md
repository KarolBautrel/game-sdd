# Combat Specs

Combat specs are split by tactical domain. See `STRUCTURE.md` for the organization rules.

## Domain Specs

### Overview

- `overview/000_combat_core.md`
- `overview/005_event_log_and_replay.md`

### Grid

- `grid/001_combat_grid.md`
- `grid/024_terrain.md`
- `grid/023_cover.md`

### Turns

- `turns/002_turn_order.md`

### Actions

- `actions/003_actions.md`

### Attacks

- `attacks/004_damage_and_statuses.md`
- `attacks/020_ranged_attacks.md`

### Hit Resolution

- `hit_resolution/021_hit_chance.md`
- `hit_resolution/025_accuracy_evasion.md`

### AI

- `ai/008_enemy_ai_v0.md`
- `ai/030_enemy_ai_ranged_v1.md`
- `ai/031_enemy_ai_pathfinding_v1.md`
- `ai/032_enemy_ai_ranged_positioning_v1.md`

## Executable Slices

Executable acceptance scenarios live in `slices/`.

They stay flat and chronological because they prove implementation progress across domains.

## Milestones

Milestones live in `milestones/`.

They summarize what is already implemented and what a fresh agent should do next.
