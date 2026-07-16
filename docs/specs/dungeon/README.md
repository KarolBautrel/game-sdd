# Dungeon Specs

Dungeon specs describe the exploration layer that connects authored rooms, corridor movement, expedition supplies, corridor hazards, encounter triggers, rewards, and tactical combat transitions.

## Domain Specs

### Overview

- `overview/000_dungeon_exploration_loop.md`
- `overview/001_dungeon_combat_boundary.md`
- `overview/002_dungeon_data_contract_v1.md`
- `overview/004_dungeon_state_model_v1.md`
- `overview/005_dungeon_combat_transition_v1.md`
- `overview/008_dungeon_reward_claim_v1.md`
- `overview/009_dungeon_exit_completion_v1.md`
- `overview/010_dungeon_run_inventory_v1.md`
- `overview/011_locked_door_key_use_v1.md`
- `overview/012_dungeon_expedition_resources_v1.md`
- `overview/013_dungeon_hazard_outcome_contract_v1.md`
- `overview/014_dungeon_light_and_oil_v1.md`
- `overview/015_dungeon_rubble_pickaxe_v1.md`
- `overview/016_dungeon_trap_tools_v1.md`
- `overview/017_dungeon_debuff_table_v1.md`
- `overview/018_dungeon_combat_modifier_bridge_v1.md`

### Presentation

- `presentation/003_dungeon_debug_view_v1.md`
- `presentation/006_dungeon_exploration_scene_v1.md`
- `presentation/007_dungeon_exploration_hud_v1.md`
- `presentation/008_dungeon_exit_navigation_v1.md`
- `presentation/010_dungeon_post_run_summary_v1.md`
- `presentation/011_spatial_dungeon_map_v1.md`
- `presentation/012_dungeon_event_presentation_v1.md`

## Executable Slices

- `slices/001_dungeon_data_contract_v1.md`
- `slices/002_dungeon_debug_view_v1.md`
- `slices/003_dungeon_state_model_v1.md`
- `slices/004_dungeon_combat_transition_v1.md`
- `slices/005_dungeon_exploration_scene_v1.md`
- `slices/006_dungeon_exploration_hud_v1.md`
- `slices/007_dungeon_exit_navigation_v1.md`
- `slices/008_dungeon_reward_claim_v1.md`
- `slices/009_dungeon_exit_completion_v1.md`
- `slices/010_dungeon_post_run_summary_v1.md`
- `slices/011_dungeon_run_inventory_v1.md`
- `slices/012_spatial_dungeon_map_v1.md`
- `slices/013_locked_door_key_use_v1.md`
- `slices/014_dungeon_hazard_outcome_contract_v1.md`
- `slices/015_dungeon_light_and_oil_v1.md`
- `slices/016_dungeon_rubble_pickaxe_v1.md`
- `slices/017_dungeon_trap_tools_v1.md`
- `slices/018_dungeon_debuff_table_v1.md`
- `slices/019_dungeon_combat_modifier_bridge_v1.md`
- `slices/020_dungeon_event_presentation_v1.md`

## Milestones

- `milestones/001_dungeon_exploration_foundation.md`

## Current Status

Dungeon mode has an initial data contract, an abstract debug view, a deterministic state model, and the first domain-level combat result transition.

The next implementation step is improving exploration presentation beyond the temporary graph HUD while preserving the existing dungeon state and combat bridge. Longer term, dungeon mode should gain its own resource-pressure systems such as light, oil, tools, supplies, corridor hazards, and negative traversal events.
