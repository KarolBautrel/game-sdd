# Slice034: approved family in a native exploration screen

Owner: ../034_ashen_exploration_native.md.

- Production outputs have saved prompts, source/reference hashes and editable
  Aseprite sources. Transparent room assets have real alpha and clean edges.
- Real room ids/names/routes/selection/costs/resources/HP render independently
  from chart artwork; changed generated graphs cannot display false baked paths.
- Preview does not mutate state; confirm and event choices use authoritative
  domain transitions. Modal focus blocks map travel until resolution.
- Native target-size captures show readable fitted type, whole portrait/current
  max HP, faithful shared shell and varied map contents. Compare to approved art.
- Existing dungeon/domain/route acceptance plus focused new native tests pass.
  Report physical play separately and retain any unresolved visual gaps.

Executable proofs: `ashen_exploration_tests.gd`, `dungeon_visual_cohesion_tests.gd`,
`dungeon_route_preview_tests.gd`, `expedition_art_direction_tests.gd` and native
play renderer `--views dungeonpolish,ashenfamily`; detailed results/commands in
`docs/qa/2026-11-04-ashen-native-ui.md`. Physical/user acceptance remains open.
