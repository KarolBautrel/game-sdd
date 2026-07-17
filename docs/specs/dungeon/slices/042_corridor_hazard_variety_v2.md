# Slice 042: Corridor Hazard Variety V2

Status: implemented
Owner spec: `docs/specs/dungeon/overview/035_corridor_hazard_variety_v2.md`

## Acceptance

- Corridor hazard schema accepts darkness, noise, and blockage hazard families.
- The Old Mine hazard catalogue includes multiple rubble severities and multiple trap/noise/darkness variants.
- Old Mine hazard pools reference more than one event where appropriate.
- A major blockage can reject traversal through `blocks_traversal`.
- A darkness hazard can use lamp oil through the existing supply-choice flow.
- Generated corridor plans can select non-rubble/non-trap mine hazard pools by tag and danger band.

## Proof

- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
