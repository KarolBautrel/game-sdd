# Slice 037: Stable Dungeon Entry Selection V1

Status: implemented
Owner spec: `docs/specs/dungeon/overview/030_stable_dungeon_entry_selection_v1.md`

## Acceptance

- Given no explicit payload, dungeon entry selection resolves to authored Old Mine.
- Given a generated payload with seed and difficulty, dungeon data is generated deterministically from that payload.
- Given invalid payload fields, source and difficulty are normalized to supported values.
- Given the debug preparation panel changes source, seed, or difficulty, it updates the entry payload and rebuilds the run preview from that payload.

## Proof

- `scripts/domain/dungeon_entry_selection_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
