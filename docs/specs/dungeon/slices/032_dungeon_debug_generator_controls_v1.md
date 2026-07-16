# Slice 032: Dungeon Debug Generator Controls V1

Status: implemented
Owner spec: `docs/specs/dungeon/presentation/015_dungeon_debug_generator_controls_v1.md`

## Acceptance

- Given the debug scene is in preparation mode, when generated source is selected, the preparation panel shows generated source metadata including difficulty, seed, rooms, corridors, and hazard count.
- Given generated source is selected, when debug difficulty is changed, the generated dungeon rebuilds for that difficulty and the preparation state resets.
- Given a dense generated difficulty-3 template is selected, every room block remains inside the framed map area.
- Given generated source is selected, when reroll is pressed, the seed changes and hazards/layout metadata refresh for the same selected difficulty.
- Given authored source is selected, difficulty controls do not change authored dungeon rules.

## Proof

- `scripts/presentation/dungeon_exploration_hud_tests.gd`
