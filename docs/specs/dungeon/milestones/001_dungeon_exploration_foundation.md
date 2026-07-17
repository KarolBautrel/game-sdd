# Milestone 001: Dungeon Exploration Foundation

Status: active
Date: 2026-07-15

## Summary

Dungeon exploration is the planned gameplay phase that connects authored rooms, corridor traversal, room content, combat transitions, and post-combat rewards.

The target feel is an authored dungeon-crawler exploration layer: the party moves through corridors between room checkpoints, manages expedition pressure, resolves authored room content, and switches into tactical combat when a room contains enemies.

Long term, dungeon exploration should have its own mechanics rather than being only room-to-room navigation. The party should bring supplies, spend resources, and face corridor hazards or negative events when it lacks the right preparation.

## Current State

- Dungeon specs exist.
- Dungeon data contract v1 is implemented.
- `dungeon_old_mine` is authored as a small room/corridor graph.
- `DungeonDebug.tscn` renders the authored dungeon as an abstract graph.
- Dungeon state model v1 tracks current room, visited rooms, cleared empty rooms, and pending combat requests.
- Dungeon combat transition v1 consumes combat result payloads, clears victorious combat rooms, and unlocks guarded rewards.
- Dungeon exploration scene v1 can start combat from a pending dungeon room and return after combat result.
- Combat now exposes the stable result payload dungeon needs to consume after a battle.
- Dungeon exploration HUD v1 replaces raw state diagnostics with a cleaner player-facing room panel and a single visible combat entry action.
- Dungeon HUD now has a visible expedition progress line and a stronger framed current-room panel, so the change is apparent in the running scene rather than only in text copy.
- Combat debug now exposes a `Debug Win` button, making dungeon-combat-dungeon loop testing faster without manually playing out every battle.
- Dungeon HUD now exposes numbered exit commands and supports number-key room traversal.
- Dungeon state now supports one-time reward claiming for treasure and guarded treasure reward stubs.
- Dungeon state now supports first-pass exit-room completion through `Finish Expedition`.
- Dungeon completion now shows a post-run summary in the HUD.
- Dungeon reward claims now aggregate run XP, gold, and item totals.
- Dungeon graph presentation now includes room-type markers, room positions, and stateful exit hints.
- `dungeon_old_mine` now has a locked `Sealed Armory` room opened by the claimed `rusty_key`.
- Dungeon design direction now explicitly includes expedition resources, light pressure, tools, corridor hazards, and negative traversal events as planned future mechanics.
- Dungeon state now has a shared corridor hazard outcome contract with deterministic structured traversal events.
- Dungeon state now tracks expedition light, lamp oil, pickaxe supplies, hazard log, and first-pass exploration modifiers.
- `dungeon_old_mine` now includes a rubble hazard on the cache corridor that is safely resolved with `pickaxe` or produces HP/debuff consequences without one.
- Dungeon HUD now shows light, oil, pickaxe count, last corridor/hazard feedback, and exposes a `Use Oil` action when the lamp is not full.
- Corridor hazards now stop traversal before the target room and require a player choice in a debug popup, so rubble/traps-style events happen between rooms rather than as room content.
- Dungeon debuffs now have a validated data catalogue and active run-state stack summary.
- `dungeon_old_mine` now includes a needle trap corridor hazard before `Spider Nest`, mitigated by carried trap tools or resolved through `poisoned`.
- Corridor event presentation now uses a custom debug event panel with hazard type, corridor endpoints, supply availability, and choice buttons.
- Hazard outcomes now support weighted variants and party slot targets for HP/debuff effects.
- Dungeon combat launch metadata now carries `dungeon_modifiers` into combat encounters, including light, party effects, target effects, and active debuffs.
- Dungeon combat launch now applies first supported modifier effects: enemy initiative bonus, party HP loss, limping MP penalty, and bleeding starting status.
- Dungeon debuffs and target effects now persist across ordinary traversal/backtracking until an explicit future removal system, end-of-run flow, or reset clears them.
- Dungeon hazard targets now use `party_slot_front` plus `party_formation` metadata instead of new data depending on the temporary `party_member_0` stub.
- Dungeon debug flow now has an explicit supply loadout step before expedition start.
- Dungeon presentation now has a first vertical slice with a framed map surface, resource tray, map legend, route state copy, and corridor hazard markers.
- Dungeon corridor hazards now support reusable catalogue templates through `hazard_refs`; `Old Mine` uses reusable rubble and trap templates.
- Dungeon corridors now support weighted `hazard_pool_refs`; `Old Mine` materializes rubble/trap through reusable event pools.
- Dungeon now has a first procedural corridor-plan helper that selects reusable hazard pools by corridor tags and danger bands.
- Dungeon now has a first generated dungeon-shaped draft that uses corridor plans and can enter the existing state model.
- Dungeon debug now exposes a preparation-time source toggle for switching between authored Old Mine and the generated draft.
- Generated dungeon drafts now use seed and difficulty to produce variable layouts and can be rerolled from the debug preparation panel.
- Generated dungeon drafts now select from a curated pool of five finite Old Mine templates, while rubble/trap corridor hazards are still generated through reusable event pools.
- Generated template hazards now choose one low-danger rubble candidate and one high-danger trap candidate per seed instead of attaching hazards to every marked corridor.
- Generated template hazards now assign rubble/trap pool types by seed across all planned candidates, so the same candidate corridor can receive rubble in one run and trap in another.
- Dungeon debug preparation now exposes generated difficulty controls, seed, room/corridor counts, and hazard count as debug-only generator metadata.
- Dungeon state now supports `remedy_kit` recovery supplies that clear persistent dungeon debuffs without restoring HP loss.
- Dungeon debug generated map layout now recalculates graph scale after source/seed/difficulty changes and shrinks room blocks for dense D3 templates so rooms remain inside the map frame.
- Dungeon room exploration now supports reusable room event catalogues and weighted room event pools.
- `Old Mine` now has a first authored room event in `Dusty Crossing`, shown through the debug event popup and resolved before further actions.
- Generated Old Mine templates now attach seed-driven room event pool refs to eligible rooms, separate from corridor trap/rubble generation.
- Dungeon combat return now stores readable session feedback for normal victories, guarded reward victories, and defeats so the dungeon scene explains the result after returning from combat.
- Dungeon entry selection now has a stable payload contract for authored/generated source, generated seed, and generated difficulty; the debug preparation panel rebuilds previews from that payload instead of owning the entry contract directly.
- Dungeon run completion now produces a stable `dungeon_run_result` payload with outcome, claimed rewards, persistent effects, and a next-scene return hook stored on the dungeon session.
- Dungeon loot resolution now separates claimed run loot into `run_inventory` and marks end-of-run payload rewards as kept or lost with an `inventory_delta` for future durable inventory integration.
- Room event system now supports expanded reusable event families and records run-level room event history by event id, type, and tag.
- Room event outcomes now support supply-gated choices, outcome tone, weighted risk examples, party-targeted consequences through existing consequence targeting, and future-facing skill-check metadata.
- Corridor hazards now support varied rubble, trap, darkness, noise, and blockage families, including traversal-blocking outcomes and darkness hazards that use lamp oil through the existing supply-choice flow.
- Expedition loadout now uses packing capacity and per-supply packing costs, so the party cannot carry every supply candidate at once.
- Dungeon state now supports a first `camping_kit` camp action that reduces accumulated dungeon HP loss, clears active dungeon debuffs, consumes a kit, and costs light.
- Generated dungeon entry now supports named profiles: `short_mine`, `medium_mine`, and `deep_mine`, while still using the curated Old Mine template pool.
- Generated Old Mine templates now declare profile ownership and pacing metadata, and each generated mine profile has at least three selectable curated layouts.
- Generated dungeon combat rooms now select presentation-ready combat encounters from a validated Old Mine pool by seed, profile, difficulty, and room kind.
- Tactical combat map selection now has explicit design rules for coherent floors, believable blockers, readable cover, justified high ground, and worldbuilding-driven tactical spaces.
- Dungeon HUD now uses dedicated semantic pixel-art icons for carried resources and core room markers instead of temporary indexed atlas reuse.
- Resource balance now tightens Old Mine and generated profile packing capacity, gives bandages an HP-loss recovery use, and makes camping consume food as well as a camping kit.

