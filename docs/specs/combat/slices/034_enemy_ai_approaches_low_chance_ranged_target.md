# 034 Enemy AI Approaches Low Chance Ranged Target

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemy AI does not always shoot just because a ranged attack is legal.

## Expected Result

- player stands on `cover_low`;
- enemy has a legal ranged shot, but final hit chance is below the AI shooting threshold;
- AI chooses `move` instead of `ranged_attack`;
- enemy moves to `{ "x": 3, "y": 1 }`.
