# 040 Multi Enemy AI Plan

Status: planned  
Date: 2026-07-14

## Intent

Multi-enemy AI should be designed after single-enemy movement, ranged positioning, and obstacle handling are stable.

## Problems To Solve

- two enemies choosing the same destination;
- enemies blocking each other in narrow paths;
- deterministic target choice when several players exist;
- deterministic movement priority when several enemies can approach the same tile;
- ranged enemies choosing firing lanes while melee enemies engage.

## Proposed First Slice

`040_multi_enemy_pathing_and_targeting.md`

The first slice should use two enemies and one player:

- enemy A has a clear path and moves first;
- enemy B must choose a different legal tile;
- both commands must be deterministic;
- no enemy may move onto an occupied destination.

## Deferred

- formations;
- flanking;
- role-based coordination;
- threat scoring;
- focus fire.
