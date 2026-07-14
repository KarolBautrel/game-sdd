# 008 Enemy AI V0

Status: specified  
Date: 2026-07-14

## Intent

Enemy AI v0 gives enemies deterministic behavior for debug and executable combat slices.

It is intentionally simple and should remain predictable until core combat rules are stable.

## Scope V0

When the active unit is an enemy:

1. If a living player is adjacent, the enemy uses `basic_attack`.
2. Otherwise, if it has AP and can move, it moves one legal step toward the nearest living player.
3. Otherwise, it uses `end_turn`.

When the enemy has 0 AP:

- it immediately chooses `end_turn`.

## Movement Choice

- AI movement uses the same legal movement rules as player movement.
- AI can move diagonally.
- The nearest player is selected by Manhattan distance.
- Ties are deterministic by unit id and tile ordering.

## Deferred

- retreating;
- target priority by HP or threat;
- using cover;
- using highground;
- multi-enemy coordination;
- skill selection.

## Extended By

- `030_enemy_ai_ranged_v1.md`
