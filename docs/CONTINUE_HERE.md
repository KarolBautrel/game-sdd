# Continue development here

Last handoff: 2026-11-02. This is a status/navigation document; owning domain
specs define behavior. This handoff does not authorize additional implementation
when the user has only requested an explanation or plan.

## Current task: stages27..29 implemented; next is physical acceptance

User resumed2026-11-02 and requested completing outstanding work and the earlier
repository push. Stage26 campaign appearance was approved. Presentation007/slice007
and milestone002 own the completed dungeon/battle extension. Read
[stage29 report](qa/stages/2026-11-02-stage-29.md):51/51 source checks, strict2094 files,
final release and packaged native play/campaign104 clicks/51 captures all PASS.
Runtime catalogue1889 PNGs;91-file editable/source/export art manifest.

Latest build: artifacts/export-smoke/stage29-release-20261102/sdd-game.exe plus
adjacent PCK/owned windowed App profile/notices. Native previews and commands:
[play UI notes](design/play-ui/README.md). Includes named-room parchment dungeon,
scrolling preparation/events and board-preserving battle portrait/resources/action
inspector/chronicle/costed actions/Tools; fixed actors vanishing after scenario reload.

Next unfinished work is46 NOT_RUN [live cases](qa/live-test-scenarios.md). Wait for
explicit physical mouse/keyboard/focus release, then windowed larger left DISPLAY1,
protected saves, physical input/resize, ordinary battles, normal return/settlement/
restart and closed-log audit. Native fixtures do not count as ordinary play.
Do not start another UI rewrite or content batch first. The user authorized
commit/push after checks; exact checkpoint is in Git/tracking and final handoff audit.

## Prior task: dark fantasy UI stages23..26 implemented; live acceptance pending

The latest user request on2026-11-02 authorizes the complete research proposal:
install the two UI skills, add useful libraries, create/choose inventory concepts,
ship a coherent art family, implement inventory and parchment map, extend the
style to campaign screens, verify and export. Read
[the ordered UI milestone](specs/presentation/milestones/001_dark_fantasy_ui.md),
presentation006 and slice006 before continuing. The dark fantasy inventory and
parchment map are the user's selected visual references. Background work and
deferred physical desktop tests still apply; no mouse/keyboard/focus release.

Implementation: game-ui-ux/godot-ui-control installed and read, Godot MCP75 tools
configured/tested, Kenney/Shikashi/ThemeGen/fonts integrated. Three concepts saved;
A selected. Coherent Aseprite art, inventory, parchment map, town/trade/training
and native GPU review are implemented. Read [stage26 report](qa/stages/2026-11-02-stage-26.md)
for final evidence and build hashes. Latest build:
`artifacts/export-smoke/stage26-release-final-20261102/sdd-game.exe` with adjacent
PCK and owned windowed App profile. Starts in the campaign map on DISPLAY1.

Next unfinished work is physical acceptance:38 NOT_RUN cases in
[live registry](qa/live-test-scenarios.md). Preserve existing dirty work and saves.
Wait for control release, then actual pointer/keyboard/hover/focus, resize, ordinary
equipped victory/return/trade/train/restart and closed-log audit. Do not start
another UI rewrite or claim user visual approval from native fixture PASS.
Future campaign UI changes follow [the recorded tool/art workflow](design/campaign-ui/TOOLING.md).

## Research baseline: current appearance rejected

On2026-11-02 the user rejected the current UI appearance and requested thorough
internet research into references, assets, generators, skills and MCP. Read
[the UI research and proposed sequence](qa/2026-11-02-ui-design-research.md).
That research preceded the implementation authorization above. Its proposed
concept/material/tool sequence has now been executed. Earlier technical proofs
remain historical; physical acceptance is still pending. No GUI control was
released, and the desktop/save policy remains in force.

## Technical baseline: UI polish stages20..22 implemented; actual acceptance pending

User authorized the full UI polish plan on2026-11-02. Owners shared
presentation003/004/005 and slices003/004/005. In order: stage20 visual inventory/
portrait-slot editor and compact shell46/46;21 visual trading/training47/47;
22 town/service tiles/interactive landmarks/final review48/48. All automated PASS,
all actual acceptance AWAITING_INTERACTIVE. Existing campaign v4/domain rules
unchanged. The latest [stage22 report](qa/stages/2026-11-02-stage-22.md) records
acceptance, review defects/fixes, exact commands and build identity.

Use `artifacts/export-smoke/stage22-release-fixed-20261102/sdd-game.exe` plus
adjacent PCK/owned window profile. Source
`artifacts/qa-runs/stage22-fixed-headless-20261102/report.json`:48/48,46 Python
tests,2223 UI assertions,0 diagnostics; strict checker2032 files and fresh corrected
EXE probe PASS. Earlier stage22-release is superseded (collapsed tile labels).
Final proof includes actual tile purchases/equipping/retained Torin selection and
map-marker travel to pending Cart, in-memory only. Start EXE, F7 / World-Ravenford.

