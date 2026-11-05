# Stage82 tactical locomotion

Owners presentation041/slice041. Translation rate1.18, same physical160px stride;
walk frame is driven by root displacement, with per-actor phase carried between
orders. Reset kills tweens/phase and rejects stale callbacks. Original PNG/ASE,
source durations, idle/attacks, facing and domain MP/path/outcomes unchanged.

Baseline/candidate path: Forest knight(2,7)->(4,7),280logical pixels,2MP.
Before1.75s; candidate1.48305s. No stride stretch. The focused test exposed a
one-frame phase reset at the start of a second order; initializing from carried
distance before the first tween fixed it.4643checks pass across30/60/144FPS and
two actual HUD orders/reset, plus1887enemy-pilot and313battle-review checks.

Native `locomotion-native-exercise`: PASS,12engine-local clicks,8GPU captures,
720p/1080p,0errors/warnings, realMove preview/confirm for both arenas. Report:
artifacts/qa-runs/locomotion-native-exercise/native-review.json. These are native
control/end-state samples, not continuous-video proof or user feel acceptance.

Actual Sky desktop: normal Forest Ambush baseline and candidate both used the
same two-cell move. Candidate reached(4,7),MP2, then ordinary End turn selected
Bran. No stuck animation/turn. Number-key input did not submit the action in the
observed setup; clicking the visible action works. Complete physical battles
continue in stage84. Larger full regression receipt follows after stage83.
