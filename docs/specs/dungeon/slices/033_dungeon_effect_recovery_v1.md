# Slice 033: Dungeon Effect Recovery V1

Status: implemented
Owner spec: `docs/specs/dungeon/overview/027_dungeon_effect_recovery_v1.md`

## Acceptance

- Given a hazard applies a dungeon debuff and the party has a remedy kit, when recovery is used, one remedy kit is consumed and active debuffs are cleared.
- Given a debuff has target mappings, when recovery is used, target debuff mappings are removed while HP loss remains.
- Given no debuff exists, recovery is rejected.
- Given no remedy kit exists, recovery is rejected.
- Given the debug HUD has an active debuff and a remedy kit, it shows a recovery action and refreshes the effects summary after use.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
