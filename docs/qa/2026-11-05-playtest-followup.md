# Physical play and background combat regressions

2026-11-05, master583ebc84; changes remain local and uncommitted. The user first
released controls, reclaimed them, then gave the requested green light with
"Dobra, kontynuuj". The final section supersedes the earlier stop below.

Current result: physical campaign mine contract, L87-01/L88-01 and all three
L89-01 fixtures PASS. Both post-detour shots pass in the final static bow fixture. No new art
or feature expansion. Own test windows are closed; eight existing profiles and
the accepted terrain/atlas remain byte-identical.

## Ordinary desktop battle

Painted Six - Old Mine, `drawn_roster_skirmish`, seed2001, larger left DISPLAY1:
ordinary victory in round3, Knight14/14, Bran10/14, Torin10/10, Rogue10/10.
Normal UI movement, basic/aimed attacks, Defend, Shield wall and Deep cut were
used. Enemy policy commands ran through Tools / Next turn step. No boosted
statistics, forced terminal state or Debug Win. Stable action slots remained
present after AP depletion; no stuck turn was observed.

This completes the previously interrupted third physical battle, L84-03, on the
stage85/86 source fingerprint
`072abfea07accbc7cf1edcb51c75d23b04813fbf35158caefcff42f4f52fb5c0`.
It predates the two fixes below and is not their post-fix replay.

[Unmodified victory capture](../design/background-polish/2026-11-05/desktop-followup/painted-six-victory.jpg),
[physical receipt](../design/background-polish/2026-11-05/desktop-followup/physical-play-receipt.json)
and [closed combat runtime log](../design/background-polish/2026-11-05/desktop-followup/painted-six-runtime.log).
The source capture contained JPEG bytes despite its initial `.png` name; the
portable copy uses `.jpg` and preserves every byte and its SHA256.

Round1: Knight approached and hit the southern axe twice. Bran used Shield wall
and Defend. Torin's basic shot from7,5 at10,8 correctly reported blocked LOS,
but Aimed shot incorrectly passed and killed the wounded axe. Rogue approached
and defended. A spearman also spent MP after exhausting AP.

Round2: Knight detoured around a blocked cell and killed the southern spear.
Bran's Deep cut/basic attacks, Torin's two basic shots (one hit, one miss) and
Rogue's two attacks killed the northern axe. The remaining spear hit Bran twice,
exhausted AP, then moved12,5 ->11,5 ->10,5 ->9,5 ->8,5 toward other heroes.
Round3: Knight moved8,7 ->8,6 and killed the final spear with two ordinary hits.

## Bounded fixes, stages87..89

- Combat grid022/actions063, slice104: basic and aimed shots now share terrain
  LOS rejection in both GDScript and Python. Intermediate rocks reject before
  AP, cooldown and hit/intercept rolls; the real HUD preview uses the same
  resolver. Clear floor/highground/cover lines and endpoint exclusions remain
  legal, with out-of-range rejection retaining precedence.
- Combat ai008/030, slice105: an enemy with zero AP immediately ends its turn,
  even with MP left. The guard precedes target/skill/path selection for melee
  and ranged actors. Positive-AP approach/attack and manual zero-AP player
  movement with MP remain available under their existing rules.
- Combat ai008, slice106: full Mine regression exposed a fallback first path
  step onto2MP highground while only1MP remained. It now passes normal move
  validation before selection; no affordable approach means end-turn. Affordable
  MP moves and legacy1AP steps remain unchanged. This is a prerequisite legality
  fix, not a change to tactical roles or terrain costs.

The first Python regression run reproduced13 failing subtests before the fixes.
The initial Godot harness also caught the defects; four additional checks needed
scalar coordinate/resource comparisons instead of typed integer/JSON-float
Dictionary equality. The corrected focused suites pass:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -p test_combat_playtest_regressions.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://scripts/domain/combat_playtest_regression_tests.gd
```

The original stage87/88 suite passed Python6/6 and Godot116/0. Expanded coverage
after the full Mine failure passes Python7/7 tests and Godot137checks/0failures.
The new weighted-budget case failed in both implementations before its fix.
These cover equipment/fallback bow
profiles, atomic rejection and actual HUD preview, clear/blocked endpoints,
melee/ranged AI with adjacent/distant/multiple targets, deterministic read-only
command selection, normal move/attack/pass, preserved manual MP movement and
weighted fallback affordability at1MP/2MP plus legacy1AP movement.

## Full verification

First full-source run: `playtest-followup-final`,89/90PASS, one failed suite:
`painted_arena_tests`. A positive-AP actor with1MP repeatedly chose a2MP step,
emitting `not_enough_mp`. This produced765 downstream assertions from one stuck
Mine battle. The failure is retained in that immutable run; it led to stage89.
The independent Python reproduction also failed at Mine command40 for the same
unaffordable-move reason. Expected Forest/Mine active/passive outcomes were not
relaxed, and no fixture stats/terrain were altered to make the battle pass.
[Retained failed-run receipt](../design/background-polish/2026-11-05/desktop-followup/first-full-failed.json).

After stage89, the original Godot arena suite passes1415checks/0failures: Forest
active-policy victory32commands / passive defeat106; Mine victory47 / defeat103.
The Python mirror independently completes the same four outcomes in34/106/50/103
commands with no rejected commands. Existing deterministic roll behavior differs
between implementations; no roll-equivalence claim is made.
[Godot receipt](../design/background-polish/2026-11-05/desktop-followup/godot-arenas.json),
[Python receipt](../design/background-polish/2026-11-05/desktop-followup/python-arenas.json).

Final full-source run: `playtest-followup-affordability-final`.

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id playtest-followup-affordability-final
```