Next unfinished task: [live registry](qa/live-test-scenarios.md),30 NOT_RUN cases
across stages8..22. No GUI activation/input while user uses PC. When they release
controls, use windowed larger left DISPLAY1 and safe saves, native UI/pointer/
focus/motion review plus ordinary battle/trade/train/return/restart/log audit.
Do not count offline reconstructed previews or headless geometry as native visual
acceptance. Fix/retest/re-export observed defects. No commit/push without request.
Further game content is outside this completed UI batch.

Current UX: inventory category tabs/icon grid, portrait hero picker, named slots,
authored metadata comparisons and persistent local hero/item/filter; trading uses
visual stock/free-loot grids; training shows tier/delta/XP bars. Compact counters,
region-only party rail, warm heading typography/existing ornament frame, city
supply tiles and guarded landmark travel. No legacy form dropdowns were kept.

## Prior technical baseline: stages18 progression/19 campaign interfaces

User authorized further code/automation and specifically reprioritized polished
campaign interfaces. Implemented18 party advancement and19 shared UI (the earlier
second-location proposal is still future scope). Owner world007/slice007/combat103,
shared presentation002/slice002. [Stage19 report](qa/stages/2026-11-01-stage-19.md)
records final build and all acceptance. Source
`artifacts/qa-runs/stage19-verified-20261101/report.json`:45/45 PASS,45 Python
tests/1219 UI checks/33 progression checks,0 diagnostics. Strict checker2022 files
and final extended EXE probe PASS. Historical stage19 build:
`artifacts/export-smoke/stage19-release-final-20261101/sdd-game.exe` plus adjacent
PCK and owned local windowed DISPLAY1 profile. Earlier stage19-release is superseded.

New shell gives Region/Town/Stash/Trading/Training navigation, fixed resource/
location header and feedback footer, responsive cards, party rail and bounded
inventory scrolling. Campaign save v4 migrates valid v1..v3 in memory without
rewriting on load; advancement levels allocate shared earned XP, never heal or
change max HP. Managed dungeon/road snapshots freeze both gear and training;
sandbox stays isolated. Train at Ravenford, after resolving active events/runs.

At stage19 handoff the registry held24 NOT_RUN cases; it now has30 for stages8..22. No GUI/input while user uses PC. When released, use windowed
larger left DISPLAY1, safe saves, ordinary battles/trades/training/return/restart
and closed-log audit. Stage18/19 remain AWAITING_INTERACTIVE. Offline preview PNGs
are labelled reconstructions of geometry/art, not native screenshots or acceptance.
Fix/retest/re-export defects before recording live PASS. Further location/quest
content needs new scope; do not restart completed implementation.

## Prior technical baseline: stage17

User's "DAWAJ DALEJ" authorized the next background increment after stage16:
Ravenford Trading Post, world006/slice006. Buying equipment and selling only free
Valuable/Equipment copies now work through CampaignSession's atomic transactions.
No sale of quest/legacy/assigned items; purchases never auto-equip. Save remains
v3. [Stage17 report](qa/stages/2026-11-01-stage-17.md) records acceptance and build.
Source `artifacts/qa-runs/stage17-headless-20261101/report.json` passes43/43,
39 Python tests/48 trade assertions,0 diagnostics. Strict checker2003 files and
fresh extended release EXE probe PASS. Historical stage17 build:
`artifacts/export-smoke/stage17-release-20261101/sdd-game.exe` with adjacent PCK
and owned local windowed DISPLAY1 profile. Use the newer stage19 build above for current acceptance.

At stage17 handoff the live registry held20 NOT_RUN cases across stages8..17;
it now has30 and uses the stage22 corrected build above. Wait for mouse/keyboard/focus release; no GUI while
they use the PC. Play on larger left DISPLAY1, windowed; protect player save,
test ordinary combat/return/trade/equip/restart and audit the closed log. No stage
is finally accepted by headless checks. Fix/retest/re-export observed defects.
This section is historical; progression and interfaces above are implemented.

## Prior technical baseline: stages13..16

The authorized package is implemented in order with per-stage automated PASS:
13 travel39/39,14 persisted events/road combat40/40,15 stash41/41,16 equipment42/42.
Specs world002..005/slices002..005, combat slice102 and
[campaign expansion milestone](specs/world/milestones/001_campaign_expansion.md)
own the changes. Final checker1997 files and extended release EXE probe pass,
zero diagnostics. [Stage16 report](qa/stages/2026-11-01-stage-16.md) records all
acceptance, hashes, commands and limits. Source run:
`artifacts/qa-runs/stage16-headless-20261101/report.json`; final build:
`artifacts/export-smoke/stage16-release-20261101/sdd-game.exe` plus adjacent PCK.