## Implemented Capability Summary

The milestone currently delivers a debug-playable dungeon exploration foundation rather than only isolated data contracts. The party can enter a dungeon from a stable entry payload, explore an authored or generated room/corridor graph, resolve corridor hazards, resolve room events, launch combat from dungeon rooms, return from combat with readable feedback, claim rewards, finish or fail a run, and produce a structured return payload for future world-map integration.

Implemented capability groups:

- **Dungeon data and state:** validated dungeon schemas, authored Old Mine data, deterministic room/corridor traversal, visited/cleared room tracking, room content state, pending combat state, pending room-event state, completion state, retreat/failure payloads, and run-result summaries.
- **Presentation and debug flow:** `DungeonDebug.tscn`, preparation/loadout step, authored/generated source toggle, seed/difficulty/reroll controls, framed map view, room markers, route copy, resource tray, numbered exits, event popup choices, combat entry action, reward claim action, finish expedition action, and post-run HUD summary.
- **Combat boundary:** dungeon creates combat launch requests, combat returns stable result payloads, victories clear combat rooms or unlock guarded rewards, defeats keep rooms dangerous, and post-combat feedback is stored through `DungeonRunSession`.
- **Expedition resources:** light, torch oil, pickaxe, trap tools, bandages, camping kit, food, persistent debuffs/effects, targetable party consequences, and combat launch metadata influenced by dungeon state.
- **Corridor hazards:** reusable hazard catalogues, weighted event pools, hazard pool refs, rubble/trap/darkness/noise/blockage families, traversal-blocking outcomes, supply-mitigated choices, weighted consequences, and structured hazard logs.
- **Room events:** reusable room-event catalogues, weighted room-event pools, expanded event families, pending room choices, supply-gated choices, weighted outcomes, tone metadata, future skill-check metadata, reward/supply/effect consequences, and run-level room-event history.
- **Loadout and camping:** packing-point loadout capacity, per-supply packing costs, carried-only supply candidates, camping kit usage, HP-loss recovery, debuff clearing, and camp light cost.
- **Icon coverage:** dedicated processed dungeon HUD icons for torch oil, pickaxe, trap tools, bandage, camping kit, food, gold, light states, hazards, room events, treasure, combat, exits, and locked rooms.
- **Generated dungeons:** curated finite Old Mine template pool, seed/difficulty/profile-based template selection, generated graph drafts that enter the same state model, seed-driven hazard candidate placement, seed-driven room event pool placement, and debug preview metadata.
- **Run loot and return:** run inventory for claimed XP/gold/items, kept/lost loot resolution, `inventory_delta`, persistent effects in the return payload, and a `next_scene` hook for future global-map/world return.

Current explicit boundaries:

- Dungeon owns only carried expedition supplies and their in-dungeon use/loss. Buying, pricing, crafting, restocking, and long-term ownership of supplies are future town/world/inventory responsibilities.
- Dungeon still uses debug party formation and debug presentation chrome.
- Generated dungeons use curated finite templates, not full free-form procedural generation.
- Combat encounter selection is still early and should later become dungeon/theme/difficulty-aware.
- Final art, production UI skin, persistent roster, durable inventory application, and town/global-map integration are not part of the completed foundation yet.

## Owning Specs

```text
docs/specs/dungeon/overview/000_dungeon_exploration_loop.md
docs/specs/dungeon/overview/001_dungeon_combat_boundary.md
docs/specs/dungeon/overview/002_dungeon_data_contract_v1.md
docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md
docs/specs/dungeon/overview/004_dungeon_state_model_v1.md
docs/specs/dungeon/overview/005_dungeon_combat_transition_v1.md
docs/specs/dungeon/presentation/006_dungeon_exploration_scene_v1.md
docs/specs/dungeon/presentation/007_dungeon_exploration_hud_v1.md
docs/specs/dungeon/presentation/008_dungeon_exit_navigation_v1.md
docs/specs/dungeon/overview/008_dungeon_reward_claim_v1.md
docs/specs/dungeon/overview/009_dungeon_exit_completion_v1.md
docs/specs/dungeon/presentation/010_dungeon_post_run_summary_v1.md
docs/specs/dungeon/overview/010_dungeon_run_inventory_v1.md
docs/specs/dungeon/presentation/011_spatial_dungeon_map_v1.md
docs/specs/dungeon/overview/011_locked_door_key_use_v1.md
docs/specs/dungeon/overview/012_dungeon_expedition_resources_v1.md
docs/specs/dungeon/overview/013_dungeon_hazard_outcome_contract_v1.md
docs/specs/dungeon/overview/014_dungeon_light_and_oil_v1.md
docs/specs/dungeon/overview/015_dungeon_rubble_pickaxe_v1.md
docs/specs/dungeon/overview/016_dungeon_trap_tools_v1.md
docs/specs/dungeon/overview/017_dungeon_debuff_table_v1.md
docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md
docs/specs/dungeon/overview/019_dungeon_party_targeting_v1.md
docs/specs/dungeon/overview/020_dungeon_supply_loadout_v1.md
docs/specs/dungeon/overview/021_dungeon_reusable_event_catalogue_v1.md
docs/specs/dungeon/overview/022_dungeon_event_pools_v1.md
docs/specs/dungeon/overview/023_dungeon_procedural_corridor_plan_v1.md
docs/specs/dungeon/overview/024_dungeon_procedural_draft_v1.md
docs/specs/dungeon/overview/025_dungeon_procedural_generation_v1.md
docs/specs/dungeon/overview/026_dungeon_template_pool_generation_v1.md
docs/specs/dungeon/overview/027_dungeon_effect_recovery_v1.md
docs/specs/dungeon/overview/028_dungeon_reusable_room_events_v1.md
docs/specs/dungeon/overview/029_dungeon_beta_combat_loop_v1.md
docs/specs/dungeon/overview/030_stable_dungeon_entry_selection_v1.md
docs/specs/dungeon/overview/031_dungeon_run_result_world_return_v1.md
docs/specs/dungeon/overview/032_dungeon_inventory_loot_resolution_v2.md
docs/specs/dungeon/overview/033_room_event_system_v2.md
docs/specs/dungeon/overview/034_room_event_outcomes_v2.md
docs/specs/dungeon/overview/035_corridor_hazard_variety_v2.md
docs/specs/dungeon/overview/036_expedition_loadout_capacity_v2.md
docs/specs/dungeon/overview/037_recovery_and_camping_v1.md
docs/specs/dungeon/overview/038_generated_dungeon_profiles_v1.md
docs/specs/dungeon/overview/039_generated_template_pool_expansion_v1.md
docs/specs/dungeon/overview/040_dungeon_combat_encounter_selection_v1.md
docs/specs/dungeon/overview/041_resource_balance_pass_v1.md
docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md
docs/specs/dungeon/presentation/013_dungeon_presentation_vertical_slice_v1.md
docs/specs/dungeon/presentation/014_dungeon_debug_generated_toggle_v1.md
docs/specs/dungeon/presentation/015_dungeon_debug_generator_controls_v1.md
docs/specs/dungeon/presentation/016_dungeon_room_event_presentation_v1.md
docs/specs/dungeon/presentation/017_pixel_art_dungeon_ui_assets_v1.md
```