Final90/90 PASS,0errors/0warnings, including75Python tests, the focused137Godot
checks, every discovered Godot suite and nine scene boots. Started
2026-11-05T11:32:40Z; finished11:38:19Z. Source SHA256:
`ab530fde0f2cc6ec6d7f616326b298dc0ff29703773d3b9a8b978874be86b2f9`.
The source fingerprint matches after the run and evidence copy.
[Complete verification receipt](../design/background-polish/2026-11-05/desktop-followup/source-verification.json),
[focused Godot output](../design/background-polish/2026-11-05/desktop-followup/focused-godot.stdout.log),
[Python test output](../design/background-polish/2026-11-05/desktop-followup/python-tests.stderr.log).
`git diff --check` passes; Git's CRLF normalization notices are not content errors.
Logs remain in `artifacts/qa-runs/playtest-followup-affordability-final/`. Run identifiers are
immutable; use a fresh name when repeating.

## Campaign attempt and remaining acceptance

A fresh QA profile20261106 / Marches / Large, Northbarrow Highlands, was opened
after closing only the completed standalone battle. It stopped paused at
Ravenford, Contracts tab, before accepting the mine job: Day1 08:00,80g,Food16,
Fatigue0. Its profile is
`user://qa_living_world_generated_v2_marches_20261106.json`.
No ordinary campaign contract victory is claimed. Do not send input to its
possibly still-open window while the user uses the computer.

Eight existing save/profile files matched their saved pre-attempt SHA256 values
both when preparing the physical receipt and after full verification; names
and comparisons are in the physical/preservation receipts. The new profile is
QA-only. No accepted art or terrain edits
were made in stages87..89. Stages85/86 and their earlier native receipts remain.
The designer revision9 mask and approved world atlas match their established
SHA256 values byte-for-byte; [preservation receipt](../design/background-polish/2026-11-05/desktop-followup/preservation.json).

Deferred physical checks, all explicitly separate from automated PASS:

1. L87-01: behind a rock, basic and aimed shot both reject without spending
   AP/cooldown; move around it and obtain a legal firing lane.
2. L88-01: spear uses its last AP and passes instead of circling with leftover MP.
3. L89-01: positive AP with1MP cannot choose a2MP highground step; affordable
   approaches remain available, and an unaffordable approach passes without cost.
4. L77-01: fresh profile contract acceptance, ordinary travel/preparation/mine
   victory/loot/return/report/reload, plus the remaining world checks.
5. User review of Large-map composition, movement/feet and painted tactical props.