At stage16 handoff actual computer-control acceptance covered stages8..16:
18 cases, all NOT_RUN; the registry now includes stage17 and20 cases. Do not activate
windows/inject input while user uses PC; wait until they release controls. Test
windowed on larger left DISPLAY1, preserve player save, normal victories/returns,
restart and closed-log audit. Technical PASS is not final acceptance; every new
stage remains AWAITING_INTERACTIVE. Do not restart completed implementation.
Fix any live defect, rerun affected automated
checks and export before retesting.

Campaign save is now v3 at the same user://campaign_v1.json path. Valid v1/v2
migrate without load-time rewrite; new starters are added only if missing.
F7 opens campaign from direct sandbox. Travel to Old Mine before managed packing,
keep return food; pending road events block travel/services/gear. Open Stash
contains the equipment UI; gear locks/snapshots during expeditions and ambushes.
Combat resumes at encounter entry/seed, never mid-turn. Existing source direct
dungeon remains free sandbox. Stages8..12 below are historical technical evidence.

## Prior technical baseline: stages8..12

Stages8..12 implementation/technical review is complete. Final source run
`artifacts/qa-runs/stage12-final-headless-20261101/report.json` passes38/38,
strict scene checker1973 files and final release/probe PASS, zero errors/warnings.
Build: `artifacts/export-smoke/stage12-release-20261101/`. The exported EXE also
loads Clearing crossfire through its data catalogue and performs ordinary
confirmed movement with correct MP/input unlock. Read the
[stage12 readiness/build report](qa/stages/2026-11-01-stage-12.md).

The user explicitly changed the order on2026-11-01: continue stages9..12 with
automated tests, collect actual gameplay scenarios and perform them in one later
session. Do not activate Godot/game windows or inject desktop input until the
user releases controls. All stages8..12 remain AWAITING_INTERACTIVE. Next action
was their accumulated live session before the later13..16 authorization above.
[Live-test registry](qa/live-test-scenarios.md) now lists30 NOT_RUN scenarios and
the newer stage22 build/setup; the original stage12 subset had11. No deferred
scenario counts as PASS.

## Accepted baseline

Stages0..7 of the Fallout FPP comparison/adaptation task are complete. Read the
[stage index](qa/README.md) and [final acceptance](qa/stages/2026-11-01-stage-7.md)
for every acceptance scenario, observed gameplay, defects and build identity.

Delivered: repeatable QA and DISPLAY1 placement; combat injury return; imported
asset catalogue; reusable passive HUD; TMX/map-v2 and playable workbench;
generation quality gates; durable campaign, Ravenford market/inn, checkpoint and
single-application expedition settlement. These are foundations, not a claim
that every historical combat roadmap item or the whole game is complete.

Final source run: `artifacts/qa-runs/stage7-fixed-20261101/report.json`,34/34 PASS,
zero errors/warnings. Export: `artifacts/export-smoke/stage7-release-fixed-20261101/`,
with EXE/PCK, reports, `interactive-acceptance.json`, closed runtime log and
archived campaign. Normal three-enemy victory,6/6 expedition and restart passed.
The campaign created during QA ended at75g/16XP/nine items, Bran7/14,Torin10/10.
This is historical evidence; inspect current state before further play.

Raw artifacts, `.venv` and local `override.cfg` are ignored by Git. Written stage
reports/specs are source files. A different checkout must regenerate artifacts.
Changes are local and uncommitted on `feature/dungeon-eod-checkpoint-2026-07-17`,
based on `f4f4546d7305ce98bde58a5dba91ef703be71ce7`. Verify current Git status;
do not reset, clean, commit or push this work without the appropriate user request.

Earlier documentation-only handoff verification (before stage8): `.venv/Scripts/python.exe tools/validators/validate_all.py`
PASS, `git diff --check` PASS,19 local Markdown link targets and both workspace/repo
entry points checked. No gameplay changed or new runtime acceptance claimed in
this documentation update.

## Current queue and acceptance