Related combat owner:

```text
docs/specs/combat/overview/082_combat_result_contract_v1.md
```

## Ordered Dungeon Queue

1. **Done - Combat Result Contract V1**
   - Owner spec: `docs/specs/combat/overview/082_combat_result_contract_v1.md`
   - Slice: `docs/specs/combat/slices/082_combat_result_contract.md`
   - Goal: combat can return victory/defeat, surviving player summaries, defeated enemy ids, and reward-shaped data.
   - Proof: Python and Godot combat slice tests.

2. **Done - Dungeon Data Contract V1**
   - Goal: define authored dungeon graph data.
   - Expected data:
     - dungeon id;
     - rooms;
     - corridors;
     - start room;
     - room content entries;
     - combat encounter references;
     - reward payloads.
   - Expected files:
     - `resources/schemas/dungeon_run.schema.json` or similar;
     - one minimal reference dungeon in `resources/data/dungeons/`.
   - Proof: schema validation through `python tools/validators/validate_all.py`.

3. **Done - Dungeon Debug View V1**
   - Goal: make the first visible dungeon exploration screen.
   - Owner spec: `docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md`
   - Slice: `docs/specs/dungeon/slices/002_dungeon_debug_view_v1.md`
   - Implementation:
     - `scenes/dungeon/DungeonDebug.tscn`
     - `scripts/presentation/dungeon_debug.gd`
   - Proof: Godot headless project load plus manual UI verification gap.

4. **Done - Dungeon State Model V1**
   - Goal: create a small deterministic model for current room, visited rooms, cleared rooms, and pending combat request.
   - Owner spec: `docs/specs/dungeon/overview/004_dungeon_state_model_v1.md`
   - Slice: `docs/specs/dungeon/slices/003_dungeon_state_model_v1.md`
   - Expected behavior:
     - enter adjacent room;
     - reject non-adjacent movement;
     - expose room content;
     - mark combat room pending when enemies are present.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`.

5. **Done - Dungeon Combat Transition V1**
   - Goal: prove dungeon can launch a combat request and consume a combat result payload.
   - Owner spec: `docs/specs/dungeon/overview/005_dungeon_combat_transition_v1.md`
   - Slice: `docs/specs/dungeon/slices/004_dungeon_combat_transition_v1.md`
   - Expected behavior:
     - combat room creates an encounter request;
     - victory clears the room;
     - guarded reward becomes available;
     - defeat does not clear the room.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`.

6. **Done - Dungeon Exploration Scene V1**
   - Goal: build the first usable dungeon exploration scene.
   - Owner spec: `docs/specs/dungeon/presentation/006_dungeon_exploration_scene_v1.md`
   - Slice: `docs/specs/dungeon/slices/005_dungeon_exploration_scene_v1.md`
   - Expected behavior:
     - render room/corridor graph;
     - move between connected rooms;
     - show current room content state;
     - transition into combat scene for combat rooms;
     - return after combat result.
   - Proof: Godot headless load, dungeon state tests, session bridge tests, and manual UI verification gap for click-through.

7. **Done - Dungeon Exploration HUD V1**
   - Goal: replace raw debug readouts with a cleaner player-facing exploration panel.
   - Owner spec: `docs/specs/dungeon/presentation/007_dungeon_exploration_hud_v1.md`
   - Slice: `docs/specs/dungeon/slices/006_dungeon_exploration_hud_v1.md`
   - Expected behavior:
     - current room panel shows room, state, content, exits, rewards, and short feedback;
     - header shows visited rooms, secured rooms, and unlocked rewards;
     - pending combat rooms show one visible `Enter Combat` action;
     - raw visited, cleared, dungeon id, and pending encounter path diagnostics are not shown in the HUD;
     - manual `Resolve Victory` and `Resolve Defeat` controls are removed from the visible exploration HUD.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd`, Godot headless scene load, dungeon state tests, and session bridge tests.

8. **Done - Dungeon Exit Navigation V1**
   - Goal: expose connected rooms as explicit HUD exit commands and support number-key traversal.
   - Owner spec: `docs/specs/dungeon/presentation/008_dungeon_exit_navigation_v1.md`
   - Slice: `docs/specs/dungeon/slices/007_dungeon_exit_navigation_v1.md`
   - Expected behavior:
     - connected rooms appear as numbered exit commands;
     - number keys 1-9 trigger matching exit slots;
     - graph click navigation remains available.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd`.

9. **Done - Dungeon Reward Claim V1**
   - Goal: claim treasure and guarded treasure into dungeon-run state as a progression/inventory stub.
   - Owner spec: `docs/specs/dungeon/overview/008_dungeon_reward_claim_v1.md`
   - Slice: `docs/specs/dungeon/slices/008_dungeon_reward_claim_v1.md`
   - Expected behavior:
     - treasure can be claimed once;
     - guarded treasure requires combat victory unlock;
     - claimed reward rooms are tracked and marked cleared.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

10. **Done - Dungeon Exit Completion V1**
   - Goal: expose a first explicit completion action in authored exit rooms.
   - Owner spec: `docs/specs/dungeon/overview/009_dungeon_exit_completion_v1.md`
   - Slice: `docs/specs/dungeon/slices/009_dungeon_exit_completion_v1.md`
   - Expected behavior:
     - exit rooms expose `Finish Expedition`;
     - completion is stored in dungeon state;
     - non-exit completion is rejected.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

