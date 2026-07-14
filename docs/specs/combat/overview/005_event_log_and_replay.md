# 005 Event Log And Replay

Status: draft  
Date: 2026-07-14

## Intent

Combat must be reproducible from initial state, seed, and command list. The event log is the audit trail for what happened.

## Event Rules

Every event must include:

- `type`
- `sequence`
- `combat_id`

Events that depend on a command must include:

- `command_id`
- `actor_id`

Events that use RNG must include:

- `rng_roll_id`
- `rng_value`

## Initial Event Types

- `combat_started`
- `turn_started`
- `turn_ended`
- `command_rejected`
- `action_performed`
- `unit_moved`
- `damage_applied`
- `status_applied`
- `status_expired`
- `unit_defeated`
- `combat_ended`

## Replay Requirement

Given:

- same encounter definition;
- same RNG seed;
- same ordered command list;

Then:

- final combat state must match;
- event log must match;
- victory/defeat result must match.

## Acceptance Criteria

### Stable event order

- Given a valid basic attack command
- When it is resolved
- Then emitted events have strictly increasing sequence numbers

### Command rejection event

- Given an invalid command
- When it is resolved
- Then event `command_rejected` is emitted
- And no mutation events are emitted

### Replay

- Given an encounter seed and command list
- When replay is run twice
- Then both event logs are identical

