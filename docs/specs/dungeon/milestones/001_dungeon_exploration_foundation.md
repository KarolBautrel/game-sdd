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
- `dungeon_old_mine` now includes a needle trap corridor hazard before `Spider Nest`, mitigated by `trap_tools` or resolved through `poisoned`.
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
docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md
docs/specs/dungeon/presentation/013_dungeon_presentation_vertical_slice_v1.md
docs/specs/dungeon/presentation/014_dungeon_debug_generated_toggle_v1.md
docs/specs/dungeon/presentation/015_dungeon_debug_generator_controls_v1.md
docs/specs/dungeon/presentation/016_dungeon_room_event_presentation_v1.md
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

1. **In Progress - Beta Dungeon-Combat Loop**
   - Goal: make one playable loop feel coherent end to end: enter dungeon, explore, hit corridor hazards, resolve room events, enter combat, return to dungeon, claim rewards, finish or reset.
   - Expected work:
     - harden dungeon session handoff into combat and back;
     - verify room/corridor pending state survives scene changes;
     - make post-combat dungeon feedback understandable without debug-only assumptions.
   - Current progress:
     - session-level combat return feedback is implemented for victory, guarded reward victory, and defeat.
   - Proof target: dungeon state tests, session bridge tests, HUD tests, manual click-through.

2. **Planned - Stable Dungeon Entry Selection**
   - Goal: move generated difficulty/seed/source out of the debug preparation panel and into a pre-entry contract.
   - Expected work:
     - define an entry payload from world map/node/progression systems;
     - generated dungeon difficulty is predefined before entering;
     - debug controls remain only as local test helpers.
   - Proof target: data contract validation plus dungeon debug test helpers.

3. **Planned - Run Result And World Return**
   - Goal: turn `Finish Expedition` into a return payload that can be consumed by the wider game.
   - Expected work:
     - completed/retreated/failed result states;
     - claimed gold/items/XP summary;
     - persistent injuries/debuffs summary;
     - next-scene/world-map return hook.
   - Proof target: dungeon state tests and session tests.

4. **Planned - Dungeon Inventory And Loot Resolution**
   - Goal: separate temporary run loot from durable player inventory.
   - Expected work:
     - run inventory bucket;
     - loot confirmation on completion;
     - lost/kept loot rules for retreat or defeat;
     - item ids prepared for a real inventory service.
   - Proof target: dungeon state tests and validator checks.

5. **Planned - Room Event System V2**
   - Goal: expand room content beyond the first shrine/stash examples.
   - Expected work:
     - chests, locked chests, corpses, notes, shrines, curios, blocked objects, hidden caches;
     - event tags by theme and room kind;
     - event history so repeated rooms do not feel arbitrary.
   - Proof target: room event schema validation, domain tests, HUD tests.

6. **Planned - Room Event Outcomes V2**
   - Goal: make room event choices tactically interesting.
   - Expected work:
     - supply costs;
     - weighted risk;
     - party-targeted consequences;
     - skill/stat hooks once roster skills exist;
     - positive, neutral, and negative outcomes.
   - Proof target: domain tests for each consequence family.

7. **Planned - Corridor Hazard Variety V2**
   - Goal: broaden traversal pressure beyond the first rubble/trap examples.
   - Expected work:
     - multiple rubble severities;
     - trap variants;
     - darkness/ambush/noise events;
     - temporary blocked paths;
     - theme-specific pools.
   - Proof target: reusable event/pool validation and traversal tests.

8. **Planned - Supply Economy V2**
   - Goal: make loadout choices matter across a whole expedition.
   - Expected work:
     - balance oil, pickaxe, trap tools, remedy;
     - add candidates such as bandages, antidote, food, rope, camping kit;
     - define carry limits and cost/source of supplies;
     - expose clearer supply consequences in UI.
   - Proof target: loadout tests and manual balance notes.

9. **Planned - Recovery And Camping**
   - Goal: add an explicit in-dungeon recovery layer instead of only instant remedy usage.
   - Expected work:
     - rest/camp action;
     - partial HP recovery;
     - debuff treatment;
     - supply consumption;
     - ambush or time/light risk while resting.
   - Proof target: state tests and HUD action tests.

10. **Planned - Generated Dungeon Profiles**
    - Goal: make generated dungeons select from named profiles rather than only difficulty.
    - Expected work:
      - short/medium/deep profiles;
      - mine/crypt/ruins themes;
      - profile-specific template pools, room event pools, corridor hazard pools, combat encounter pools;
      - constraints for route length and branch count.
    - Proof target: procedural draft tests and schema validation.

11. **Planned - Generated Template Pool Expansion**
    - Goal: grow curated finite layouts before returning to freer procedural generation.
    - Expected work:
      - more layouts per difficulty/profile;
      - candidate slots for room events and corridor hazards;
      - authored pacing rules for treasure, combat, and exits;
      - visual fit checks for dense templates.
    - Proof target: procedural tests and headless scene load at common resolutions.

12. **Planned - Combat Encounter Selection Per Dungeon**
    - Goal: stop using one debug encounter for every dungeon combat room.
    - Expected work:
      - encounter pools by dungeon theme/difficulty/room kind;
      - generated rooms choose encounter refs by seed;
      - authored rooms can still pin a specific encounter;
      - combat launch metadata includes dungeon context.
    - Proof target: validator checks and session/combat launch tests.

13. **Planned - Dungeon UI Game Skin**
    - Goal: replace the current debug-like chrome with a first game UI skin.
    - Expected work:
      - styled resource bar;
      - event cards;
      - map frame and room nodes;
      - clearer combat/reward/exit buttons;
      - hover/disabled/active states.
    - Proof target: presentation tests plus manual screenshot review.

14. **Planned - Pixel-Art Dungeon UI Assets**
    - Goal: create or integrate small readable pixel-art UI assets for dungeon play.
    - Expected work:
      - oil, pickaxe, trap tools, remedy, gold, light state, room event, trap, rubble icons;
      - source assets under `assets_src/` where practical;
      - exported assets under `assets/`;
      - repeatable asset workflow documented.
   - Proof target: asset import check and manual visual review.

15. **Planned - Playable Dungeon Beta**
    - Goal: ship one coherent beta dungeon pass for hands-on testing.
    - Expected work:
      - pre-entry setup;
      - supplies;
      - generated or curated layout;
      - corridor hazards;
      - room events;
      - multiple combat encounter choices;
      - rewards/inventory result;
      - finish/return flow;
      - first-pass game UI.
    - Proof target: automated smoke tests plus manual playthrough checklist.

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

Next dungeon work should continue roadmap item 1, **Beta Dungeon-Combat Loop**, by testing/polishing pending state across scene transitions and then moving toward stable dungeon entry selection, unless the user explicitly reprioritizes UI/assets or generated content variety.