11. **Done - Dungeon Post-Run Summary V1**
   - Goal: show completion, visited/secured rooms, and claimed rewards after `Finish Expedition`.
   - Owner spec: `docs/specs/dungeon/presentation/010_dungeon_post_run_summary_v1.md`
   - Slice: `docs/specs/dungeon/slices/010_dungeon_post_run_summary_v1.md`
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd`.

12. **Done - Dungeon Run Inventory V1**
   - Goal: aggregate claimed XP, gold, and item ids in dungeon run state.
   - Owner spec: `docs/specs/dungeon/overview/010_dungeon_run_inventory_v1.md`
   - Slice: `docs/specs/dungeon/slices/011_dungeon_run_inventory_v1.md`
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

13. **Done - Spatial Dungeon Map V1**
   - Goal: make the abstract graph communicate authored room type and position more clearly.
   - Owner spec: `docs/specs/dungeon/presentation/011_spatial_dungeon_map_v1.md`
   - Slice: `docs/specs/dungeon/slices/012_spatial_dungeon_map_v1.md`
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd`.

14. **Done - Locked Door Key Use V1**
   - Goal: add a first item-gated room unlocked by `rusty_key`.
   - Owner spec: `docs/specs/dungeon/overview/011_locked_door_key_use_v1.md`
   - Slice: `docs/specs/dungeon/slices/013_locked_door_key_use_v1.md`
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

15. **Planned - Dungeon Expedition Resources V1**
   - Goal: make dungeon exploration its own resource-pressure layer.
   - Owner spec: `docs/specs/dungeon/overview/012_dungeon_expedition_resources_v1.md`
   - Expected future behavior:
     - party brings supplies such as lamp oil and tools;
     - corridor traversal can reduce light or trigger hazards;
     - missing supplies can cause HP loss, stress/fatigue, debuffs, ambushes, blocked paths, or other negative outcomes;
     - supplies can avoid, reduce, or alter those outcomes.
   - Proof: planned only; implementation will need schema updates, dungeon state tests, and presentation tests.

16. **Done - Dungeon Hazard Outcome Contract V1**
   - Goal: create the shared deterministic contract for all corridor hazards.
   - Owner spec: `docs/specs/dungeon/overview/013_dungeon_hazard_outcome_contract_v1.md`
   - Slice: `docs/specs/dungeon/slices/014_dungeon_hazard_outcome_contract_v1.md`
   - Implemented:
     - corridor `hazards` validate through `resources/schemas/dungeon.schema.json`;
     - `DungeonStateModel.enter_room` resolves traversal events;
     - deterministic weighted outcomes and structured consequences are recorded in `hazard_log`.
   - Proof: schema validation and `scripts/domain/dungeon_state_model_tests.gd`.

17. **Done - Dungeon Light And Oil V1**
   - Goal: add lamp light pressure and `lamp_oil` restoration.
   - Owner spec: `docs/specs/dungeon/overview/014_dungeon_light_and_oil_v1.md`
   - Slice: `docs/specs/dungeon/slices/015_dungeon_light_and_oil_v1.md`
   - Implemented:
     - run state tracks `light_level`, `light_state`, `supplies.lamp_oil`, and exploration modifiers;
     - corridor traversal reduces light;
     - `Use Oil` restores light in the debug HUD.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

18. **Done - Dungeon Rubble And Pickaxe V1**
   - Goal: add rubble corridor hazard mitigated by `pickaxe`.
   - Owner spec: `docs/specs/dungeon/overview/015_dungeon_rubble_pickaxe_v1.md`
   - Slice: `docs/specs/dungeon/slices/016_dungeon_rubble_pickaxe_v1.md`
   - Implemented:
     - `crossing_to_cache` contains `rubble_crossing_cache`;
     - `pickaxe` clears the hazard safely and is consumed;
     - missing `pickaxe` forces passage and records HP loss plus `bruised`.
     - the hazard prompts before entering the target room and requires an explicit player choice.
   - Proof: schema validation and `scripts/domain/dungeon_state_model_tests.gd`.

19. **Done - Dungeon Debuff Table V1**
   - Goal: define structured dungeon debuffs and weighted outcome mapping.
   - Owner spec: `docs/specs/dungeon/overview/017_dungeon_debuff_table_v1.md`
   - Slice: `docs/specs/dungeon/slices/018_dungeon_debuff_table_v1.md`
   - Implemented:
     - `resources/data/dungeon_debuffs/base_dungeon_debuffs.json` defines first debuff ids;
     - `resources/schemas/dungeon_debuff.schema.json` validates the catalogue;
     - dungeon hazard `apply_debuff` consequences are validated against that catalogue;
     - dungeon state stores `active_debuffs` with stacks and HUD summary.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

20. **Done - Dungeon Trap Tools V1**
   - Goal: add trap corridor hazard mitigated by `trap_tools`.
   - Owner spec: `docs/specs/dungeon/overview/016_dungeon_trap_tools_v1.md`
   - Slice: `docs/specs/dungeon/slices/017_dungeon_trap_tools_v1.md`
   - Implemented:
     - starting supplies include `trap_tools`;
     - `crossing_to_nest` contains `needle_trap_crossing_nest`;
     - `Use trap tools` consumes one tool and prevents the trap consequence;
     - `Force passage` applies HP loss and `poisoned`.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

21. **Done - Dungeon Event Presentation V1**
   - Goal: show corridor hazards as player-facing event cards with choices, supply availability, and outcomes.
   - Owner spec: `docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md`
   - Slice: `docs/specs/dungeon/slices/020_dungeon_event_presentation_v1.md`
   - Implemented:
     - corridor hazard panel appears from `choice_required`;
     - player can choose `Use pickaxe` or `Force passage`;
     - panel shows hazard type, route, text, supply availability, and decisions.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd` plus manual visual verification.

22. **Done - Dungeon Combat Modifier Bridge V1**
   - Goal: pass dungeon light/debuff/ambush consequences into combat launch metadata.
   - Owner spec: `docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md`
   - Slice: `docs/specs/dungeon/slices/019_dungeon_combat_modifier_bridge_v1.md`
   - Implemented:
     - pending combat requests carry `dungeon_modifiers`;
     - session launch metadata copies modifiers into the encounter;
     - combat debug displays a compact dungeon modifier summary;
     - combat resolver behavior remains unchanged until supported modifier effects are implemented.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/session/dungeon_run_session_tests.gd`.

23. **Done - Dungeon Combat Modifier Effects V1**
   - Goal: make the first dungeon modifiers affect combat launch state.
   - Owner spec: `docs/specs/dungeon/overview/018_dungeon_combat_modifier_bridge_v1.md`
   - Slice: `docs/specs/dungeon/slices/021_dungeon_combat_modifier_effects_v1.md`
   - Implemented:
     - enemy `initiative_bonus` modifies enemy combat unit stats;
     - `party_slot_front.hp_loss` reduces the resolved combat unit's starting HP;
     - `party_slot_front.debuffs.limping` reduces the resolved combat unit's starting MP;
     - `party_slot_front.debuffs.bleeding` applies supported combat `bleeding` status;
     - turn order is rebuilt by initiative after launch effects.
   - Proof: `scripts/session/dungeon_run_session_tests.gd`.

