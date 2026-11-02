# Slice054: generation quality

Owner: ../overview/046_generation_quality_gates.md

| ID | Scenario | Expected |
| --- | --- | --- |
| G5-01 | accepted/candidate/missing-status pools | only accepted selected; no implicit promotion |
| G5-02 | broken graph mutations | duplicate/disconnected/dangling/start/exit/content errors rejected |
| G5-03 | 100 seeds x3 profiles, twice each | deterministic, connected, valid encounter paths, >=3 template variants/profile |
| G5-04 | no valid accepted template | no usable generated draft |
| G5-05 | actual D1/D2/D3 and reroll | visible valid graphs and ordinary expedition interaction |

Proof: scripts/domain/dungeon_generation_quality_tests.gd, tests/test_dungeon_quality.py,
stage5 report and full verification runner. Runtime checks do not use Debug Win.
