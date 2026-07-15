# Milestone 001: Combat Core Debug Loop

Status: complete  
Date: 2026-07-14

## Summary

Combat has a verified core loop in both Python and Godot.

The project now has:

- combat rule specs;
- combat rule specs organized by tactical domain;
- executable combat slices;
- JSON encounter and command data;
- Python simulation and validation;
- Godot domain resolver;
- Godot headless combat slice tests;
- interactive Godot combat debug scene.
- movement-point resource support for multi-tile movement in debug combat.
- combat terrain decoration scale contract for grass tufts, stumps, boulders, and fallen branches.
- combat terrain decorations render without square debug tint underneath their transparent PNGs.
- combat unit art preloads all combat directions/actions once per encounter and caches resolved texture paths to avoid runtime stalls during animations.
- combat debug presentation now separates static grid rendering from dynamic tile overlays and updates unit nodes in place instead of recreating them during actions.
- combat HUD now uses an 18x11 tactical board at the 112 px combat scale, bottom skillbar action slots, and a pixel-styled top-right turn order panel.
- combat move targeting preview uses a local BFS cache instead of simulating one command per board tile.
- combat attack and skill targeting preview now labels targets with hit chance, damage, or blocked reasons before confirmation.

## Implemented Combat Rules

- Turn-based command resolution.
- Active unit validation.
- AP cost validation.
- Melee `basic_attack`.
- `move` to adjacent legal tiles.
- Rejection for invalid move targets:
  - occupied tile;
  - blocked tile;
  - out of bounds;
  - non-adjacent destination.
- `defend` status application.
- `end_turn` turn handoff.
- Enemy AI v0:
  - attack adjacent player;
  - otherwise move one tile toward nearest living player;
  - end turn when it has no AP;
  - otherwise end turn.
- Enemy AI ranged v1:
  - adjacent melee stays higher priority than ranged;
  - otherwise enemies with `ranged_attack` shoot a legal visible target in range;
  - if no ranged shot is legal, enemies still move toward the nearest living player.
- Enemy AI pathfinding v1:
  - enemy movement searches for a route through legal walkable tiles;
  - enemies can route around a `blocked` tile instead of only stepping toward lower distance;
  - pathfinding stops when it reaches a tile adjacent to the target;
  - diagonal movement cannot cut through blocked corners.
- Enemy AI ranged positioning v1:
  - enemies shoot legal ranged targets at 60% final hit chance or better;
  - enemies move instead of shooting when cover/evasion drops final hit chance below 60%;
  - blocked line of sight makes ranged target illegal, so AI falls back to movement.
- 8-way adjacency:
  - diagonal movement is legal;
  - diagonal melee attacks are legal;
  - AI can use diagonal steps when moving toward the player.
- Movement points v1:
  - units with `resources.mp` spend MP, not AP, for `move`;
  - multi-tile movement resolves a legal path up to remaining MP;
  - `unit_moved.path` exposes each step for presentation animation;
  - AP remains available for abilities after movement;
  - abilities such as `basic_attack` spend AP without reducing MP;
  - legacy units without `resources.mp` keep the original 1 AP adjacent move behavior.
- Deterministic event logs.
- Replay checks for executable slices.
- Terminal combat results:
  - last enemy defeated emits `combat_ended` with `victory`;
  - last player defeated emits `combat_ended` with `defeat`;
  - commands after combat end are rejected with `combat_already_ended`;
  - debug scene disables command buttons after combat ends.
- Terrain v1:
  - `blocked` tiles are not walkable;
  - `highground` tiles are walkable;
  - `cover_low` tiles are walkable;
  - debug scene colors terrain types distinctly;
  - attacker on `highground` gets `+10` ranged hit chance.
- Line of sight v1:
  - `ranged_attack` requires clear line of sight;
  - intermediate `blocked` tiles reject ranged attacks with `target_not_visible`;
  - units do not block line of sight yet.