24. **Done - Dungeon Party Targeting V1**
   - Goal: replace new `party_member_0` hazard data with stable party formation targets.
   - Owner spec: `docs/specs/dungeon/overview/019_dungeon_party_targeting_v1.md`
   - Slice: `docs/specs/dungeon/slices/022_dungeon_party_targeting_v1.md`
   - Implemented:
     - dungeon schema supports `default_party_formation`;
     - `dungeon_old_mine` maps `party_slot_front` to `unit_player_001`;
     - rubble and trap hazard consequences target `party_slot_front`;
     - dungeon modifiers carry `party_formation` into combat launch;
     - session launch resolves party slot effects to combat units;
     - old `party_member_0` metadata remains a debug fallback.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/session/dungeon_run_session_tests.gd`.

25. **Done - Dungeon Supply Loadout V1**
   - Goal: let the player choose expedition supplies before the dungeon run starts.
   - Owner spec: `docs/specs/dungeon/overview/020_dungeon_supply_loadout_v1.md`
   - Slice: `docs/specs/dungeon/slices/023_dungeon_supply_loadout_v1.md`
   - Implemented:
     - dungeon schema supports `supply_loadout_options`;
     - `dungeon_old_mine` defines min/max/default values for oil, pickaxe, and trap tools;
     - `DungeonStateModel.initial_state` accepts selected supply loadout overrides;
     - run state records `selected_supply_loadout`;
     - debug HUD shows a preparation panel with supply steppers and `Start Expedition`;
     - reset returns to the preparation/loadout step.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

26. **Done - Dungeon Presentation Vertical Slice V1**
   - Goal: make the temporary dungeon scene read more like a playable exploration screen.
   - Owner spec: `docs/specs/dungeon/presentation/013_dungeon_presentation_vertical_slice_v1.md`
   - Slice: `docs/specs/dungeon/slices/024_dungeon_presentation_vertical_slice_v1.md`
   - Implemented:
     - framed route-map surface behind the authored room graph;
     - resource tray for light, oil, pickaxe, trap tools, and active effects;
     - route state copy for preparation, corridor events, combat-ready rooms, and exploration;
     - compact map legend;
     - corridor hazard markers such as `Rubble` and `Trap`;
     - corridor danger color pass.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd` and Godot headless dungeon scene load.

27. **Done - Dungeon Reusable Event Catalogue V1**
   - Goal: move common corridor hazards out of single-dungeon inline data and into reusable templates.
   - Owner spec: `docs/specs/dungeon/overview/021_dungeon_reusable_event_catalogue_v1.md`
   - Slice: `docs/specs/dungeon/slices/025_dungeon_reusable_event_catalogue_v1.md`
   - Implemented:
     - `resources/schemas/dungeon_event.schema.json` validates reusable event catalogues;
     - `resources/data/dungeon_events/base_corridor_hazards.json` defines `rubble_minor` and `needle_trap_basic`;
     - dungeon schema supports corridor `hazard_refs`;
     - `dungeon_old_mine` references reusable rubble/trap templates;
     - `DungeonStateModel` materializes refs into runtime hazards;
     - HUD hazard markers work for referenced hazards;
     - validator checks missing event refs, debuff refs, and party target refs.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

28. **Done - Dungeon Event Pools V1**
   - Goal: let authored/generated corridors materialize reusable hazards from weighted pools.
   - Owner spec: `docs/specs/dungeon/overview/022_dungeon_event_pools_v1.md`
   - Slice: `docs/specs/dungeon/slices/026_dungeon_event_pools_v1.md`
   - Implemented:
     - event templates support tags;
     - `resources/schemas/dungeon_event_pool.schema.json` validates event pools;
     - `resources/data/dungeon_event_pools/base_old_mine_pools.json` defines mine rubble/trap pools;
     - dungeon schema supports `hazard_pool_refs`;
     - `dungeon_old_mine` uses pool refs for rubble/trap corridor hazards;
     - `DungeonStateModel` deterministically selects and materializes pool entries;
     - validator checks missing pool ids and pool entries referencing missing event ids.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

29. **Done - Dungeon Procedural Corridor Plan V1**
   - Goal: provide the first generator-facing helper for choosing corridor hazard pools.
   - Owner spec: `docs/specs/dungeon/overview/023_dungeon_procedural_corridor_plan_v1.md`
   - Slice: `docs/specs/dungeon/slices/027_dungeon_procedural_corridor_plan_v1.md`
   - Implemented:
     - event pools support optional `danger_min` and `danger_max` bands;
     - Old Mine rubble/trap pools define low/high danger bands;
     - `DungeonStateModel.procedural_corridor_plan` selects a matching pool by required tags and corridor danger;
     - planned `hazard_pool_refs` materialize through the same runtime path as authored corridors;
     - validator rejects event pools whose danger range is inverted.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

30. **Done - Dungeon Procedural Draft V1**
   - Goal: create the first generated dungeon-shaped data draft.
   - Owner spec: `docs/specs/dungeon/overview/024_dungeon_procedural_draft_v1.md`
   - Slice: `docs/specs/dungeon/slices/028_dungeon_procedural_draft_v1.md`
   - Implemented:
     - `DungeonStateModel.procedural_dungeon_draft` returns normal dungeon data with rooms, corridors, supplies, party formation, and exit rules;
     - the draft has entrance, crossing, treasure, combat, and exit rooms;
     - low/high danger generated corridors use `procedural_corridor_plan` to receive rubble/trap pool refs;
     - generated traversal can prompt corridor hazards and create a normal pending combat request.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, `scripts/domain/dungeon_procedural_draft_tests.gd`, and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

31. **Done - Dungeon Debug Generated Toggle V1**
   - Goal: expose the generated dungeon draft in the playable debug scene.
   - Owner spec: `docs/specs/dungeon/presentation/014_dungeon_debug_generated_toggle_v1.md`
   - Slice: `docs/specs/dungeon/slices/029_dungeon_debug_generated_toggle_v1.md`
   - Implemented:
     - preparation panel can switch between authored Old Mine and Generated Draft;
     - switching source resets preparation state, selected loadout, selected room, pending corridor UI, and session data;
     - generated draft data rebuilds the graph and uses the existing state model/HUD helpers;
     - returning from combat preserves active dungeon data from the session instead of always reloading authored Old Mine.
   - Proof: schema validation, `scripts/presentation/dungeon_exploration_hud_tests.gd`, and headless `DungeonDebug.tscn` load.

32. **Done - Dungeon Procedural Generation V1**
   - Goal: make generated dungeon drafts actually vary by seed and scale by difficulty.
   - Owner spec: `docs/specs/dungeon/overview/025_dungeon_procedural_generation_v1.md`
   - Slice: `docs/specs/dungeon/slices/030_dungeon_procedural_generation_v1.md`
   - Implemented:
     - `DungeonStateModel.procedural_dungeon_draft` accepts `seed` and `difficulty`;
     - same seed/difficulty produces the same graph signature;
     - different seeds produce different graph signatures;
     - higher difficulty produces larger generated graphs in the first profile;
     - generated graphs use a main route plus treasure/combat side branches;
     - generated corridors still use `procedural_corridor_plan` for hazard pool refs;
     - debug generated source uses fresh seeds and exposes a preparation-time reroll action.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, `scripts/domain/dungeon_procedural_draft_tests.gd`, `scripts/presentation/dungeon_exploration_hud_tests.gd`, and headless `DungeonDebug.tscn` load.

