# 105 Enemy AI ends an exhausted turn with MP remaining

Status: implemented; post-fix physical replay PASS
Date: 2026-11-05
Owners: ../ai/008_enemy_ai_v0.md and ../ai/030_enemy_ai_ranged_v1.md.

Given an active melee or ranged enemy with zero AP and positive MP, command
selection returns `end_turn` without modifying its input. Cover adjacent and
distant players, plus a mixed roster with several potential pursuit targets.
Submission advances to the next living unit, preserves the spent actor's MP
and position, and emits no movement or attack. The choice is deterministic.

Retain normal slice62 move-then-attack behavior while AP is positive. After the
attack consumes the last AP, the next command is `end_turn`. Manual player
movement with zero AP and positive MP remains legal and costs only MP.

Automated proofs: `scripts/domain/combat_playtest_regression_tests.gd` and
`python -m unittest discover -s tests -p test_combat_playtest_regressions.py`.
Physical replay: Painted Six spearman attacks then passes, instead of circling
to other heroes with its leftover MP. On2026-11-05, Painted Six seed2001's
spearman at10,5 spent its last AP attacking Bran, retained3MP and passed
immediately without moving. A second spear and the actual campaign mine's
ranged enemies also passed at zero AP with MP left. See the interactive receipt
linked by docs/qa/2026-11-05-playtest-followup.md.
