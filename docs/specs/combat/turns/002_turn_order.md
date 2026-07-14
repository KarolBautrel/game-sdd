# 002 Turn Order

Status: draft  
Date: 2026-07-14

## Intent

Turn order must be deterministic and replayable. The first slice uses initiative sorting at combat start.

## Initial Rule

At combat start:

1. Sort living units by `initiative` descending.
2. Break ties by stable unit id ascending.
3. The first unit becomes active.

## Turn Start

When a unit turn starts:

- AP is restored to `max_ap`.
- temporary turn flags are cleared.
- event `turn_started` is emitted.

## Turn End

A turn ends when:

- the active unit performs `end_turn`;
- the active unit has no legal actions and AI chooses to pass;
- the active unit dies during its own turn.

When a turn ends:

- event `turn_ended` is emitted;
- active index advances to the next living unit;
- dead units are skipped.
- round increments when the active index wraps back to an earlier living unit.

## Round

A round is complete when all living units in the current order have had a turn.

For the first slice, initiative is not recalculated between rounds.

## Acceptance Criteria

### Initiative order

- Given player initiative is 10
- And enemy initiative is 8
- When combat starts
- Then player acts first

### Tie break

- Given `unit_a` and `unit_b` both have initiative 10
- When combat starts
- Then `unit_a` acts before `unit_b`

### AP refresh

- Given a unit has `max_ap` 2
- And its current AP is 0
- When its turn starts
- Then current AP becomes 2
