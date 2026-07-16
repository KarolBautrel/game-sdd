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
- Hazard outcomes now support weighted variants and `party_member_0` target stubs for HP/debuff effects.
- Dungeon combat launch metadata now carries `dungeon_modifiers` into combat encounters, including light, party effects, target effects, and active debuffs.

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
docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md
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
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_debug_force_victory_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/combat/CombatDebug.tscn --quit --resolution 2560x1440
```

Next dungeon work should focus on making dungeon modifiers actually affect combat setup, then replacing party target stubs with real roster/formation data. Separately, the abstract graph can later be replaced with a real exploration layout, post-run return destination, and persistent party progression once those systems are ready.