- Cover v1:
  - target standing on `cover_low` gets `-20` ranged hit chance;
  - `cover_low` does not block line of sight;
  - cover does not reduce damage yet.
- Ranged attack v1:
  - `ranged_attack` targets a living enemy up to range 3;
  - range uses Chebyshev distance to match current 8-way movement;
  - line of sight and cover are applied;
  - out-of-range targets are rejected with `target_out_of_range`.
- Hit chance v1:
  - `ranged_attack` resolves a deterministic 1-100 roll;
  - base hit chance is 70%;
  - `hit_roll_resolved` records roll, base chance, unit modifiers, terrain modifier, cover modifier, final chance, and outcome;
  - misses spend AP but do not apply damage;
  - melee attacks still always hit.
- Accuracy/evasion v1:
  - final ranged hit chance uses `base + attacker.accuracy - target.evasion`;
  - omitted accuracy/evasion stats default to 0;
  - final hit chance is clamped to 10-95.
- Weapon profiles v1:
  - encounters may define `weapon_profiles`;
  - units may equip `equipped_weapon_id`;
  - weapon profiles can control action id, range, AP cost, ranged base hit chance, and damage bonus;
  - legacy units without equipped weapons still use fallback combat values.
- Special skills v1:
  - `power_strike` is implemented as the first melee special action;
  - `power_strike` can be driven by a weapon profile;
  - `aimed_shot` can be granted by a bow item profile;
  - learned unit actions can grant skills independently from equipment.
- Equipment/loadout v1:
  - encounters may define `item_profiles`;
  - units may equip `main_hand`, `off_hand`, and `armor` items through `loadout`;
  - equipped items may grant combat actions;
  - item action profiles can define AP cost, range, hit chance, damage bonus, cooldowns, and status effects;
  - `basic_attack`, `ranged_attack`, `shield_wall`, and `power_strike` can now be gated by equipped items;
  - two-handed main-hand items reject off-hand-dependent actions when an off-hand item is present.
- Enemy archetype loadouts v1:
  - encounters may define `enemy_archetypes`;
  - enemy units may reference an `archetype_id`;
  - archetypes can provide available actions and loadout before AI command selection and command resolution.
- Map Pipeline V1:
  - combat encounters may reference generated Tiled map JSON through `map_path`;
  - Python and Godot combat setup resolve `grid.width`, `grid.height`, and `grid.tiles` from the referenced map;
  - inline `grid` remains supported for low-level regression slices;
  - validators reject stale inline grids that conflict with `map_path`;
  - validators reject referenced-map unit spawns outside bounds or on blocked tiles.
- Debug scene usability pass:
  - action buttons use readable labels;
  - ranged attack can be selected and tested;
  - LoS blocked-shot scenario can be loaded from the debug UI;
  - cover scenario can be loaded from the debug UI;
  - unit HP/AP, accuracy/evasion, and position are visible in a side panel;
  - a compact legend explains grid colors.

## Verified Slices

Executable slice docs live in:

```text
docs/specs/combat/slices/
```

Current verified slices:

- `001_basic_attack.md`
- `002_invalid_no_ap.md`
- `003_move.md`
- `004_move_occupied.md`
- `005_move_blocked.md`
- `006_defend.md`
- `007_end_turn.md`
- `008_enemy_ai_adjacent_attack.md`
- `009_enemy_ai_move_toward_player.md`
- `010_diagonal_move.md`
- `011_diagonal_attack.md`
- `012_enemy_ai_no_ap_end_turn.md`
- `013_round_cycle_player_enemy_player.md`
- `014_victory_last_enemy_defeated.md`
- `015_defeat_last_player_defeated.md`
- `016_command_after_combat_end_rejected.md`
- `017_debug_legal_target_feedback.md`
- `018_debug_reset_and_enemy_turn_helper.md`
- `019_highground_walkable.md`
- `020_terrain_debug_visible.md`
- `021_ranged_attack_in_range.md`
- `022_ranged_attack_out_of_range.md`
- `023_ranged_attack_hit_roll.md`
- `024_ranged_attack_miss.md`
- `025_accuracy_increases_hit_chance.md`
- `026_evasion_decreases_hit_chance.md`
- `027_highground_increases_ranged_hit_chance.md`
- `028_ranged_attack_blocked_by_line_of_sight.md`
- `029_cover_reduces_ranged_hit_chance.md`
- `030_enemy_ai_ranged_attack.md`
- `031_enemy_ai_pathfinds_around_blocked_tile.md`
- `032_enemy_ai_multi_turn_path_pursuit.md`
- `033_diagonal_corner_cut_blocked.md`
- `034_enemy_ai_approaches_low_chance_ranged_target.md`
- `035_debug_sandbox_ui_pass.md`
- `040_multi_enemy_pathing_and_targeting.md`
- `041_multi_enemy_bottleneck_spacing.md`
- `042_mixed_melee_ranged_enemy_roles.md`
- `043_target_selection_multiple_players.md`
- `044_ranged_intercept_by_unit.md`
- `045_weapon_profile_melee_damage.md`
- `046_weapon_profile_ranged_range_hit.md`
- `047_weapon_profile_ap_cost.md`
- `048_power_strike_skill.md`
- `049_weapon_profile_ap_cost_success.md`
- `050_enemy_ai_power_strike.md`
- `051_enemy_ai_power_strike_cooldown_blocks_repeat.md`
- `052_skill_cooldown_expires_on_own_turn.md`
- `053_weapon_loadout_v1.md`
- `054_bow_required_for_ranged_attack.md`
- `055_shield_required_for_shield_wall.md`
- `056_two_handed_blocks_shield.md`
- `057_weapon_grants_power_strike.md`
- `058_armor_reduces_damage.md`
- `059_shield_wall_applies_damage_reduction.md`
- `060_movement_points_multi_tile.md`
- `061_ap_mp_turn_economy.md`
- `062_enemy_ai_move_then_attack.md`
- `063_aimed_shot_from_bow.md`
- `064_learned_skill_without_weapon.md`
- `065_enemy_archetype_loadout.md`
- `066_map_reference_encounter.md`
- `068_move_preview_confirm.md`
- `069_combat_presentation_architecture_v1.md`
- `074_combat_action_feedback.md`
- `075_targeting_preview_completion.md`
- `076_unit_animation_state_machine.md`

## Spec Organization

Rule specs now live in domain folders:

- `overview/`
- `grid/`
- `turns/`
- `actions/`
- `attacks/`
- `hit_resolution/`
- `equipment/`
- `weapons/`
- `ai/`
- `presentation/`

Executable slices remain flat in `slices/`.

Current presentation rule specs:

- `presentation/068_combat_interaction_preview.md`
- `presentation/069_combat_presentation_architecture.md`
- `presentation/074_combat_action_feedback.md`
- `presentation/076_combat_sandbox_layout.md`
- `actions/063_aimed_shot_v1.md`
- `actions/064_learned_actions_v1.md`
- `ai/065_enemy_archetype_loadout_v1.md`

See:

```text
docs/specs/combat/STRUCTURE.md
```

## Latest Update

Latest verified scope:

- round increments when turn order wraps back to the player;
- player AP refreshes when the next player turn starts;
- full player -> enemy -> player round cycle is verified in Python and Godot;
- victory and defeat are verified in Python and Godot;
- commands after combat end are rejected.
- debug scene highlights active unit and legal targets using resolver-backed checks;
- debug scene displays last accepted action or rejection reason.
- debug scene can reset the encounter;
- debug scene has a one-click enemy turn helper.
- terrain v1 is specified and highground movement is verified.
- ranged attack v1 is specified and verified in Python and Godot.
- hit chance v1 is specified and verified in Python and Godot.
- accuracy/evasion v1 is specified and verified in Python and Godot.
- highground ranged hit modifier is specified and verified in Python and Godot.
- line of sight v1 is specified and verified in Python and Godot.
- cover v1 is specified and verified in Python and Godot.
- enemy AI ranged v1 is specified and verified in Python and Godot.
- enemy AI pathfinding v1 is specified and verified in Python and Godot.
- diagonal corner-cutting is blocked and verified in Python and Godot.
- enemy AI ranged positioning v1 is specified and verified in Python and Godot.
- debug scene has a clearer status panel, unit panel, legend, and ranged attack button.
- debug scene can load a dedicated ranged enemy AI test.
- debug scene can load a dedicated pathfinding obstacle test.
- debug scene can load a dedicated low-chance ranged AI test.
- debug scene has grouped command/load buttons, newest-first event log, tile inspect panel, and action rejection previews.
- multi-enemy movement v1 is specified and verified for two enemies acting on the current board state.
- debug scene can load a dedicated multi-enemy test.
- multi-enemy bottleneck spacing is specified and verified for a one-tile corridor.
- debug scene can load a dedicated bottleneck test.
- mixed melee/ranged enemy roles are specified and verified.
- debug scene can load a dedicated mixed roles test.
- multiple-player target selection is specified and verified for nearest living ranged targets.
- debug scene can load a dedicated target selection test.
- ranged intercept by living units is specified and verified.
- debug scene can load a dedicated ranged intercept test.
- debug scene test loading now uses a compact scenario picker instead of a long button list.
- debug scene reserves more vertical space for the newest-first event log.
- weapon profiles v1 is specified and verified in Python and Godot.
- melee weapon damage bonus, ranged weapon range/base hit, and blocked weapon AP cost are covered by slices 045-047.
- `power_strike` special action is specified and verified by slice 048.
- positive 2 AP heavy weapon attack is verified by slice 049.
- debug scene can load dedicated weapon profile and power strike tests.
- enemy AI can use `power_strike` when adjacent, eligible, and deterministic chance passes.
- `power_strike` applies `skill_cooldown`, which prevents repeat use and expires on the actor's own turn start.
- debug scene can load dedicated enemy power strike and cooldown tests.
- item profiles and unit loadouts are specified and verified in Python and Godot.
- equipped items can grant actions that are not listed in legacy `available_actions`.
- sword-only units cannot perform `ranged_attack`.
- shieldless units cannot perform `shield_wall`.
- invalid two-handed plus off-hand loadouts reject shield-dependent actions.
- greatsword loadout can grant `power_strike` and apply its cooldown.
- debug scene can load dedicated loadout/equipment tests 053-057.
- debug scene now has temporary Aseprite-generated pixel-art unit sprites.
- movement and attack events briefly switch unit sprites to simple test animation frames.
- armor v1 is specified and verified in Python and Godot.
- equipped armor can contribute passive `armor_reduction` to incoming damage.
- slice 058 verifies `chainmail` reducing raw damage 4 to final damage 2.
- `shield_wall` positive case is specified and verified in Python and Godot.
- slice 059 verifies status-based `damage_reduction` stacking with armor mitigation and clamping final damage to minimum 1.
- debug scene can load dedicated armor and shield wall mitigation tests.
- movement points v1 is specified and verified in Python and Godot.
- slice 060 verifies a two-tile move that spends 2 MP and 0 AP while recording `unit_moved.path`.
- slice 061 verifies a unit can move with MP and then attack with AP in the same turn.
- slice 062 verifies enemy AI can spend MP to move adjacent and then choose `basic_attack` while AP remains available.
- `aimed_shot` item-granted special action is specified in `actions/063_aimed_shot_v1.md` and verified by slice 063.
- learned unit actions are specified in `actions/064_learned_actions_v1.md` and verified by slice 064.
- enemy archetype loadouts are specified in `ai/065_enemy_archetype_loadout_v1.md` and verified by slice 065.
- slice 066 verifies `debug_map_scale_showcase` uses `map_path`, resolves its combat grid from `combat_test_clearing.json`, and no longer duplicates inline grid tiles.
- slice 068 documents the combat sandbox move interaction: legal movement overlay is softer, first click previews path/MP cost, and second click confirms the move.
- slice 069 starts the production-facing combat presentation architecture by extracting text formatting, unit art lookup, action visibility, and scenario catalog responsibilities from `combat_debug.gd`.
- character assets were reorganized into `assets/combat/characters/heroes/warrior` and `assets/combat/characters/villains/enemy_baddie`, keeping combat character art separate from future dungeon crawler and world map assets.
- debug scene loads sprites from the new asset folders and can animate multi-step movement paths.
- debug scene can load the dedicated movement points multi-tile test.
- debug scene can load the dedicated AP/MP move-then-attack economy test.
- debug scene now renders units on a separate overlay layer with larger tactical sprites, larger grid tiles, and tweened pixel movement between tile centers.
- debug scene scenario picker was reduced to one full combat showcase instead of exposing low-level regression slices.
- `debug_full_combat_showcase` uses an 8x8 arena with blocked tiles, highground, cover, one sword-and-shield hero, one melee enemy, and one bow enemy.
- debug showcase grid scale was tuned down for an 8x8 arena, unit stats were moved out of tile labels, and movement animation now uses one chained tween across path steps.
- debug showcase UI was compacted for the 8x8 board, tactical grid markings were muted, units start closer together, and movement tweens are slower/linear so walk sprites read more clearly.
- debug showcase resource readouts now render as compact HP/AP/MP overlays on unit sprites, and turn stepping uses the same animated command path instead of jumping through hidden commands.
- combat debug UI now has a prominent pixel-styled action banner, human-readable action feed, and clearer selected-action buttons.
- combat debug action buttons are filtered by the active unit's available actions, loadout-granted actions, cooldowns, and current AP/MP so unavailable equipment actions do not clutter the UI.
- asset folders are now split by gameplay layer: combat visuals live under `assets/combat/`, with `assets/dungeon/` and `assets/world/` reserved for dungeon crawler and world map art.
- combat scene now uses `assets/combat/terrain/grass/meadow_grass_floor_*.png` variants as the base floor visuals.
- combat scene presentation moved closer to an in-game battle screen: larger 72px tiles, larger 96px unit sprites, a framed board, darker scene background, cleaner combat HUD copy, and `debug_full_combat_showcase` as the default encounter.
- combat scene scale was retuned for 2K presentation: 128px tiles, 160px unit sprites, 2560x1440 default viewport, solid grass base under transparent floor art, and special terrain now uses generated nature props over the grass instead of the old hand-painted logic atlas tiles.
- combat floor rendering now uses 96px logical tiles with 112px overlapped terrain art, so transparent grass edges blend across neighboring tiles instead of exposing visible square gaps.
- combat 2K layout was enlarged again: 150px logical tiles, 214px overlapped terrain art, 190px unit sprites, and a 4:1 left-board/right-command layout so the battle board becomes the dominant screen area.
- combat floor rendering was reworked to preserve asset sharpness: the showcase is now a 12x12 arena, each 104px logical tile is built from multiple unscaled 64px grass patches, terrain props render at 98px centered scale, and unit sprites render at 142px.
- combat floor rendering was optimized into a single generated board background texture. Grass patches are composited once per encounter into `BoardTerrain`, while per-tile nodes now handle only interaction overlays, terrain props, previews, and units.
- combat terrain backgrounds are now authored/generated as reusable full-board PNGs in `assets/combat/terrain/backgrounds/`; combat encounters can reference one with `background_path`, and `debug_full_combat_showcase` uses `old_mine_meadow_00_lush.png`.
- combat background generation now creates two 10x10 continuous meadow surfaces instead of visible per-tile grass blocks. It uses procedural grass texture, soft clumps, and occasional smaller `grass_tuft` accents so the board reads as one field.
- combat debug HUD now uses a bottom pixel skillbar for player actions, a top-right turn order panel, unit-local HP/AP/MP readouts, and a larger 18x11 full-board meadow background so the combat screen reads closer to the target game layout.
- move preview is now cached from a local BFS reachability pass when the active unit/action changes, removing the repeated resolver simulations that caused a hitch every time `Move` was selected on the larger 18x11 board.
- attack and skill targeting preview now renders visible unit-local result text for targetable units, so selected melee/ranged/special actions can show damage, hit chance, or rejection reasons above the target instead of only coloring the terrain tile underneath.
- SDD workflow documentation now explicitly requires durable rules to live in domain specs, slices to remain acceptance proofs, and milestones to remain progress summaries.
- target preview was clarified so legal melee/special attacks show guaranteed `100% HIT` plus `DMG`, while rejected targets no longer show misleading unit-local damage panels or `0` placeholders.
- combat action feedback is now specified and implemented in `presentation/074_combat_action_feedback.md`: confirmed hits show floating `-X DMG`, misses show floating `MISS`, and existing lunge/hit/death animations remain event-driven.
- floating combat text is extracted into `scripts/presentation/combat/combat_floating_text.gd`, so future resolver events such as `status_applied` can reuse the same board-message pipeline.
- SDD workflow docs now explicitly require every behavior change to follow `domain/presentation spec -> slice acceptance scenario -> test/validator proof`, with manual UI verification gaps documented when automation is not available yet.
- floating text helper mapping is covered by `scripts/presentation/combat_floating_text_tests.gd`, closing the automated gap for `damage_applied`, miss, and `status_applied` event-to-message conversion.
- targeting preview formatting is extracted into `scripts/presentation/combat/combat_targeting_preview.gd` and covered by `scripts/presentation/combat_targeting_preview_tests.gd`, including `100% HIT`, `% HIT`, `DMG`, `COST X AP`, and rejected-target suppression.
- unit visual state selection is extracted into `scripts/presentation/combat/combat_unit_visual_state.gd` and covered by `scripts/presentation/combat_unit_visual_state_tests.gd`, including walk, combat, hit, death, and status reaction mapping.
- Validation passed on 2026-07-15:
  - `python tools\validators\validate_all.py`
  - `& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --quit --resolution 2560x1440`
  - `& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd`
  - `& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_floating_text_tests.gd --resolution 2560x1440`
  - `& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_targeting_preview_tests.gd --resolution 2560x1440`
  - `& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/combat_unit_visual_state_tests.gd --resolution 2560x1440`

