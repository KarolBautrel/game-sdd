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
- `overview/019_dungeon_party_targeting_v1.md`
- `overview/020_dungeon_supply_loadout_v1.md`
- `overview/021_dungeon_reusable_event_catalogue_v1.md`
- `overview/022_dungeon_event_pools_v1.md`
- `overview/023_dungeon_procedural_corridor_plan_v1.md`
- `overview/024_dungeon_procedural_draft_v1.md`
- `overview/025_dungeon_procedural_generation_v1.md`
- `overview/026_dungeon_template_pool_generation_v1.md`
- `overview/027_dungeon_effect_recovery_v1.md`
- `overview/028_dungeon_reusable_room_events_v1.md`

### Presentation

- `presentation/003_dungeon_debug_view_v1.md`
- `presentation/006_dungeon_exploration_scene_v1.md`
- `presentation/007_dungeon_exploration_hud_v1.md`
- `presentation/008_dungeon_exit_navigation_v1.md`
- `presentation/010_dungeon_post_run_summary_v1.md`
- `presentation/011_spatial_dungeon_map_v1.md`
- `presentation/012_dungeon_event_presentation_v1.md`
- `presentation/013_dungeon_presentation_vertical_slice_v1.md`
- `presentation/014_dungeon_debug_generated_toggle_v1.md`
- `presentation/015_dungeon_debug_generator_controls_v1.md`
- `presentation/016_dungeon_room_event_presentation_v1.md`

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
- `slices/021_dungeon_combat_modifier_effects_v1.md`
- `slices/022_dungeon_party_targeting_v1.md`
- `slices/023_dungeon_supply_loadout_v1.md`
- `slices/024_dungeon_presentation_vertical_slice_v1.md`
- `slices/025_dungeon_reusable_event_catalogue_v1.md`
- `slices/026_dungeon_event_pools_v1.md`
- `slices/027_dungeon_procedural_corridor_plan_v1.md`
- `slices/028_dungeon_procedural_draft_v1.md`
- `slices/029_dungeon_debug_generated_toggle_v1.md`
- `slices/030_dungeon_procedural_generation_v1.md`
- `slices/031_dungeon_template_pool_generation_v1.md`
- `slices/032_dungeon_debug_generator_controls_v1.md`
- `slices/033_dungeon_effect_recovery_v1.md`
- `slices/034_dungeon_reusable_room_events_v1.md`
- `slices/035_dungeon_room_event_presentation_v1.md`

## Milestones

- `milestones/001_dungeon_exploration_foundation.md`

## Current Status

Dungeon mode has an initial data contract, an abstract debug view, a deterministic state model, and the first domain-level combat result transition.

The current dungeon presentation has a first vertical slice: preparation panel, resource tray, framed map, hazard markers, legend, and player-facing route copy. Corridor hazards now support reusable catalogue templates, weighted event pools through `hazard_pool_refs`, a procedural corridor-plan helper, template-pool generated dungeon drafts, and a preparation-time debug toggle/reroll for switching between authored and generated dungeon data. Room exploration now has reusable room event catalogues, room event pools, pending room-event choices, and debug popup presentation. Longer term, dungeon mode should replace debug party formation data with a real roster, persistent party progression, beta combat-loop integration, and final art assets.
