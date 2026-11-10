# Physical mine contract and combat regression replays

Latest user instruction: "Dobra, kontynuuj" renews the previously withheld
permission for desktop testing. The bounded follow-up is recorded below. Own
test windows are closed. No new commit/push request: all changes remain local
on master583ebc84. Do not restart an expired two-hour feature queue or redesign
accepted art.

Read [the QA report](../qa/2026-11-05-playtest-followup.md),
[current physical receipt](../design/background-polish/2026-11-05/interactive-acceptance/receipt.json)
and [earlier ordinary victory receipt](../design/background-polish/2026-11-05/desktop-followup/physical-play-receipt.json).

## Current result

- Earlier third ordinary desktop victory: Painted Six seed2001, round3,
  Knight14/14, Bran10/14, Torin10/10, Rogue10/10 on stage85/86 source. L84-03 PASS.
- Stage87 / combat104 restores shared basic/Aimed terrain LOS in both resolvers,
  with atomic blocked rejection and normal clear/endpoint behavior. Physical
  L87-01 PASS: blocked basic/Aimed rejection plus both same-target clear shots
  after a3MP detour in static qa_bow_los_detour. Aimed5damage/2AP, basic3/1AP.
  Original bow profiles/stats; independent Load avoids cooldown/AP conflict.
- Stage88 / combat105 restores immediate enemy end-turn at AP0 despite MP left.
  Physical L88-01 PASS: spear at10,5 retains3MP after attacking Bran and passes
  without circling. Other spear and campaign ranged enemies also passed normally.
- Stage89 / combat106 fixes fallback movement choosing an unaffordable2MP step.
  Physical L89-01 PASS in all three static catalogue fixtures:1MP highground
  passes unchanged,2MP highground moves for2MP,1MP floor moves for1MP. All keep1AP.
- The post-fix Painted Six replay won round3 with all four survivors, but an
  input during a transition accidentally skipped one Axe I turn. Exclude that
  replay from clean ordinary-policy victory evidence; it does not replace L84-03.
- Actual campaign mine contract completed normally on separate fresh20261107 /
  Marches / Large, Ashenvale Highlands: accepted job, travelled, owned7/7 packing,
  Use Old Mine, two-hero ordinary victory round3 (Bran12/14, Torin4/10),7g/12XP/key
  loot, Lower Exit completion, mine restored, return Ravenford, report45g/20XP /
  River League+10. Every enemy turn used AI. Duplicate report and disk reload
  leave exactly the same bytes:117g,32XP, paused Day6 09:30, completed contract.
  L77-01 mine-contract subcase PASS; broader delivery/recon/world cases stay open.
- Eight existing profiles, accepted terrain revision9 and world atlas remain
  byte-identical. No art, sprite or movement change in this follow-up. Five
  closed physical runtime logs contain zero errors/warnings.
- Focused161Godot checks /7Python tests PASS. Four static QA encounters are
  isolated from production. Full validation found two test fixtures inheriting
  a manual launcher scenario; tooling001 now requires explicit setup. All prior
  assertions remain. Feedback179/environment124 checks pass with QA override
  selected. Latest full results and source identity are in the QA report's
  durable verification.json; preserve earlier failed receipts too.
- Stable action slots / owned preparation stages85/86 remain intact. User visual
  approval of larger maps, foot cadence and tactical props is still pending.

## Exact stop and next work

QA profile `user://qa_living_world_generated_v2_marches_20261107.json` is paused
in Ravenford, Day6 09:30,117g, Food1, fatigue73, mine restored and contract paid.
The game was closed after exact reload verification. 4x operator observation
latency advanced unused calendar time; do not treat the final supplies as travel
balance acceptance.

Correction: the earlier20261106 Day1 stop description was stale. Its pre-input
baseline in this resumed batch already had0g/Food0 and tick22464. No offline
progress defect is inferred. The profile was not reset; a new seed was used.

Next bounded work:
1. Reproduce the tentative Painted Six damage-preview discrepancy in isolation
   before declaring a bug. A label appeared to show2 before3 applied; campaign
   Aimed4 and melee5 matched their previews.
2. Continue ordinary delivery/recon and remaining L77-01 world cases on an
   isolated QA profile, respecting the current desktop permission at resume.
3. User review of map composition, natural movement and painted props stays
   separate from automated/agent gameplay results.

No new feature or art expansion is needed for this follow-up. Commit/push only
upon a fresh explicit request. Preserve all local stages85..89.

Launch from repository:

```powershell
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
& .\tools\qa\start_game.ps1 -Scene regions
```
