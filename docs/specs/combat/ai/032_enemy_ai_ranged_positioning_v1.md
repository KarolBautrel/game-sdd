# 032 Enemy AI Ranged Positioning V1

Status: implemented  
Date: 2026-07-14

## Intent

Enemy AI should not treat every legal ranged attack as equally good.

## Rule

When an enemy has a legal `ranged_attack` target:

- if final hit chance is at least `60`, it shoots;
- if final hit chance is below `60`, it moves toward the target instead.

The final hit chance uses the same modifiers as the resolver:

- base ranged chance;
- attacker accuracy;
- target evasion;
- highground modifier;
- cover modifier.

## Blocked Ranged Fallback

If line of sight is blocked, the target is not a legal ranged target. The enemy uses pathfinding movement instead.

## Deferred

- comparing several targets by expected damage;
- choosing highground before shooting;
- flanking around cover;
- ammunition and reload logic.
