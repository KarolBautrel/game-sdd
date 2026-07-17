# Slice 039: Dungeon Inventory And Loot Resolution V2

Status: implemented
Owner spec: `docs/specs/dungeon/overview/032_dungeon_inventory_loot_resolution_v2.md`

## Acceptance

- Given a reward is claimed, dungeon state records it in `run_inventory`.
- Given a run is completed, the run result keeps claimed loot and exposes the same values as `inventory_delta`.
- Given a run is retreated, the first beta rule keeps claimed loot.
- Given a run fails, claimed loot appears in `lost_rewards` and `inventory_delta` is empty.
- Given the HUD renders progress and post-run summary, it reads run inventory totals.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