33. **Done - Dungeon Template Pool Generation V1**
   - Goal: replace unstable free-form graph generation with a curated pool of finite layouts.
   - Owner spec: `docs/specs/dungeon/overview/026_dungeon_template_pool_generation_v1.md`
   - Slice: `docs/specs/dungeon/slices/031_dungeon_template_pool_generation_v1.md`
   - Implemented:
     - `resources/data/dungeon_templates/generated_old_mine_templates.json` defines five Old Mine layouts across difficulties 1-3;
     - `resources/schemas/dungeon_template.schema.json` validates the template pool;
     - `DungeonStateModel.procedural_dungeon_draft` selects a template by seed and difficulty;
     - selected templates instantiate normal dungeon rooms/corridors with finite authored graph shapes;
     - marked corridors act as hazard candidates rather than fixed hazard placements;
     - each generated seed selects hazard candidate slots and assigns rubble/trap pool types by seed;
     - different seeds can move rubble/trap refs to different corridors and can swap which corridor receives rubble versus trap;
     - debug reroll advances seed so generated layout changes within the finite template pool.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, `scripts/domain/dungeon_procedural_draft_tests.gd`, `scripts/presentation/dungeon_exploration_hud_tests.gd`, and headless `DungeonDebug.tscn` load.

34. **Done - Dungeon Debug Generator Controls V1**
   - Goal: make generated dungeon testing visible and controllable in the preparation panel without making difficulty a player-facing entry flow.
   - Owner spec: `docs/specs/dungeon/presentation/015_dungeon_debug_generator_controls_v1.md`
   - Slice: `docs/specs/dungeon/slices/032_dungeon_debug_generator_controls_v1.md`
   - Implemented:
     - generated source has debug D1/D2/D3 controls;
     - generated summary shows difficulty, seed, room count, corridor count, and hazard count;
     - reroll keeps the selected debug difficulty and changes seed;
     - generated graph blocks scale down for dense templates and transform is recalculated after source/seed/difficulty changes;
     - specs record that target-game dungeon difficulty is predefined before entering the dungeon.
   - Proof: schema validation, `scripts/presentation/dungeon_exploration_hud_tests.gd`, and headless `DungeonDebug.tscn` load.

35. **Done - Dungeon Effect Recovery V1**
   - Goal: add the first explicit removal system for persistent dungeon debuffs.
   - Owner spec: `docs/specs/dungeon/overview/027_dungeon_effect_recovery_v1.md`
   - Slice: `docs/specs/dungeon/slices/033_dungeon_effect_recovery_v1.md`
   - Implemented:
     - `remedy_kit` is available in authored and generated Old Mine loadouts;
     - `DungeonStateModel.use_recovery_supply` consumes remedy and clears active debuffs, party debuff ids, and target debuff mappings;
     - HP loss intentionally persists for future healing systems;
     - debug HUD exposes `Use Remedy` only when a debuff and remedy are available.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, `scripts/presentation/dungeon_exploration_hud_tests.gd`, and headless `DungeonDebug.tscn` load.

36. **Done - Dungeon Reusable Room Events V1**
   - Goal: add reusable exploration events that happen inside rooms rather than on corridors.
   - Owner spec: `docs/specs/dungeon/overview/028_dungeon_reusable_room_events_v1.md`
   - Slice: `docs/specs/dungeon/slices/034_dungeon_reusable_room_events_v1.md`
   - Implemented:
     - `resources/schemas/dungeon_room_event.schema.json` and `resources/schemas/dungeon_room_event_pool.schema.json`;
     - `resources/data/dungeon_room_events/base_old_mine_room_events.json` defines first room events;
     - `resources/data/dungeon_room_event_pools/base_old_mine_room_event_pools.json` defines the first weighted room event pool;
     - dungeon and template schemas allow `room_event` content entries;
     - `DungeonStateModel` tracks `pending_room_event`, `resolved_room_event_ids`, and `room_event_log`;
     - room event outcomes can apply rewards, light changes, supplies, HP loss, and debuffs through the shared consequence path;
     - generated dungeon drafts attach room event pool refs to seed-selected eligible rooms.
   - Proof: schema validation, `scripts/domain/dungeon_state_model_tests.gd`, and `scripts/domain/dungeon_procedural_draft_tests.gd`.

37. **Done - Dungeon Room Event Presentation V1**
   - Goal: show room events as explicit debug popup choices.
   - Owner spec: `docs/specs/dungeon/presentation/016_dungeon_room_event_presentation_v1.md`
   - Slice: `docs/specs/dungeon/slices/035_dungeon_room_event_presentation_v1.md`
   - Implemented:
     - debug scene reuses the event popup shell with `Room Event` copy;
     - pending room events block exits, reward claiming, combat entry, finish action, oil, and remedy until resolved;
     - detail panel, status line, and route state describe pending room events;
     - resolving a room event refreshes room cleared state and last event feedback.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd` and headless `DungeonDebug.tscn` load.

38. **Done - Dungeon Beta Combat Loop V1**
   - Goal: make returning from combat readable during the first playable dungeon beta loop.
   - Owner spec: `docs/specs/dungeon/overview/029_dungeon_beta_combat_loop_v1.md`
   - Slice: `docs/specs/dungeon/slices/036_dungeon_beta_combat_loop_v1.md`
   - Implemented:
     - `DungeonRunSession.finish_combat` now produces player-facing return feedback after accepted combat results;
     - normal victory feedback names the room, confirms it was secured, and tells the player to continue;
     - guarded treasure victory feedback names the room and summarizes the unlocked reward;
     - defeat feedback names the room and confirms the room remains dangerous.
   - Proof: `scripts/session/dungeon_run_session_tests.gd`.

## Long-Term Dungeon Roadmap

This queue captures the next agreed dungeon direction after the exploration foundation work. Treat it as the forward plan for future agents: work top-down unless a user explicitly reprioritizes, and keep the usual spec -> slice -> implementation -> proof workflow for each item.

1. **Done - Beta Dungeon-Combat Loop**
   - Goal: make one playable loop feel coherent end to end: enter dungeon, explore, hit corridor hazards, resolve room events, enter combat, return to dungeon, claim rewards, finish or reset.
   - Owner spec: `docs/specs/dungeon/overview/029_dungeon_beta_combat_loop_v1.md`
   - Slice: `docs/specs/dungeon/slices/036_dungeon_beta_combat_loop_v1.md`
   - Implemented:
     - dungeon session handoff into combat and back is covered by session tests;
     - room and corridor pending state remains owned by dungeon state before combat launch;
     - post-combat feedback is stored in `DungeonRunSession.last_feedback` for the restored dungeon scene.
   - Proof: `scripts/session/dungeon_run_session_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

