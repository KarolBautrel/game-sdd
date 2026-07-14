# 004 Damage And Statuses

Status: draft  
Date: 2026-07-14

## Intent

Damage and statuses must be deterministic, readable, and easy to validate in tests.

## Damage Formula

Initial melee damage:

```text
max(1, attacker.strength - target.defense)
```

If target has `defending`, reduce final damage by 1 after the minimum calculation:

```text
max(1, base_damage - 1)
```

## HP Rules

- HP cannot go below 0.
- A unit at 0 HP is defeated.
- Defeated units cannot act.
- Defeated units are skipped in turn order.

## Initial Statuses

### defending

Effects:

- reduces incoming damage by 1;
- expires at the start of the status owner's next turn.

Fields:

- `id`
- `duration_rule`
- `source_unit_id`

## Acceptance Criteria

### Minimum damage

- Given attacker strength is 2
- And target defense is 5
- When damage is resolved
- Then damage is 1

### Defending reduction

- Given base damage would be 3
- And target has `defending`
- When damage is resolved
- Then final damage is 2

### Defeat

- Given a unit has 1 HP
- When it receives 2 damage
- Then its HP becomes 0
- And event `unit_defeated` is emitted

