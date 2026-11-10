# Combat Specs

Combat specs are split by tactical domain. See `STRUCTURE.md` for the organization rules.

## Domain Specs

### Overview

- `overview/000_combat_core.md`
- `overview/005_event_log_and_replay.md`
- `overview/082_combat_result_contract_v1.md`
- `overview/092_combat_encounter_authoring_v1.md`
- `overview/093_combat_readiness_for_dungeon.md`

### Grid

- `grid/001_combat_grid.md`
- `grid/022_line_of_sight.md`
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
- `presentation/086_combat_ui_asset_pipeline_v1.md`
- `presentation/087_combat_hud_restructure_v1.md`
- `presentation/088_combat_terrain_asset_showcase_v1.md`
- `presentation/089_combat_board_frame_skin_v1.md`
- `presentation/090_combat_unit_resource_assets_v1.md`
- `presentation/091_combat_feedback_polish_v2.md`
- `presentation/094_combat_map_editor_v1.md`

## Executable Slices

Executable acceptance scenarios live in `slices/`.

They stay flat and chronological because they prove implementation progress across domains.

Recent presentation/debug slices:

- `slices/085_debug_force_victory.md`
- `slices/086_combat_ui_asset_pipeline_v1.md`
- `slices/087_combat_hud_restructure_v1.md`
- `slices/088_combat_terrain_asset_showcase_v1.md`
- `slices/094_combat_map_editor_v1.md`
- `slices/095_combat_hud_text_layout.md`
- `slices/096_combat_animation_lifecycle.md`
- `slices/097_combat_board_frame_skin_v1.md`
- `slices/098_combat_unit_resource_assets_v1.md`
- `slices/099_combat_feedback_polish_v2.md`
- `slices/100_combat_encounter_authoring_v1.md`
- `slices/101_combat_readiness_for_dungeon.md`
- `slices/102_campaign_equipment_handoff.md` (world005 campaign boundary)
- `slices/103_party_advancement_handoff.md` (world007 progression)
- `slices/104_aimed_shot_line_of_sight.md` (grid022/actions063 regression)
- `slices/105_enemy_ai_exhausted_ap_with_mp.md` (ai008/030 regression)
- `slices/106_enemy_ai_affordable_fallback.md` (ai008 weighted-movement regression)
- `slices/107_preview_command_consistency.md` (presentation068 preview/commit audit)

## Milestones

Milestones live in `milestones/`.

They summarize what is already implemented and what a fresh agent should do next.
