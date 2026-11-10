# 104 Aimed shot terrain visibility regression

Status: implemented; physical blocked and same-target clear-after-detour replay PASS
Date: 2026-11-05
Owners: ../grid/022_line_of_sight.md and ../actions/063_aimed_shot_v1.md.

Use the existing slice63 bow encounter with an intermediate blocked tile.
Both basic and aimed-shot preview must reject `target_not_visible`. Submission
must leave unit resources/statuses/positions and turn state unchanged, emit no
action/hit/intercept/cooldown events, and retain the original random seed.
Prove both equipment-granted and fallback aimed profiles. Clear floor,
highground and cover lines remain legal; endpoints do not block themselves.
An out-of-range target retains `target_out_of_range` precedence.

Automated proofs: `scripts/domain/combat_playtest_regression_tests.gd` and
`python -m unittest discover -s tests -p test_combat_playtest_regressions.py`.
Both use the real GDScript/Python resolvers, including the shared preview gate.
Physical replay: Torin behind rocks in Painted Six must see the same blocked
target for basic/aimed shot, then obtain a legal target by moving around them.
On2026-11-05, post-fix Painted Six seed2001 physically rejected both shots at
the same blocked target without spending AP/cooldown. Clear Aimed shot at a
different target and basic shots after a real detour also passed. The initial Painted Six replay did not repeat clear Aimed at the same target
after detouring because its cooldown was active. The fixture below subsequently
closed that exact gap; the original partial observation remains recorded.
See docs/qa/2026-11-05-playtest-followup.md and its interactive receipt.

To close that literal subcase, `qa_bow_los_detour` is a static catalogue fixture
derived from slice63: bow actor1,1 with normal2AP and3MP, target4,1, blocked2,1,
otherwise floor. It retains the original bow profiles/stats. Both shots must
reject before movement; a normal move to3,2 goes around the rock for3MP and
keeps2AP. Try a legal basic shot, then reload the fixture and repeat the detour
with Aimed shot instead. Two independent runs avoid a cooldown/AP conflict.
The real resolver and HUD preview are used; this proves LOS rather than an
ordinary victory. Production encounters and campaign saves remain unchanged.

Physical fixture result2026-11-05 PASS: both blocked shots retained2AP/3MP.
Each independent run moved normally to3,2 for3MP. Aimed hit the same target for5,
spent2AP; after Load, basic hit for3 and spent1AP. Preview damage matched both.
The fixture retains generic legacy Bran artwork despite its bow loadout; no
weapon-art or ordinary-victory acceptance is inferred. Focused161checks PASS.