2. **Done - Stable Dungeon Entry Selection**
   - Goal: move generated difficulty/seed/source out of the debug preparation panel and into a pre-entry contract.
   - Owner spec: `docs/specs/dungeon/overview/030_stable_dungeon_entry_selection_v1.md`
   - Slice: `docs/specs/dungeon/slices/037_stable_dungeon_entry_selection_v1.md`
   - Implemented:
     - `DungeonEntrySelection` normalizes authored/generated entry payloads;
     - generated seed and difficulty now live in the payload used to build preview dungeon data;
     - debug source, reroll, and difficulty controls update that payload instead of being the owning contract.
   - Proof: `scripts/domain/dungeon_entry_selection_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

3. **Done - Run Result And World Return**
   - Goal: turn `Finish Expedition` into a return payload that can be consumed by the wider game.
   - Owner spec: `docs/specs/dungeon/overview/031_dungeon_run_result_world_return_v1.md`
   - Slice: `docs/specs/dungeon/slices/038_dungeon_run_result_world_return_v1.md`
   - Implemented:
     - `DungeonStateModel.run_result_payload` creates completed, retreated, failed, and in-progress payloads;
     - exit-room completion stores a `completed` payload in dungeon state;
     - retreat and failed flows produce first contract payloads for future UI/session use;
     - `DungeonRunSession.finish_run` stores `pending_world_return_payload` and exposes a next-scene return hook;
     - post-run HUD summary shows result outcome and return hook.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`; `scripts/session/dungeon_run_session_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

4. **Done - Dungeon Inventory And Loot Resolution**
   - Goal: separate temporary run loot from durable player inventory.
   - Owner spec: `docs/specs/dungeon/overview/032_dungeon_inventory_loot_resolution_v2.md`
   - Slice: `docs/specs/dungeon/slices/039_dungeon_inventory_loot_resolution_v2.md`
   - Implemented:
     - dungeon state now tracks `run_inventory` with gold, XP, item ids, and reward records;
     - reward claims write to `run_inventory` while `reward_totals` remains a compatibility summary;
     - run result payloads include `claimed_run_inventory`, `kept_rewards`, `lost_rewards`, and `inventory_delta`;
     - completed and retreated runs keep claimed loot in this beta rule;
     - failed runs lose claimed loot while preserving persistent effects.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`; `scripts/session/dungeon_run_session_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

5. **Done - Room Event System V2**
   - Goal: expand room content beyond the first shrine/stash examples.
   - Owner spec: `docs/specs/dungeon/overview/033_room_event_system_v2.md`
   - Slice: `docs/specs/dungeon/slices/040_room_event_system_v2.md`
   - Implemented:
     - room event schema now accepts chest, locked chest, corpse, note, curio, blocked object, hidden cache, and generic event families;
     - Old Mine room event catalogue now includes chest, corpse, note, curio, and hidden-cache examples;
     - Old Mine room event pool references the expanded catalogue;
     - dungeon state records `room_event_history` with resolved count, event ids, type counts, and tag counts;
     - HUD last room event feedback includes the resolved-event count.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

6. **Done - Room Event Outcomes V2**
   - Goal: make room event choices tactically interesting.
   - Owner spec: `docs/specs/dungeon/overview/034_room_event_outcomes_v2.md`
   - Slice: `docs/specs/dungeon/slices/041_room_event_outcomes_v2.md`
   - Implemented:
     - room event choices may declare `requires_supply`, and unavailable choices are rejected by the domain model;
     - room event outcomes may declare `tone` as positive, neutral, or negative;
     - weighted outcomes are used for risky curio inspection;
     - skill-check metadata is accepted and preserved for future roster/stat resolution;
     - room event logs and history count outcome tone;
     - HUD room event panel summarizes missing/available required supplies.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

7. **Done - Corridor Hazard Variety V2**
   - Goal: broaden traversal pressure beyond the first rubble/trap examples.
   - Owner spec: `docs/specs/dungeon/overview/035_corridor_hazard_variety_v2.md`
   - Slice: `docs/specs/dungeon/slices/042_corridor_hazard_variety_v2.md`
   - Implemented:
     - corridor hazard schemas now accept `noise` and `blockage` families in addition to rubble, trap, darkness, and generic;
     - Old Mine hazard catalogue now includes major cave-in blockage, snare trap, dark pocket, and echoing alarm hazards;
     - Old Mine pools include multiple rubble/trap entries and new darkness/noise pools;
     - major cave-in can block traversal through the existing `blocks_traversal` result contract;
     - darkness hazards can consume lamp oil through the existing `use_supply` choice flow;
     - fixed `consume_required_supply` so required supply is consumed once through the normal consequence path.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

8. **Done - Expedition Loadout Capacity V2**
   - Goal: make pre-dungeon packing choices matter without owning town/world supply economy.
   - Owner spec: `docs/specs/dungeon/overview/036_expedition_loadout_capacity_v2.md`
   - Slice: `docs/specs/dungeon/slices/043_expedition_loadout_capacity_v2.md`
   - Implemented:
     - define carry limits or expedition packing points for supplies brought into a dungeon;
     - keep buying, pricing, restocking, and persistent supply ownership in future town/world/inventory specs;
     - restrict the visible carried resource set to torch oil, pickaxe, trap tools, bandages, camping kit, and food;
     - show compact icon/count resource tiles with tooltip names and usage;
     - expose clearer loadout tradeoffs and supply consequences in UI.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

9. **Done - Recovery And Camping**
   - Goal: add an explicit in-dungeon recovery layer instead of only instant remedy usage.
   - Owner spec: `docs/specs/dungeon/overview/037_recovery_and_camping_v1.md`
   - Slice: `docs/specs/dungeon/slices/044_recovery_and_camping_v1.md`
   - Implemented:
     - `camping_kit` is a carried supply candidate;
     - camp action consumes one kit;
     - camp reduces accumulated dungeon HP loss;
     - camp clears active dungeon debuffs;
     - camp costs one light level;
     - camp is blocked while combat, corridor hazards, or room events are pending.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

10. **Done - Generated Dungeon Profiles**
    - Goal: make generated dungeons select from named profiles rather than only difficulty.
    - Owner spec: `docs/specs/dungeon/overview/038_generated_dungeon_profiles_v1.md`
    - Slice: `docs/specs/dungeon/slices/045_generated_dungeon_profiles_v1.md`
    - Implemented:
      - `short_mine`, `medium_mine`, and `deep_mine` profiles;
      - generated entry payload preserves `generated_profile`;
      - profile metadata is exposed on generated dungeon drafts;
      - profiles set first beta difficulty, light budget, and loadout capacity;
      - debug difficulty buttons act as profile shortcuts.
    - Proof: `scripts/domain/dungeon_entry_selection_tests.gd`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

11. **Done - Generated Template Pool Expansion**
    - Goal: grow curated finite layouts before returning to freer procedural generation.
    - Owner spec: `docs/specs/dungeon/overview/039_generated_template_pool_expansion_v1.md`
    - Slice: `docs/specs/dungeon/slices/046_generated_template_pool_expansion_v1.md`
    - Implemented:
      - template schema requires `profile_ids` and `pacing`;
      - `short_mine`, `medium_mine`, and `deep_mine` each have at least three selectable Old Mine layouts;
      - generated template selection filters by requested profile before difficulty fallback;
      - generated dungeon output exposes selected template id, display name, and pacing metadata;
      - added authored pacing rules for route length, branch count, treasure count, combat count, room-event slots, and corridor-hazard candidates.
    - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/domain/dungeon_state_model_tests.gd`; headless `DungeonDebug.tscn` load.