Later launch, only when the user is ready:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario drawn_roster_skirmish
& .\tools\qa\start_game.ps1 -Scene regions
```

## Resumed desktop follow-up: current result

The user renewed desktop permission. All play used the larger left DISPLAY1,
normal UI controls and separate QA saves. [Structured physical receipt](../design/background-polish/2026-11-05/interactive-acceptance/receipt.json),
[input trace](../design/background-polish/2026-11-05/interactive-acceptance/input-trace.json)
and [preservation receipt](../design/background-polish/2026-11-05/interactive-acceptance/preservation.json)
are retained with raw JPEG captures and five closed runtime logs (zero errors /
warnings). Eight existing profiles, designer revision9 and the world atlas match
their baseline SHA256 values.

Post-fix Painted Six seed2001 won round3 with Knight14/14, Bran12/14, Torin2/10
and Rogue10/10. One input during a transition accidentally skipped Axe I's first
turn. This replay is useful regression evidence but is excluded from clean
ordinary-enemy-policy victory claims. The earlier L84-03 victory remains intact.

- Initial L87-01 replay PARTIAL (subsequently completed below): Torin at7,5 targeting10,8 saw blocked LOS for both basic and
  Aimed shot, without losing AP/cooldown. A clear Aimed shot at11,6 and basic
  shots after an actual detour worked. The literal same-target clear Aimed shot
  after that detour was not repeated because its cooldown was active. Keep this
  narrow physical gap rather than infer it from automated tests.
- L88-01 PASS: spear at10,5 attacked Bran until AP0, retained3MP and immediately
  passed to the next actor without moving. A later spear and the campaign mine's
  ranged actors also passed after their final attack with MP left.
- L89-01 PASS: three static catalogue fixtures, inspected with Enemy AI once.
  At1MP, highground caused a cost-free pass; at2MP the actor moved1,1 ->2,1 and
  spent2MP; with1MP on floor that move spent1MP. All retained1AP. These fixtures
  also feed the focused149-check Godot suite and do not change campaign data.

### Actual campaign mine contract

The old20261106 profile was already exhausted in the pre-input baseline:
0g/Food0 and tick22464. Its earlier Day1 handoff description was stale; this is
not evidence of an offline-progress defect. It was not reset. A genuinely fresh
20261107 / Marches / Large QA region, Ashenvale Highlands, started at80g,16Food,
Day1 08:00 and fatigue0 in a separate size-aware save.

Accepted Reopen the Old Mine in Ravenford, travelled normally, prepared owned
supplies at7/7, switched to Use Old Mine without losing that context and started.
Entrance -> Dusty Crossing (Move on at the shrine) -> Guarded Cache. The actual
mission combat won in round3 with Bran12/14 and Torin4/10, all enemy turns run
through their AI decisions. Normal movement, ranged/basic/Aimed attacks and
Defend only; no Debug Win, skipped enemy turn or state injection. [Victory capture](../design/background-polish/2026-11-05/interactive-acceptance/campaign-mine-ordinary-victory.jpg).

Claimed7g/12XP/rusty_key once, exited through Lower Exit, finished4/7 visited,
and returned to the living world with the mine restored. Contract was Ready to
Report and unpaid at the mine. Travelled back to Ravenford and collected exactly
45g/20XP/+10River League. A second report attempt changed no bytes. Closed and
restarted through Region Foundry, selected the same seed/preset/size and resumed:
117g,32XP, cleared mine, completed contract, same paused Day6 09:30 and party.
After-report, duplicate-attempt and after-reload saves share SHA256
`363737bb7404862d59b5bcb04dfc54d0d140f0322eb97787e734461cace5c86d`.
[Compact before/after/reload facts](../design/background-polish/2026-11-05/interactive-acceptance/campaign-report-reload.json).

Operator observation latency at4x advanced unused calendar time before pausing;
finalFood1/fatigue73 is not a balance or travel-pace acceptance. This completes
L77-01's mine-contract subcase, not its delivery/recon/camping/raids/world cases.

### Verification and remaining scope

Runtime play used stage87..89 source `ab530fde...`; later additions are isolated
QA resources/assertions and deterministic test setup. Full run
`physical-followup-fixtures-final` initially passed88/90. Feedback and environment
tests inherited the manually selected tiny QA encounter, violating their terrain
and outcome assumptions. They now explicitly load full_combat_showcase after
initialization, per tooling001, retaining every assertion. With the QA override
still selected, feedback179 and environment124 checks pass. Focused domain149
checks and Python7/7 also pass. Both failed and final full-run receipts are saved
alongside the captures; see `verification.json` for the latest exact results.

Next: ordinary delivery/recon and the other open L77-01 subcases. Some Painted Six preview labels
appeared to show2 damage before3 applied; retain the capture and reproduce this
in isolation before treating it as a confirmed defect. Campaign Aimed4 and
melee5 matched their previews. User visual/motion/prop approval remains separate.
No commit or push was requested.

### Final L87-01 detour proof

The literal gap is now closed on static catalogue fixture qa_bow_los_detour,
derived from slice63 with original bow profiles/stats,2AP/3MP and a blocked2,1.
Actor1,1 and target4,1: basic and Aimed both reject without cost. In two separate
UI runs, ordinary move preview/confirmation reaches3,2 for3MP and keeps2AP.
Aimed then hits that same target for5 (10->5HP), spending2AP; after normal Load,
basic follows the same detour and hits for3 (10->7HP), spending1AP. Both displayed
damage previews match actual damage. Raw detour-* captures and the trace are in
the evidence folder. L87-01 PASS. This legacy fixture has generic Bran artwork
despite the hunting_bow loadout; it verifies LOS, not weapon art or an ordinary
victory. No production encounter or runtime gameplay changed. Focused Godot
coverage now161checks; final full verification includes that exact fixture.

## Final exact-source verification

```powershell
.\.venv\Scripts\python.exe tools/qa/verify_project.py --run-id physical-followup-complete-final
```

Final90/90 PASS,0errors/0warnings,75Python tests,161focused Godot checks,
all discovered suites and nine scene boots. The manual bow QA scenario remained
selected throughout, proving deterministic feedback/environment test setup.
Started 2026-11-05T17:01:56.192278+00:00; finished 2026-11-05T17:07:03.203787+00:00. Source SHA256 `f0d2a9b6c8579856490a03ddd26aa62e431715b82167a5ec36fca77dd56ac5ce` matches after
the run. Eight existing saves and accepted terrain/atlas hashes still match.
[Full final receipt](../design/background-polish/2026-11-05/interactive-acceptance/verification.json).
Failed fixture-override and interim PASS reports are retained beside it.
`git diff --check` passes. No commit/push; changes remain local on master.