## Important Files

Python domain prototype:

```text
tools/combat/simulate_combat.py
tools/validators/validate_combat_slice.py
```

Godot domain implementation:

```text
scripts/domain/combat_resolver.gd
scripts/domain/combat_slice_tests.gd
```

Interactive debug scene:

```text
scenes/combat/CombatDebug.tscn
scripts/presentation/combat_debug.gd
```

## Validation Commands

Full validation:

```powershell
python tools\validators\validate_all.py
```

Combat slices in Python:

```powershell
python -m tools.validators.validate_combat_slice
```

Combat slices in Godot:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

Interactive combat debug scene:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

## Combat To Dungeon Roadmap

Status: active queue
Owner: combat milestone until dungeon transition criteria are met

Combat is not considered "done forever"; it is considered "ready for dungeon" when the core battle loop is readable, authored, deterministic, and reusable enough that dungeon encounters can enter and exit combat without reopening combat fundamentals.

### Queue Workflow

For every item below:

1. Add or update the owning domain/presentation spec.
2. Add or update one chronological slice in `docs/specs/combat/slices/`.
3. Add or update automated validation/test coverage for the slice.
4. If no UI automation exists yet, document the manual verification gap in the slice and milestone.
5. Implement the smallest complete behavior.
6. Run the named validation commands.
7. Mark the item `Done` only after spec, slice, implementation, and test/validation proof are all present.
8. Move to the next unfinished item in order unless the user explicitly reprioritizes.

