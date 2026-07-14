# 003 Combat Actions

Status: draft  
Date: 2026-07-14

## Intent

Actions are data-driven commands available to units. The first slice needs three actions.

## Initial Actions

### Move

Purpose: change unit position on the combat grid.

Rules:

- actor must be active unit;
- actor must be alive;
- destination must be inside grid;
- destination must be walkable;
- destination must be unoccupied;
- path length must be less than or equal to remaining move allowance;
- legacy units without `resources.mp` spend 1 AP and may move only one adjacent tile;
- units with `resources.mp` spend MP equal to path length and do not spend AP for `move`;
- multi-tile movement emits `unit_moved.path` so presentation can animate each step.

### Basic Attack

Purpose: deal melee damage to one adjacent enemy.

Rules:

- actor must be active unit;
- actor must be alive;
- target must be alive;
- target must be enemy team;
- target must be in range 1 by Chebyshev distance;
- actor must have required AP;
- damage is resolved by the damage spec.

### Defend

Purpose: spend AP to gain a temporary defensive state.

Rules:

- actor must be active unit;
- actor must be alive;
- actor must have required AP;
- status `defending` is applied until actor's next turn starts.

### End Turn

Purpose: pass control to the next living unit.

Rules:

- actor must be active unit;
- actor must be alive.

## Acceptance Criteria

### Move command

- Given the active unit has 1 AP
- And the destination is adjacent, walkable, and empty
- When it performs `move`
- Then AP is reduced by 1
- And the unit position changes
- And event `unit_moved` is emitted

### MP move command

- Given the active unit has 1 AP and 3 MP
- And a legal two-step path exists to the destination
- When it performs `move`
- Then AP is unchanged
- And MP is reduced by 2
- And the unit position changes to the destination
- And event `unit_moved` includes the two-step path

### Attack command

- Given the active unit has 1 AP
- And an enemy is adjacent
- When it performs `basic_attack`
- Then AP is reduced by 1
- And damage is applied
- And events `action_performed` and `damage_applied` are emitted

### Defend command

- Given the active unit has 1 AP
- When it performs `defend`
- Then AP is reduced by 1
- And status `defending` is added
- And event `status_applied` is emitted
