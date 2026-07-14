# 048 Special Skills V1

Status: implemented  
Date: 2026-07-14

## Intent

Introduce the first explicit special combat action without building the full skill tree yet.

## Rules

- `power_strike` is a melee special action.
- `power_strike` targets one adjacent enemy.
- `power_strike` uses the same target validation as melee attacks.
- `power_strike` can be driven by a weapon profile.
- In slice 048, `power_strike` costs 2 AP and applies weapon-profile damage bonus.
- Using `power_strike` applies `skill_cooldown` to the actor.
- `skill_cooldown` stores `action_id`, `remaining_turns`, and `duration_rule`.
- Cooldown ticks down when the affected unit's own turn starts.
- A skill on cooldown is rejected with `skill_on_cooldown`.
- Enemy AI may use `power_strike` when adjacent to a player, but only when:
  - the action is available;
  - the actor has enough AP;
  - the action is not on cooldown;
  - deterministic AI decision roll passes the configured chance.

## Non-Goals

- skill unlocks;
- non-cooldown status effects;
- area-of-effect targeting;
- animation.
