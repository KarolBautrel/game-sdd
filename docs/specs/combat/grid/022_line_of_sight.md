# 022 Line Of Sight

Status: planned  
Date: 2026-07-14

## Intent

Line of sight determines whether a unit can target another unit or tile with ranged actions.

## Planned Scope

- grid ray or line algorithm;
- blockers;
- partial cover interaction;
- target visibility;
- debug visualization;
- validation tests for common geometry cases.

## Deferred Until

- ranged attack rules are specified;
- combat grid supports more tile metadata;
- debug scene can show targeting overlays.

## Initial Questions

- Should units block line of sight?
- Do low cover and high cover differ?
- Are diagonal lines allowed?
- Does line of sight use tile centers or tile edges?

