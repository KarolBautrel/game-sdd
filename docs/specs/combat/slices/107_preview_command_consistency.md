# 107 Preview and committed command consistency

Date:2026-11-09. Owner: ../presentation/068_combat_interaction_preview.md.
Status: headless475checks /40cases PASS; desktop tests explicitly deferred.

Investigate the earlier tentative Painted Six observation of2preview damage
before3applied without assuming a confirmed defect. Use the actual CombatDebug
scene headlessly with isolated in-memory snapshots of its accepted roster.
Retain real weapon profiles/stats. Position attacker/target adjacently on clear
floor to isolate damage, and cover Torin basic/Aimed, Rogue melee, Bran melee
and Knight melee, normal/near-death targets and multiple next-command indices,
including a deterministic basic-shot miss and basic-to-Aimed shortcut switching.

For each case, select through the actual primary action control, inspect the
rendered target Label, submit the very same next command, await real animated
commit and compare hit/miss, AP, resolved damage, target HP and seed. Repeated
preview calls preserve the input snapshot. A dead target loses its target panel.
Record the exact case data so a non-reproduction is not presented as a fix.
Also retain blocked bow rejection and post-detour legal-shot coverage.

Proof: `scripts/presentation/combat_preview_consistency_tests.gd`, existing
targeting/feedback/lifecycle suites and combat slices. This is headless scene /
resolver evidence, not OS input, visual acceptance or an ordinary victory.

The40cases did not reproduce the tentative2-versus3discrepancy. Torin basic2 /
Aimed3 and Rogue melee3 matched the actual labels and committed damage. Basic
command599 misses on roll92 and shows no invented damage; basic-to-Aimed number
shortcuts also refresh correctly. Near-death fixtures preserve resolved damage
even when HP clamps at0. No damage/resolver/animation change was made. Retain the
earlier physical observation as unconfirmed, not as a fixed defect.
