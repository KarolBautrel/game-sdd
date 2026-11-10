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
- This policy also applies when the enemy still has independent MP. It must not
  approach a different player or spend its remaining MP after exhausting AP.
- This is an AI decision rule, not a restriction on manual MP movement: a player
  may still move with remaining MP after spending AP under actions003.

## Movement Choice

- AI movement uses the same legal movement rules as player movement.
- Every chosen destination, including a fallback first path step, must pass
  normal move validation with the actor's remaining resources. A walkable
  highground step costing2MP is unavailable at1MP; if no affordable approach
  exists, choose `end_turn` instead of repeatedly submitting an invalid move.
- Legacy units without MP retain their existing1AP adjacent-step movement.
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
- Regression slice105 covers MP-enabled melee/ranged actors and the transition
  from a normal move-and-attack turn to immediate `end_turn`.
- Regression slice106 covers an unaffordable weighted-terrain fallback step.
  Its three explicit QA catalogue fixtures expose the same budget boundary in
  the normal debug scene; they do not change production AI or encounter balance.
