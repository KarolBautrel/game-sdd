# Combat Specs

Combat specs are split by tactical domain. See `STRUCTURE.md` for the organization rules.

## Domain Specs

### Overview

- `overview/000_combat_core.md`
- `overview/005_event_log_and_replay.md`
- `overview/082_combat_result_contract_v1.md`

### Grid

- `grid/001_combat_grid.md`
- `grid/024_terrain.md`
- `grid/023_cover.md`

### Turns

- `turns/002_turn_order.md`

### Actions

- `actions/003_actions.md`
- `actions/048_special_skills_v1.md`
- `actions/063_aimed_shot_v1.md`
- `actions/064_learned_actions_v1.md`
- `actions/078_guard_break_v1.md`

### Attacks

- `attacks/004_damage_and_statuses.md`
- `attacks/020_ranged_attacks.md`
- `attacks/077_bleeding_status_v1.md`

### Hit Resolution

- `hit_resolution/021_hit_chance.md`
- `hit_resolution/025_accuracy_evasion.md`
- `hit_resolution/044_ranged_intercept.md`

### Equipment

- `equipment/053_loadout_and_item_profiles_v1.md`
- `equipment/058_armor_v1.md`

### Weapons

- `weapons/045_weapon_profiles_v1.md`

### AI

- `ai/008_enemy_ai_v0.md`
- `ai/030_enemy_ai_ranged_v1.md`
- `ai/031_enemy_ai_pathfinding_v1.md`
- `ai/032_enemy_ai_ranged_positioning_v1.md`
- `ai/065_enemy_archetype_loadout_v1.md`
- `ai/081_enemy_archetype_roles_v2.md`

### Presentation

- `presentation/068_combat_interaction_preview.md`
- `presentation/069_combat_presentation_architecture.md`
- `presentation/074_combat_action_feedback.md`
- `presentation/076_unit_animation_state_machine.md`
- `presentation/076_combat_sandbox_layout.md`
- `presentation/083_dungeon_combat_board_theme.md`

## Executable Slices

Executable acceptance scenarios live in `slices/`.

They stay flat and chronological because they prove implementation progress across domains.

Recent presentation/debug slices:

- `slices/085_debug_force_victory.md`

## Milestones

Milestones live in `milestones/`.

They summarize what is already implemented and what a fresh agent should do next.
