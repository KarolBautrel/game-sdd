# Dungeon Specs

Dungeon specs describe the exploration layer that connects authored rooms, corridor movement, expedition supplies, corridor hazards, encounter triggers, rewards, and tactical combat transitions.

## Implemented Snapshot

Dungeon mode is currently a playable debug-stage exploration loop. It can start from an authored Old Mine dungeon or a generated Old Mine draft, show the dungeon map, move through connected rooms, resolve corridor hazards and room events, enter combat, return from combat, claim rewards, finish the expedition, and produce a stable run-result payload for a future world-map return.

The implemented foundation includes:

- an authored dungeon data contract with validated room and corridor graphs;
- a deterministic `DungeonStateModel` for movement, visited rooms, cleared rooms, pending combat, pending room events, rewards, hazards, supplies, effects, and run completion;
- a `DungeonRunSession` bridge that hands dungeon combat requests to combat and consumes combat/result/run-return payloads;
- a debug dungeon scene with preparation, source selection, generated seed/difficulty controls, map view, resource tray, event popups, room panels, numbered exits, combat entry, reward claiming, finish flow, and post-run summary;
- reusable corridor hazard catalogues and weighted hazard pools;
- reusable room event catalogues and weighted room event pools;
- generated dungeon drafts selected from curated finite Old Mine templates with seed-driven hazard and room-event placement;
- current visible expedition resources: torch oil, pickaxe, bandages, antidote, camping kit, and food;
- expedition loadout capacity with packing points and carried-only supply candidates;
- first camping action that consumes a camping kit, reduces accumulated HP loss, clears dungeon debuffs, and costs light;
- persistent dungeon effects/debuffs that can affect later traversal and combat launch metadata;
- run inventory and loot resolution that separate temporary run loot from future durable inventory integration;
- stable entry selection, generated profile selection, and run-result payload contracts for future world/global-map integration.

## Current Boundaries

Dungeon mode owns exploration pressure inside the expedition: carried supplies, light, corridor hazards, room events, temporary run loot, persistent expedition effects, and combat handoff metadata.

Dungeon mode does not own the wider supply economy. Buying, pricing, crafting, restocking, and long-term ownership of supplies belong to future town, world-map, and inventory systems. Dungeon now owns only the carried loadout capacity and in-expedition supply use; future supply work should focus on balance and integration with real inventory availability.

Combat remains a separate domain. Dungeon can launch combat with context and consume combat results, but combat still owns tactical legality, turn resolution, damage, victory, and defeat.

## Current Entry Points

- Debug dungeon scene: `scenes/dungeon/DungeonDebug.tscn`
- Main dungeon domain model: `scripts/domain/dungeon_state_model.gd`
- Dungeon entry payload helper: `scripts/domain/dungeon_entry_selection.gd`
- Dungeon session bridge: `scripts/session/dungeon_run_session.gd`
- Authored reference dungeon: `resources/data/dungeons/dungeon_old_mine.json`
- Generated template pool: `resources/data/dungeon_templates/generated_old_mine_templates.json`
- Corridor hazard catalogue and pools: `resources/data/dungeon_events/`, `resources/data/dungeon_event_pools/`
- Room event catalogue and pools: `resources/data/dungeon_room_events/`, `resources/data/dungeon_room_event_pools/`

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
- `overview/029_dungeon_beta_combat_loop_v1.md`
- `overview/030_stable_dungeon_entry_selection_v1.md`
- `overview/031_dungeon_run_result_world_return_v1.md`
- `overview/032_dungeon_inventory_loot_resolution_v2.md`
- `overview/033_room_event_system_v2.md`
- `overview/034_room_event_outcomes_v2.md`
- `overview/035_corridor_hazard_variety_v2.md`
- `overview/036_expedition_loadout_capacity_v2.md`
- `overview/037_recovery_and_camping_v1.md`
- `overview/038_generated_dungeon_profiles_v1.md`

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
- `slices/036_dungeon_beta_combat_loop_v1.md`
- `slices/037_stable_dungeon_entry_selection_v1.md`
- `slices/038_dungeon_run_result_world_return_v1.md`
- `slices/039_dungeon_inventory_loot_resolution_v2.md`
- `slices/040_room_event_system_v2.md`
- `slices/041_room_event_outcomes_v2.md`
- `slices/042_corridor_hazard_variety_v2.md`
- `slices/043_expedition_loadout_capacity_v2.md`
- `slices/044_recovery_and_camping_v1.md`
- `slices/045_generated_dungeon_profiles_v1.md`

## Milestones

- `milestones/001_dungeon_exploration_foundation.md`

## Current Status

Dungeon mode has moved beyond a pure graph prototype into a debug-playable beta foundation. It has a data contract, deterministic state model, debug presentation, reusable hazard/event content, generated dungeon templates/profiles, combat handoff, run inventory, end-of-run result payloads, and the first resource-pressure systems.

The current dungeon presentation has a first vertical slice: preparation panel, packing-point loadout, resource tray, framed map, hazard markers, legend, and player-facing route copy. Corridor hazards support reusable catalogue templates, weighted event pools through `hazard_pool_refs`, varied rubble/trap/darkness/noise/blockage families, a procedural corridor-plan helper, template-pool generated dungeon drafts, and a stable entry payload for authored/generated/profile source selection. Room exploration has reusable room event catalogues, expanded room event families, room event history, supply-gated room choices, weighted room outcomes, room event pools, pending room-event choices, and debug popup presentation. The dungeon-combat session bridge returns readable post-combat feedback for normal victories, guarded reward victories, and defeats. Dungeon completion produces a stable run-result payload with claimed rewards, kept/lost loot resolution, persistent effects, and a next-scene return hook.

The next planned dungeon-owned work is `Generated Template Pool Expansion`: growing curated finite layouts and pacing rules before broader encounter/profile variety.
