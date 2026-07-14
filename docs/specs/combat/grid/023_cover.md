# 023 Cover

Status: specified  
Date: 2026-07-14

## Intent

Cover modifies ranged attack resolution and gives tactical meaning to positioning.

## Scope V1

- `cover_low` is a tile type.
- Units may stand on `cover_low`.
- `cover_low` does not block line of sight.
- A unit standing on `cover_low` receives `cover_modifier: -20` when targeted by `ranged_attack`.
- Cover modifies hit chance only.
- Cover does not reduce damage in v1.
- Melee attacks ignore cover.

## Hit Chance

Cover is applied in hit resolution:

```text
final_hit_chance =
  base_hit_chance
  + attacker.accuracy
  - target.evasion
  + terrain_modifier
  + cover_modifier
```

## Deferred

- high cover;
- directional cover;
- cover from adjacent objects;
- flanking;
- cover destruction;
- melee interaction;
- damage reduction from cover.

## Acceptance Criteria

### Cover reduces ranged hit chance

- Given a target stands on `cover_low`
- When it is targeted by `ranged_attack`
- Then `hit_roll_resolved` includes `cover_modifier: -20`
- And final hit chance is reduced by 20