### Exit Criteria For Moving To Dungeon

Move to the dungeon layer only when all required items in this roadmap are `Done` and the following are true:

- Combat can start from authored encounter data, not hardcoded scene assumptions.
- The player can understand movement, targeting, hit chance, cost, damage, miss, and status feedback without reading a debug log.
- The combat scene has a stable board/HUD layout at 2560x1440 and remains usable at smaller desktop sizes.
- At least one melee enemy and one ranged enemy use reusable archetype/loadout data.
- At least one simple status effect is fully specified, sliced, validated, displayed, and resolved over turns.
- Combat can end with victory/defeat and expose enough result data for a dungeon scene to continue.
- Full validation passes:
  - `python tools\validators\validate_all.py`
  - Godot headless project load at `2560x1440`
  - Godot combat slice tests

### Ordered Combat Queue

1. **Done - Presentation Feedback V1**
   - Owner spec: `presentation/074_combat_action_feedback.md`
   - Slice: `slices/074_combat_action_feedback.md`
   - Implementation: `scripts/presentation/combat/combat_floating_text.gd`
   - Proof: validators and Godot combat slice tests pass; visual floating text still has a documented manual UI verification gap.

2. **Done - Floating Text Helper Test**
   - Goal: add automated coverage for `CombatFloatingText.messages_from_events`.
   - Owner spec: `presentation/074_combat_action_feedback.md`
   - Slice: update `slices/074_combat_action_feedback.md`
   - Test proof: `scripts/presentation/combat_floating_text_tests.gd` asserts:
     - `damage_applied` -> `-X DMG`;
     - miss -> `MISS`;
     - `status_applied` -> uppercase status text.
   - Note: visual placement still has a documented manual UI verification gap until a screenshot/UI harness exists.

