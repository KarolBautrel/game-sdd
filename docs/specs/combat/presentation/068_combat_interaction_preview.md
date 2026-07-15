# 068 Combat Interaction Preview

Status: active
Date: 2026-07-15

## Purpose

Combat preview must make a command understandable before the player commits it.

Presentation may simulate commands against a clean copy of the current state, but `CombatResolver` remains the source of legality, costs, hit results, damage, and rejection reasons.

## Movement Preview

- Selecting `Move` shows legal destinations without mutating combat state.
- The first click on a legal destination stores a pending move preview.
- Pending movement preview shows:
  - the selected route;
  - the destination tile;
  - MP cost;
  - confirmation copy.
- A second click on the same destination executes the move command.
- Clicking a different legal destination replaces the pending preview.
- Clicking an illegal destination clears the pending preview and shows the rejection reason.
- Switching action clears pending movement preview.
- Move destination reachability should be prepared once when action/state changes, not recomputed per tile during rendering.

## Attack And Skill Preview

- Selecting a targeted attack or skill prepares preview data for targetable unit positions before rendering.
- Preview data must be derived from `CombatResolver.simulate`, not from duplicated presentation rules.
- Legal targets should be highlighted on the terrain tile.
- Rejected targets may be highlighted differently when useful for diagnostics.
- Target preview text should be visible on the unit layer, not only on the terrain tile, because sprites and resource readouts can obscure tile labels.
- Unit-local target preview should show available outcome data:
  - hit chance when a hit roll is resolved;
  - damage when damage is resolved;
  - target HP after damage when shown in inspect/debug detail;
  - short rejection label when command is rejected.

## Rejection Labels

Presentation may shorten resolver rejection reasons for compact UI, but it must preserve meaning.

Current compact labels:

- `target_out_of_range` -> `OUT RANGE`
- `target_not_visible` -> `NO LOS`
- `not_enough_ap` -> `NO AP`
- `skill_on_cooldown` -> `COOL DOWN`
- `target_defeated` -> `DOWN`
- `target_is_ally` -> `ALLY`
- `missing_target` -> `NO TARGET`
- `action_not_available` -> `NO SKILL`

## Acceptance

- Move preview does not spend MP until confirmation.
- Attack/skill preview shows more than a colored tile when a target unit is in range.
- HP/AP/MP readouts must not be the only visible information above a target during attack preview.
- Python validation, Godot project load, and Godot combat slice tests pass after presentation changes.
