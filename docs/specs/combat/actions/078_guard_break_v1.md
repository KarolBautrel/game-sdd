# 078 Guard Break V1

Status: implemented
Date: 2026-07-15

## Purpose

Add the first simple control/debuff status after bleeding proves over-time status infrastructure.

`guard_break` is a melee action that damages a target and applies `guard_broken`. While active, `guard_broken` lowers the target's effective defense, so follow-up attacks hit harder.

## Rules

- `guard_break` targets one adjacent enemy.
- `guard_break` uses normal melee target validation.
- `guard_break` costs AP from its action profile.
- On hit, `guard_break` applies normal damage.
- If the target survives, it applies `guard_broken`.
- `guard_broken` stores:
  - `id: "guard_broken"`;
  - `source_unit_id`;
  - `remaining_turns`;
  - `duration_rule: "own_turn_starts"`;
  - `defense_modifier`, usually negative.
- Attack damage uses effective target defense:

```text
max(0, target.defense + sum(status.defense_modifier))
```

- The status expires on the affected unit's own turn start according to the shared status duration rule.

## Presentation

- `status_applied` for `guard_broken` creates floating `GUARD BROKEN` text through the shared floating text helper.
- A guard-broken unit shows a compact status icon until the status expires.
- Target preview for follow-up attacks uses effective defense and therefore shows the higher damage before the click.

## Acceptance Slice

```text
docs/specs/combat/slices/078_guard_break_v1.md
```

## Non-Goals

- armor break or permanent defense damage;
- shield-specific reactions;
- AI preference for guard break;
- stacking multiple guard breaks;
- animation-specific guard break pose.