3. **Done - Targeting UX Completion V1**
   - Goal: make selected actions show all needed pre-click information.
   - Owner spec: `presentation/068_combat_interaction_preview.md`
   - Slice: `slices/075_targeting_preview_completion.md`
   - Required behavior:
     - legal targets show hit chance or guaranteed hit;
     - legal targets show `DMG`;
     - action cost is labeled clearly as `COST X AP` or `COST X MP`, not just `AP`;
     - rejected targets do not show fake damage;
     - blocked reason is available through inspect/banner.
   - Test proof: `scripts/presentation/combat_targeting_preview_tests.gd` covers legal melee/special, ranged hit, ranged miss, action cost, and rejected-target suppression.

4. **Done - Animation State Machine V1**
   - Goal: replace scattered one-off visual action flags with a small reusable presentation state model.
   - Owner spec: `presentation/076_combat_sandbox_layout.md` or new `presentation/076_unit_animation_state_machine.md`
   - Slice: `slices/076_unit_animation_state_machine.md`
   - Required behavior:
     - idle, move, attack, hit, death, status reaction states;
     - deterministic fallback when an animation asset is missing;
     - no runtime texture stalls during state changes.
   - Test proof: `scripts/presentation/combat_unit_visual_state_tests.gd` covers movement, attack, hit, death, miss actor combat, and status reaction state selection.

5. **Done - Bleeding Status V1**
   - Goal: implement the first simple over-time status before more complex control effects.
   - Owner spec: `attacks/077_bleeding_status_v1.md`
   - Slice: `slices/077_bleeding_status_v1.md`
   - Required behavior:
     - a profile can apply `bleeding`;
     - bleeding deals fixed damage at the affected unit's turn start;
     - bleeding duration ticks down predictably;
     - floating text shows `BLEEDING` on application and `-X DMG` on tick;
     - combat UI shows a compact reusable status icon while bleeding is active;
     - event log remains deterministic.
   - Test proof:
     - `validate_combat_slice_77()` asserts `deep_cut`, `status_applied`, two bleeding tick `damage_applied` events, expiry, final HP, and replay determinism;
     - `combat_slice_tests.gd` includes `slice_77_bleeding_status_v1`;
     - `combat_unit_visual_state_tests.gd` asserts status tick damage does not trigger a self-attack visual state.