The existing [Ordered Combat Queue](specs/combat/milestones/001_combat_core_debug_loop.md#ordered-combat-queue),
items15..19, maps to the historical stages8..12 below. All are implemented and
technically reviewed with automated PASS; actual-play acceptance stays pending.
Authorized world/presentation stages13..22 are also implemented; the next task is live testing.

| Next stage | Existing queue item | Scope and acceptance focus |
| --- | --- | --- |
| 8 | 15: Combat Board Frame And Panel Skin V1 | Consistent battle frame/panels/feed/tooltips; readable layout and asset fallback. Review actual movement/target overlays and panel bounds. |
| 9 | 16: Combat Unit And Resource Icon Pass V1 | Audit already implemented sprites/icons/meters, complete remaining readability/state/fallback gaps. Test active, hovered, wounded, dead and status-bearing units. |
| 10 | 17: Combat Feedback Polish V2 | Consistent action/target/chance/damage/cost/rejection/result feedback, driven by resolver events. Play normal victory and defeat/return cases. |
| 11 | 18: Combat Encounter Authoring V1 | Add a new encounter from map/archetypes without controller edits; validate starts/assets/loadouts and test editor -> save/reload -> actual combat. Stage4 tooling is already available. |
| 12 | 19: Combat Readiness Review For Dungeon | Reconcile all roadmap requirements with existing proofs, explicitly list any deferrals, then full regression, fresh export and actual dungeon/combat/return acceptance. Stage7 is a baseline, not automatic proof of future changes. |

Stage8 owns presentation089/slice097, stage9 presentation090/slice098, stage10
presentation091/slice099, stage11 overview092/slice100 and stage12 overview093/
slice101. Accepted actual-play evidence still ends at stage7/slice096. New future
slices must use the next unused number (currently104); check before allocating.
Do not duplicate working stage3 HUD helpers
or mark partially implemented historical items complete without a requirements
audit and the missing proofs. Pixel-art creation must follow `agents/README.md`
and the Aseprite pipeline; reuse processed assets where suitable.

World travel/events/stash/equipment/trade/progression are now in world002..007,
shared presentation002 owns campaign UI. Further candidates after live acceptance
are additional town services/more
locations and encounters; these need user scope, owning specs and slices first.
[world001](specs/world/001_campaign_boundary.md) retains the accepted historical
hub/town/campaign boundary and links these extensions.

## Required stage loop

1. Read AGENTS.md, this handoff, the active milestone and owning specs. Inspect
   Git status and affected source/data. Do not replay completed stages by default.
2. Write/update the owning spec, schema/reference data as needed, chronological
   slice and meaningful automated acceptance checks before implementation.
3. Implement one complete playable increment. Combat legality/outcomes stay in
   `scripts/domain/combat_resolver.gd` and its Python mirror; UI sends commands.
4. Run targeted checks, then the required project verifier. Inspect exit codes
   and diagnostics. For a release gate, make a fresh export after the last fix.
5. Actually operate the visible game window on larger left DISPLAY1. Cover the
   stage scenarios, affected screens and return flow. Normal combat victory is
   required when that is the acceptance scenario; Debug Win/state injection do
   not count. Use isolated test saves; preserve current player progress.
6. Audit the closed session log, fix defects, and repeat relevant automated and
   actual tests on the final code/build. If UI access is unavailable, document
   the missing proof and leave acceptance open. Current batch exception permits
   the next implementation stage after automated PASS, with live tests deferred.
7. Persist the acceptance matrix, exact commands/build, results and remaining
   limits under `docs/qa/stages/`; update the index, milestone and this handoff.
   Record automated progress separately from final acceptance. After stages9..22
   automation, wait for the accumulated live session. No automatic commit/push.

## Commands and entry points

Run from `C:\Users\karol\Desktop\Gierka\game_dir\sdd-game` using Godot4.7 stable
and the existing Python3.12 `.venv`. Do not change engine version as a side effect.

```powershell
.\.venv\Scripts\python.exe tools\qa\verify_project.py
.\tools\qa\start_game.ps1 -ConfigureOnly
.\.venv\Scripts\python.exe tools\qa\export_smoke.py --release
```

The verifier includes data validation, discovered Godot test suites and five scene
smokes. The default source entry is DungeonDebug sandbox. F7 opens campaign;
managed runs use owned supplies and durable settlement. F6 opens the workbench
from sandbox; F5 plays its isolated draft, F6 returns. Combat saves resume from
encounter entry/seed, not the middle of a tactical turn.

On this workstation mixed DPI/elevated shell input caused problems. The verified
workflow is ConfigureOnly, then Run from ordinary Godot Project Manager, or the
exported EXE with the owned local profile beside it. Confirm the actual window
and input before acceptance. See [launcher contract](specs/tooling/001_stage_verification.md)
and README commands. The old pre-fix `stage7-release-20261101` is superseded by
`stage7-release-fixed-20261101`.

Fallout source reference: `C:\Users\karol\Documents\vibe-modding\fallout2-fpp-vibe-mod`.
It had unrelated user changes and was left untouched. Adapted ideas were tooling,
catalogues, checkpoints and candidate quality gates; no renderer/assets import.
