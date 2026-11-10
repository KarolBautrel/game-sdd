# 106 Enemy AI fallback respects remaining movement budget

Status: implemented; three physical budget-edge replays PASS
Date: 2026-11-05
Owners: ../ai/008_enemy_ai_v0.md, ../actions/003_actions.md and ../grid/024_terrain.md.

Full Painted Mine Breach regression after slice105 exposed a fallback first path
step onto2MP highground while only1MP remained. The actor's AP was still positive.
The next command must be legal, not a repeated `not_enough_mp` rejection.

Use slice62's two actors with a full vertical highground strip atx2 between the
enemy at1,1 and player at4,1. At1MP, no affordable approach exists: choose
`end_turn`, preserve position/resources and advance the turn. At2MP, move onto
the strip, pay2MP and preserve AP. With a floor strip at1MP, retain the ordinary
approach. Legacy adjacent movement without MP retains its1AP cost on highground.
Choice is deterministic and does not mutate input. Every returned command passes
the real resolver without rejection.

Automated proof: `combat_playtest_regression_tests.gd`,
`tests/test_combat_playtest_regressions.py` and unchanged full ordinary outcome
requirements in `painted_arena_tests.gd` (Forest/Mine, active/passive policies).
Physical replay uses three static, catalogue-selectable QA encounters derived
from slice62: `qa_ai_budget_highground_1`, `qa_ai_budget_highground_2` and
`qa_ai_budget_floor_1`. Their starting enemy AP is1 and starting/max MP is the
named budget; a full x2 strip has the named terrain. Launch normally, open Tools
and click Enemy AI once, observing resources/position/turn after each decision.
The same files are consumed by the focused Godot regression test. They are
isolated fixtures, not campaign encounters or evidence of an ordinary victory;
there is no runtime state injection or Debug Win. The original default and
production encounter data remain unchanged. Record actual results separately.

Physical2026-11-05 on DISPLAY1: the1MP highground actor passed without moving
or spending AP/MP; the2MP highground actor moved1,1 ->2,1 and spent exactly2MP;
the1MP floor actor made that move for exactly1MP. All retained1AP. Captures and
input trace are linked by docs/qa/2026-11-05-playtest-followup.md. The focused
Godot suite now runs149checks including these exact fixture budgets/terrain.
Feedback/environment tests explicitly own their showcase fixture under
tooling001, so a manual QA scenario override cannot change their assumptions.