12. **Done - Combat Encounter Selection Per Dungeon**
    - Goal: stop using one debug encounter for every dungeon combat room.
    - Owner spec: `docs/specs/dungeon/overview/040_dungeon_combat_encounter_selection_v1.md`
    - Slice: `docs/specs/dungeon/slices/047_dungeon_combat_encounter_selection_v1.md`
    - Implemented:
      - `combat_encounter_pool_id` is valid on dungeon/template combat content;
      - `old_mine_generated_combat_pool` validates through schema and references presentation-ready combat encounters;
      - generated template combat rooms select encounter refs deterministically by seed, profile, difficulty, and room kind;
      - explicit authored `combat_encounter_path` remains supported as a manual pin;
      - pending combat requests include selected encounter path plus pool/entry/tactical-role metadata;
      - tactical map design rules are documented for coherent floors, believable blockers, readable cover, justified high ground, and worldbuilding-driven encounter spaces.
    - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_procedural_draft_tests.gd`; `scripts/domain/dungeon_state_model_tests.gd`; headless `DungeonDebug.tscn` load.

13. **Done - Pixel-Art Dungeon UI Assets**
    - Goal: create or integrate small readable pixel-art UI assets for dungeon play.
    - Owner spec: `docs/specs/dungeon/presentation/017_pixel_art_dungeon_ui_assets_v1.md`
    - Slice: `docs/specs/dungeon/slices/048_pixel_art_dungeon_ui_assets_v1.md`
    - Implemented:
      - torch oil, pickaxe, trap tools, bandage, camping kit, food, gold, light state, room event, trap, and rubble icons;
      - dedicated icon coverage for each compact resource tile instead of temporary atlas reuse;
      - exported semantic PNG assets under `assets/ui/dungeon/processed/icons/`;
      - green atlas background cleanup with no visible green pixels remaining;
      - HUD resource and room icon paths now use semantic dedicated files.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd` and green-pixel scan.

14. **In Progress - Playable Dungeon Beta**
    - Goal: ship one coherent beta dungeon pass for hands-on testing.
    - First beta step spec: `docs/specs/dungeon/overview/042_playable_generated_beta_party_v1.md`
    - First beta step slice: `docs/specs/dungeon/slices/050_playable_generated_beta_party_v1.md`
    - Party roster spec: `docs/specs/dungeon/overview/043_party_roster_contract_v1.md`
    - Party roster slice: `docs/specs/dungeon/slices/051_party_roster_contract_v1.md`
    - Implemented so far:
      - debug dungeon defaults to generated medium-mine content instead of authored Old Mine;
      - authored Old Mine remains available through the source toggle;
      - dungeon state uses a two-slot beta formation: Warrior front, Archer back;
      - dungeon-launched combat encounters automatically receive the Archer and bow profile;
      - front-slot dungeon effects still resolve only to Warrior.
      - shared party roster defines Bran the Warrior and Torin the Archer;
      - dungeon HUD renders both party members from roster data instead of one hardcoded portrait;
      - combat launch and combat text resolve player visuals/names from the same roster.
    - Expected work:
      - manual smoke playthrough from generated dungeon entry;
      - verify supplies, capacity, hazards, room events, combat, rewards, and finish/return flow as one loop;
      - record bugs and tune balance from the playthrough;
      - keep combat boards data-driven until bespoke tactical maps are ready.
    - Proof target: automated smoke tests plus manual playthrough checklist.

## End-Of-Day Backlog

This checkpoint preserves the current dungeon direction after the loadout/resource UI pass. The immediate next work should stay on the established spec -> slice -> implementation -> proof workflow.

1. **Done - Resource Balance Pass**
   - Owner spec: `docs/specs/dungeon/overview/041_resource_balance_pass_v1.md`
   - Slice: `docs/specs/dungeon/slices/049_resource_balance_pass_v1.md`
   - Implemented:
     - authored Old Mine capacity tightened to 7 packing points;
     - generated profile capacities tightened to short 6, medium 7, and deep 9;
     - bandages now repair one point of dungeon HP loss;
     - camping now requires and consumes food as well as a camping kit;
     - every visible carried resource now has at least one in-dungeon use.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd` and `scripts/presentation/dungeon_exploration_hud_tests.gd`.

2. **Done - Dungeon Icon Coverage**
   - Add or process dedicated icons for the six visible carried resources.
   - Keep the compact resource tray behavior: icon plus number, tooltip for name/usage.
   - Processed semantic icons now live under `assets/ui/dungeon/processed/icons/`.
   - Proof: `scripts/presentation/dungeon_exploration_hud_tests.gd` and green-pixel scan.

3. **In Progress - Playable Generated Beta Party**
   - Owner spec: `docs/specs/dungeon/overview/042_playable_generated_beta_party_v1.md`
   - Slice: `docs/specs/dungeon/slices/050_playable_generated_beta_party_v1.md`
   - Implemented:
     - generated medium mine is the default debug entry;
     - beta party formation is Warrior plus Archer;
     - dungeon-launched combat injects Archer with bow loadout/profile;
     - authored Old Mine can still be used for fallback testing.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_entry_selection_tests.gd`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/session/dungeon_run_session_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`.

4. **Done - Party Roster Contract**
   - Owner spec: `docs/specs/dungeon/overview/043_party_roster_contract_v1.md`
   - Slice: `docs/specs/dungeon/slices/051_party_roster_contract_v1.md`
   - Implemented:
     - `PartyRoster` defines Bran and Torin with names, classes, portraits, combat visuals, stats, resources, actions, and loadouts;
     - dungeon HUD party cards resolve from formation/roster data;
     - Warrior combat visual now resolves to existing `warrior` processed sprites;
     - combat text names player units through the roster.
   - Proof: `python tools/validators/validate_all.py`; `scripts/domain/dungeon_state_model_tests.gd`; `scripts/session/dungeon_run_session_tests.gd`; `scripts/presentation/dungeon_exploration_hud_tests.gd`; `scripts/presentation/combat_mercenary_asset_pipeline_tests.gd`; headless `DungeonDebug.tscn`; headless `CombatDebug.tscn`.

5. **World/Town Integration Prep**
   - Define the future boundary where town/global map owns supply purchase and durable inventory.
   - Dungeon should continue to receive only the carried loadout payload and return run results/inventory deltas.
   - Proof target: spec and slice first; implementation only after the global-map/town contract exists.

## First Implementation Guidance

- Keep the first dungeon map small: start room, one empty room, one treasure room, and one combat room.
- Use authored data before procedural generation.
- Do not implement puzzles, traps, camping, hunger, or inventory UI in this milestone.
- Keep combat boards data-driven through existing combat encounter files.
- Reward payloads may be data-shaped stubs until inventory/progression systems are ready.

## Validation

Current validation:

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_debug_force_victory_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/combat/CombatDebug.tscn --quit --resolution 2560x1440
```

Next dungeon work should continue with **Playable Dungeon Beta**, unless the user explicitly reprioritizes world/town integration or bespoke tactical combat map authoring.
