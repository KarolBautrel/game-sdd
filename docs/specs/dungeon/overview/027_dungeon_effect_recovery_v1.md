# Dungeon Effect Recovery V1

Status: implemented
Owner: dungeon overview

## Purpose

Dungeon hazards can apply persistent run effects such as bruised, poisoned, bleeding, or limping. The first recovery system gives exploration a clear way to remove debuff pressure without resetting the run.

## Rules

- Dungeons may define a `remedy_kit` expedition supply in `starting_supplies` and `supply_loadout_options`.
- `remedy_kit` is consumed by an explicit recovery action.
- Recovery is allowed only when the run has at least one active dungeon debuff.
- Recovery clears active dungeon debuff stacks and target debuff mappings.
- Recovery removes debuff ids from `party_effects.debuffs`.
- Recovery does not restore HP loss. HP recovery is a separate future mechanic.
- Recovery is rejected if no remedy kit is available or no active debuff exists.
- Recovery appends a structured event to the dungeon hazard log so the HUD/session can explain what changed.

## Data Notes

The first recovery supply is intentionally generic. Later specs may split it into bandages, antidotes, splints, food, camping supplies, or class skills once the debuff catalogue and party roster are more complete.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd` covers accepted and rejected recovery actions.
- `scripts/presentation/dungeon_exploration_hud_tests.gd` covers the debug HUD recovery action visibility and summary refresh.