6. **Done - Guard Break V1**
   - Goal: implement one simple control/status mechanic after bleeding proves status infrastructure.
   - Owner spec: `actions/078_guard_break_v1.md`
   - Slice: `slices/078_guard_break_v1.md`
   - Required behavior:
     - `guard_break` applies `guard_broken`;
     - `guard_broken` lowers effective defense through `defense_modifier`;
     - follow-up attacks use lowered defense and preview the higher damage;
     - UI shows `GUARD BROKEN` through reusable floating text and a compact `G` icon;
     - the status expires on the affected unit's own-turn start.
   - Test proof:
     - `validate_combat_slice_78()` asserts status application, follow-up damage increase, expiry, final HP, and replay determinism;
     - `combat_slice_tests.gd` includes `slice_78_guard_break_v1`;
     - `combat_floating_text_tests.gd` asserts `guard_broken` renders as `GUARD BROKEN`.

7. **Next - Terrain Movement Costs V1**
   - Goal: make authored terrain affect movement without changing the whole map pipeline again.
   - Owner spec: `grid/024_terrain.md`
   - Slice: `slices/079_terrain_movement_costs.md`
   - Required behavior:
     - terrain can define MP cost;
     - movement preview and pathfinding use MP cost;
     - enemy pathfinding handles varied costs;
     - UI preview shows final MP cost.
   - Test proof: Python/Godot combat slice tests and map validator updates if data schema changes.

8. **Enemy Archetype Roles V2**
   - Goal: make enemies reusable enough for dungeon encounters.
   - Owner spec: `ai/065_enemy_archetype_loadout_v1.md` or new `ai/080_enemy_archetype_roles_v2.md`
   - Slice: `slices/080_enemy_archetype_roles_v2.md`
   - Required behavior:
     - define swordsman, shieldman/bruiser, archer archetypes;
     - showcase encounter uses archetypes instead of bespoke inline enemy setup;
     - AI chooses actions consistent with role and loadout.
   - Test proof: Python/Godot combat slice tests.

9. **Encounter Result Contract V1**
   - Goal: define what dungeon receives when combat ends.
   - Owner spec: `overview/` or new `presentation/`/`encounter` boundary spec.
   - Slice: `slices/081_combat_result_contract.md`
   - Required behavior:
     - victory/defeat result is queryable;
     - surviving units/resources can be summarized;
     - rewards/loot hooks are intentionally stubbed or data-shaped;
     - no dungeon implementation required yet.
   - Test proof: Python/Godot combat slice tests.

10. **Combat Encounter Authoring V1**
    - Goal: make one new combat encounter from map + archetypes without code changes.
    - Owner spec: map/encounter authoring docs.
    - Slice: `slices/082_combat_encounter_authoring_v1.md`
    - Required behavior:
      - documented steps for adding a combat map encounter;
      - validator checks map reference, spawns, archetypes, loadouts, and background;
      - debug scene scenario catalog can load it without controller edits.
    - Test proof: validators plus Godot project load.

11. **Combat Readiness Review For Dungeon**
    - Goal: run the exit criteria as a final checklist.
    - Owner spec: this milestone plus any transition/boundary spec.
    - Slice: `slices/083_combat_ready_for_dungeon.md`
    - Required behavior:
      - all required roadmap items are done or explicitly deferred;
      - validation commands pass;
      - manual UI gaps are listed;
      - next milestone for dungeon can start without re-planning combat basics.
    - Test proof: full validation plus documented manual playthrough of the debug combat scene.
