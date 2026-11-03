# Accumulated live test scenarios

Policy extended2026-11-02 by explicit user instruction: stages9..36 may be
implemented with automated tests while the user uses the computer. Implementation
is ready; actual gameplay for stages8..36 will run together later. All61 scenarios
below remain NOT_RUN. No actual-play PASS is inferred from headless tests or a
prior build. Use the latest completed batch build recorded below.

Do not launch/activate visible windows or inject desktop input until the user
releases controls. Use larger left DISPLAY1, windowed. Preserve existing saves;
record the exact final EXE/PCK identity, scene/seed, actions, expected vs observed
result and closed runtime log. Fix defects, rerun affected automation and rebuild
before repeating live acceptance. Stage reports retain AWAITING_INTERACTIVE.

## Final build for the session

Latest2026-11-03: the user rejects stage45's motion/leg/hand quality and requests
the complete current state archived to `3d-models`, then drawn2.5D research.
M018-02 is USER_REJECTED (not a PASS); M018-01 remains NOT_RUN. Stop the 3D rollout.
The original61 native game cases and production game build remain unchanged.

Stages44–45 source-art follow-up2026-11-03: approved stage43 appearance receives
an isolated rig/idle/walk/sword pilot. No runtime replacement or game build change;
the original61 physical cases remain NOT_RUN. Source review is tracked separately:

| Case | Action / expected result | Status |
| --- | --- | --- |
| M018-01 | Open warden_motion_pilot/2026-11-03/preview.html; three simultaneous24fps loops, four angles, pause/step/timelines/half speed/2x work without missing frames or layout obstruction. | NOT_RUN — isolated browser host unavailable; native desktop controls unreleased |
| M018-02 | Watch at least three full cycles at1x in all four directions; approve foot contact, cloth, grip, attack timing and retained appearance before full sets/cast. | USER_REJECTED2026-11-03 — crooked legs/gait, wrist-driven sword action, poor hands; no rollout |

Read [motion guide](../design/character-art/WARDEN_MOTION_PILOT.md) and
presentation018. These are source-review gaps, not passed gameplay cases.

Stage43: stage42's outfit was rejected. Current source direction is restored
stage41 with only a modest existing-foot reduction. No game build or physical
case changed;61 remain NOT_RUN. See [stage43](stages/2026-11-02-stage-43.md).

Stage42 follow-up: anatomical stance/boots and actual modelled outfit are isolated
source-art corrections of the reviewed MPFB pilot. No runtime route or build
changes; none of the61 physical cases is closed. Rig/motion and actual gameplay
remain separate. See [stage42](stages/2026-11-02-stage-42.md).

Stage41 follow-up: MPFB warden is a static source-art pilot for user review before
animation/enemy expansion. It adds no game route, changes no packaged build and
closes none of the61 cases. Offline tactical compositions and FBX checks do not
replace live acceptance. See [stage41](stages/2026-11-02-stage-41.md).

Stage40 follow-up: softer static source variants are in `surface_refinement/`.
Matched source/FBX/Aseprite checks do not establish motion or physical play; no
runtime route or game-test build changed. All61 cases remain NOT_RUN and desktop
controls are still unreleased. See [stage40](stages/2026-11-02-stage-40.md).

Follow-up stage39: Knight-painted static candidates and new authoring tools are
isolated source-art proposals, pending user review. They add no rigged/runtime
acceptance claim and close none of the61 cases. No visible launch or desktop
input occurred. See [stage39](stages/2026-11-02-stage-39.md) and presentation012.

Stage38 character-style studies are static source-art experiments only, pending
the user's A/B/C choice. They are not integrated or animated, add no runtime
acceptance claim, and do not supersede the stage37 EXE below. Research/renders/FBX
reimports do not close any of these61 physical cases. See stage38's report and
presentation011 before any separate pilot/integration task.

Latest override: stage37 selective model rollback. User rejected the modular
characters/weapon refinements; restore our stage33 animated roster, retaining
new world art/portraits/icons. Stage37 export/package proof PASS: use
`artifacts/export-smoke/stage37-model-rollback-release-20261102/sdd-game.exe`
with adjacent PCK/windowed profile/notices. PCK SHA-256
`68003d8509e53dd6cc830d95f4f25f7f3c8b276f1d29f328b9230de4762cbfec`.
Final EXE318 checks/49 engine-local clicks/43 captures PASS; actual movement showed
7 distinct restored walk frames (8 in source). [Rollback report](stages/2026-11-02-stage-37.md).
The stage36 package below is historical and contains rejected character changes.
L34-01/L35-01 now check the restored behavior; no modular-appearance claim remains.

Current batch presentation010/stages34..36: models/grips, modular equipment,
independent pixel portraits and coherent environment. All three stages have
automated/native PASS; physical status remains AWAITING_INTERACTIVE. Use
`artifacts/export-smoke/stage36-final-release-20261102/sdd-game.exe` with its
adjacent PCK/windowed App profile/notices. PCK211336044 bytes, SHA-256
`8457ce277fb27b264b70d9bb6df83c5e4c16a94326ba87b2ebb4a87fd2585c3b`.
[Stage36 report](stages/2026-11-02-stage-36.md):56/56 source checks,50 Python
tests and final EXE3181 native checks/168 engine-local clicks/147 captures PASS,
zero diagnostics. All61 physical cases remain NOT_RUN. No desktop release.
The following stage30 notes are historical, superseded by this final package.

Priority update2026-11-02: user requested visual production tooling before this
session. See [character tools proof](2026-11-02-character-art-tooling.md). Toolchain
smokes did not change the earlier46 cases. The subsequent stage30 raider pilot
adds L30-01..03, all NOT_RUN, for a total of49.

Technical stages13..30 implemented; all49 live cases still NOT_RUN. Use
`artifacts/export-smoke/stage30-raider-release-20261102/sdd-game.exe` with its adjacent
PCK and owned windowed App profile. Build identity and source/native/export evidence:
[stage30 report](stages/2026-11-02-stage-30.md).
Native minimized GPU fixtures exercise real Controls without acquiring desktop
focus, and do not constitute a physical live session. No desktop input was injected.

## Session setup

- Confirm user has released mouse/keyboard/focus and current DISPLAY1 mapping.
- Use the final batch build recorded above, with its
  PCK and owned local windowed monitor profile. Source launch is also available
  in README. Do not use an older stage8/7 build to accept later changes.
- Record starting campaign and protect current player data. Use an isolated
  acceptance profile or normal sandbox, then managed integration on a safe copy.
- Record viewport/window size and cleanly close the session to audit its log.

## Scenario registry

| ID | Stage | Setup and steps | Expected result | State |
| --- | --- | --- | --- | --- |
| L8-01 | 8 | Open battle, inspect header/bar/turn order/feed; hover tiles/actions and scenario menu. | Consistent readable frames, correct tooltip/menu skin, unobscured board. | NOT_RUN |
| L8-02 | 8 | Resize2560x1440/1920x1080 equivalent window; reload encounter; select and move/target at board edges. | Panels remain in bounds; last row/column visible; scaled tile hit coordinates correct. | NOT_RUN |
| L9-01 | 9 | Select/hover multiple living units and inspect active unit/resources. | Identity, team/role and actual HP/AP/MP are readable and correct. | NOT_RUN |
| L9-02 | 9 | Wound a unit, apply status, kill an opponent; change active unit/turn. | Distinct hover/active/wounded/status/dead presentation; values refresh at the intended action timing. | NOT_RUN |
| L10-01 | 10 | Select movement/melee/ranged/special actions; inspect legal and rejected targets; perform hit/miss/status and end turn. | Cost, chance, damage, rejection and floating feedback agree with resolver; no stuck input or stale preview. | NOT_RUN |
| L10-02 | 10 | Win and lose normally in isolated dungeon encounters; use normal return controls. | Clear result presentation and correct dungeon return, HP/outcome preserved. | NOT_RUN |
| L11-01 | 11 | Choose **Clearing crossfire** in scenario picker, Load, move and fight normally. |12x10 referenced clearing, Bran/Torin and melee/archer roles/background work without controller edits. | NOT_RUN |
| L11-02 | 11 | F6 workbench: load `res://resources/data/combat_encounters/clearing_crossfire.json`, edit a `user://` copy, save/reload, F5 play, F6 return. | Changes survive reload/play/return; canonical source and player session remain safe. | NOT_RUN |
| L12-01 | 12 | Hub -> Ravenford purchase/recovery -> travel Old Mine -> owned-stock preparation -> event/hazard -> ordinary combat victory -> rewards -> Finish -> region -> travel Ravenford. | Coherent readable full loop, correct location/injuries/supplies, exactly one loot settlement. | NOT_RUN |
| L12-02 | 12 | Restart during a safe exploration checkpoint, Resume; later finish/settle and restart again. | Same checkpoint/encounter entry semantics, no duplicate supplies/rewards, durable final totals. | NOT_RUN |
| L12-03 | 12 | Close final EXE; audit full session log and record all scenario observations. | No engine errors/warnings; every required live scenario has evidence before acceptance. | NOT_RUN |
| L13-01 | 13 | Travel Ravenford -> Old Mine -> Ravenford; inspect map, clock, food costs and entry controls. | Position/time/food correct once; market/inn/preparation gated by location. | NOT_RUN |
| L13-02 | 13 | Try insufficient food/packing return reserve; restart after travel and Resume an existing campaign. | No stranding, duplicate charge or progress loss; migration/location durable. | NOT_RUN |
| L14-01 | 14 | Visit Broken Cart, choose an outcome; travel a dangerous route and resolve ambush normally. | Choices/costs/rewards apply once; tactical combat returns to region with correct injuries. | NOT_RUN |
| L14-02 | 14 | Restart with pending event/ambush and resume; attempt repeated settlement. | Same event/seed, no repeated travel cost/reward; no stuck return flow. | NOT_RUN |
| L15-01 | 15 | Open stash, inspect/filter stacked known and legacy items and supply counts. | Names/descriptions/quantities correct, unknown loot preserved, layout usable. | NOT_RUN |
| L16-01 | 16 | Equip/unequip/swap weapons, shield and armor between heroes; attempt invalid/over-owned combinations. | Ownership/slot rules and visible loadouts correct; invalid changes are atomic. | NOT_RUN |
| L16-02 | 16 | Start expedition/road ambush with chosen gear, fight normally, return and restart. | Actions/damage/armor match gear; snapshots persist; injuries and ownership never duplicate/reset. | NOT_RUN |
| L17-01 | 17 | Ravenford Trading Post: buy blade/armor, sell loot and one spare weapon, equip bought gear in stash, restart. | Exact prices/single copies, unchanged injuries, durable gold/items/assignments and usable selectors/feedback. | NOT_RUN |
| L17-02 | 17 | Try insufficient funds, quest/legacy/fully assigned items, remote/active/pending service entry; use Back. | Forbidden trades blocked without loss; correct disabled/empty states and return to town controls. | NOT_RUN |
| L18-01 | 18 | Open Training, inspect current/next stats and shared XP, advance each hero, try insufficient budget/cap and restart. | Exact one-tier allocation, earned XP preserved, no healing, durable levels and clear disabled reasons. | NOT_RUN |
| L18-02 | 18 | Start equipped expedition/road ambush with trained hero; fight normally, return and restart. | Frozen effective stats affect normal combat; wounds/gear/XP remain correct, sandbox separate. | NOT_RUN |
| L19-01 | 19 | Navigate Region/Town/Stash/Trade/Training, keyboard focus and resize window; scroll long inventory independently from equipment. | Readable art/type/states, no horizontal clipping, visible feedback/navigation and correct pointer targets. | NOT_RUN |
| L19-02 | 19 | Use new UI for purchase/train/equip/travel/event/ordinary victory/return/settlement/restart, then close/audit log. | Coherent complete loop with no lost state, stale controls, duplicate rewards or engine diagnostics. | NOT_RUN |
| L20-01 | 20 | Select/filter item tiles, switch hero portraits, inspect occupied/empty slots and compare gear. | Readable selected/compatible/assigned states; exact metadata and no passive save mutation. | NOT_RUN |
| L20-02 | 20 | Equip/unequip on each hero; try bow/shield conflict, legacy/quest items and locked expedition; resize. | Retained hero/item/filter, explicit reasons, correct ownership/injuries and usable bounds/focus. | NOT_RUN |
| L21-01 | 21 | Buy/sell through visual grids, inspect copy counts, spend down gold and reopen the service. | Correct prices/protection/selection and readable feedback. | NOT_RUN |
| L21-02 | 21 | Inspect training tier/deltas/XP bar, advance, test cap/lock and quickly navigate during hover feedback. | Correct budget/stats and no stale UI or animation errors; clear native motion/focus. | NOT_RUN |
| L22-01 | 22 | Use city supply tiles/inn/services and clickable map landmarks with sufficient/insufficient food/pending event. | Correct single transaction/gates and clear visual route/current-location feedback. | NOT_RUN |
| L22-02 | 22 | Full polished UI loop: trade/train/equip/travel/ordinary battle/return/settlement/restart/log audit. | Coherent visible screens/input, persistent progress and clean closed log. | NOT_RUN |
| L24-V01 | 24 | Compare real inventory with selected concept A and the user's dark fantasy reference. | User visual approval of composition, restrained brass/leather and parchment hierarchy. | NOT_RUN |
| L24-V02 | 24 | Inspect every owned/catalogue item, quest/legacy fallback and stacked/assigned copies. | Recognizable distinct correct art, transparent edges and truthful quantities. | NOT_RUN |
| L24-V03 | 24 | Inspect actual1080p text, numbers, long descriptions and Polish font samples/tooltips. | Legible glyphs, full information accessible without clipped actions. | NOT_RUN |
| L25-V04 | 25 | Windowed larger left DISPLAY1:1920x1080,1440p and4K scaling; resize/scroll all five screens. | Proper proportions, aligned map landmarks, no horizontal overflow; all actions reachable. | NOT_RUN |
| L25-V05 | 25 | Hover, select and disable controls; navigate with physical keyboard and activate actions. | Distinct native states, visible focus, correct hit targets and no stale animations. | NOT_RUN |
| L25-V06 | 25 | Filter, switch heroes/slots, compare/equip/unequip, buy/sell/train; use map/event and return. | Retained selection, correct campaign guards, gold/items/XP/food and wounds. | NOT_RUN |
| L26-V07 | 26 | After control release, confirm screen mapping/input and optionally compare Godot MCP input to normal pointer; verify cleanup. | No unexpected focus transfer, save interference or residual test autoload/window settings. | NOT_RUN |
| L26-V08 | 26 | Final EXE: normal equipped battle/victory/return/settlement, reopen services, restart and close/audit logs. | Same art and behavior as source, persistent progress, no duplicate rewards or diagnostics. | NOT_RUN |
| L27-01 | 27 | Prepare authored and generated expeditions, adjust packing, test capacity/owned limits, difficulty/source/reroll and keyboard focus at target window sizes. | Readable complete preparation, correct limits and no inaccessible controls. | NOT_RUN |
| L27-02 | 27 | Explore named room map; scroll both axes, use supplies, trigger room/corridor events and each allowed choice. | Paper inspector/blocked backdrop work; correct light, counts, paths, rewards and persistent feedback. | NOT_RUN |
| L27-03 | 27 | Managed expedition: enter ordinary battle, win, return, claim loot, finish/retreat and restart/resume. | Gear/wounds/checkpoints/rewards preserved; readable normal flow without debug victory. | NOT_RUN |
| L28-01 | 28 | Inspect all battle HUD/action/cost/portrait/turn/history states; physical hover, keyboard shortcuts/focus and resize1080p/1440p/4K/narrow. | Shared art, readable text and reachable scrolling; board hit areas clear. | NOT_RUN |
| L28-02 | 28 | Move/confirm/cancel, target melee/ranged/special actions including invalid targets, statuses and enemy turns; reload through Tools. | Correct hit transforms, previews/resources/animation locks; all actors visible after reload. | NOT_RUN |
| L28-03 | 28 | Play ordinary victory and defeat/return scenarios; inspect actors on board edges and terminal instructions. | No sprite/HUD occlusion; correct outcome and return/checkpoint behavior. | NOT_RUN |
| L29-01 | 29 | Final EXE full campaign/town/equip/train/travel/dungeon/battle/settlement/restart session, followed by closed-log audit. | All three UI modes coherent and durable; no duplicated rewards or engine diagnostics. | NOT_RUN |
| L29-02 | 29 | Confirm larger left DISPLAY1/windowed mapping and physical mouse/keyboard; complete acceptance and hand desktop back. | Correct monitor/input, protected player saves and no leftover test windows/profiles. | NOT_RUN |

| L30-01 | 30 | Tools -> Ash-road raiders -> Load; move/turn and trigger enemy turns; watch idle/walk/attack/hit/death at normal speed and resize1080p/1440p/4K. | Clear identity/weapon/role, consistent ground pivot and grip, eight real facings, complete transitions, no canvas/body clipping or stuck input. | NOT_RUN |
| L30-02 | 30 | Play an ordinary roadmap roadside ambush with the original raider, without boosted stats/Debug Win; win/lose, return, settle and restart. | Normal AI/costs/injuries/rewards remain correct; new artwork survives the campaign route and final death hold. | NOT_RUN |
| L30-03 | 30 | In the final EXE inspect the actor at board edges, during interruption/death/reload and alongside the other original roster models; close and audit the full log. | No lost actors, stale pose, swapped equipment, visual regressions or runtime warnings/errors; record visual approval or concrete defects. | NOT_RUN |

| L31-01 | 31 | Compare retained legacy sheet and original gallery at ordinary battle zoom; inspect face, blue hero identities, bandit palettes, equipment and eight views. | Readable tactical exposure, consistent ground scale, recognizable old designs; record visual approval or defects. | NOT_RUN |
| L32-01 | 32 | Tools -> Character gallery: all human pages, facing/action selectors, pause/resume, scroll, keyboard focus and Close/Escape; resize1080p/1440p/4K/narrow. | All15 human variants reachable; no clipping, stale textures, layout or battle-shortcut leakage. | NOT_RUN |
| L32-02 | 32 | Watch normal-speed melee, bow draw/release, crossbow recoil, spear thrust, walk, hit and death in ordinary encounters; inspect hero portraits in campaign, equipment, dungeon and battle. | Correct grips, shield side, timing, ground anchors and matching identities; no stuck input or changed simulation. | NOT_RUN |
| L33-01 | 33 | Inspect all12 creature families in the gallery and actual encounters, including wings, eight spider legs, coils/tail/tusks, skeleton weapons and wraith dissolve. | Species readable at ordinary zoom; full silhouettes, natural normal-speed motion, complete death hold and no cut appendages. | NOT_RUN |
| L33-02 | 33 | Play crowded and board-edge encounters with mixed small/large species; use all directions, interruption, reset and reload. | Correct sorting, pivots, selection/hit areas and readable occlusion; original art for every old ID. | NOT_RUN |
| L33-03 | 33 | Final EXE ordinary campaign/expedition victory and defeat, return, settlement, restart and closed-log audit on larger left DISPLAY1/windowed. | Models/portraits survive the real flow and saves, no duplicated rewards, missing art or runtime diagnostics. | NOT_RUN |

Stage30 physical cases now target the latest roster replacement; the original
pilot builds remain historical comparison evidence. All55 cases remain NOT_RUN.

## Equipment/portrait/environment batch (presentation010)

These are additional deferred physical scenarios; background/native evidence
does not satisfy them. All55 previous cases also remain NOT_RUN.

| ID | Stage | Scenario | Acceptance | Result |
| --- | --- | --- | --- | --- |
| L34-01 | 34/37 | Compare all27 actors with our stage33 roster, before grip/helmet refinement; inspect eight directions and normal-speed idle/walk/attack/hit/death. | Earlier models/weapons restored, visible walking/attacking, new terrain retained; no modular atlas in playable views. | NOT_RUN |
| L34-02 | 34 | Inspect Bran/Torin portraits throughout campaign, inventory, dungeon and battle at1080p/1440p/4K. | Distinct illustrated pixel portraits, recognizable identity and readable crops. | NOT_RUN |
| L35-01 | 35/37 | Equip/unequip retained items, swap sword/bow, enter battle and restart; inspect the separate illustrated portrait. | Ownership/save safety preserved, prior weapon-selected sprite family shown; rejected3D preview absent. Modular armour/boots/helmet appearance is deferred. | NOT_RUN |
| L35-02 | 35 | Load a protected legacy three-slot save and pending expedition; try two-handed/shield conflict, unavailable copies and equipment lock. | Compatible migration, unchanged combat bonuses/wounds/checkpoints and clear rejection feedback. | NOT_RUN |
| L36-01 | 36 | Play authored/generated outdoor and dungeon maps, inspect floors, cover, elevation, walls and nature props at ordinary zoom/edges. | Coherent art palette/materials with actors/UI; calm floors, readable collision/cover/elevation and reliable targeting. | NOT_RUN |
| L36-02 | 36 | Final EXE ordinary campaign victory/defeat, immediate post-turn action selection, return/settlement/restart and closed-log audit on larger left DISPLAY1/windowed. | Cohesive complete loop, no lost post-turn clicks, missing models/art or duplicated progress, no engine diagnostics; return desktop controls. | NOT_RUN |

## Results and defects

## Drawn character animation batch (presentation022)

All61 earlier physical cases remain NOT_RUN. The separate source-preview result
below is explicit user feedback and does not close the new in-game cases.

User2026-11-03 subsequently praises the overall batch and requests corrections:
idle sliding, rear shield surface and bow draw/aim. This feedback does not record
a completed ordinary campaign or close the deferred physical scenarios.

| ID | Stage | Scenario | Acceptance | Result |
| --- | --- | --- | --- | --- |
| L52-V01 | 52 | User watches supplied12-clip3/4 knight player at normal speed. | User approves neutral/combat movement and whole-body actions. | PASS_USER_REPORTED2026-11-03: explicitly says animations are great and asks to continue. |
| L53-01 | 53 | Native drawn gallery: all six roles, seven primary clips plus five additional knight clips, eight directions, pause/step/restart and floors at1080p/1440p/4K. | Readable face/gloves/gear, natural movement, ground pivots, no clipping; explicitly review mirrored costume/weapon handedness. | NOT_RUN |
| L54-01 | 54 | Ordinary battle: neutral/near-enemy guard, movement, attack anticipation/impact/recovery, hit/death, interruption/reset/reload and normal victory/defeat. | Complete timings and final corpse hold, correct aim/grips/feet/sorting, no stuck input; resolver unchanged. | NOT_RUN |
| L54-02 | 54 | Campaign equip sword/bow and restart; ordinary expedition battle/return/settlement with the replaced subset and remaining old families. | Correct weapon-selected profiles, unchanged saves/ownership/costs/rewards and coherent portraits/world/UI; close and audit log. | NOT_RUN |

| L55-V01 | 55 | User reviews idle contact, rear shield interior and stronger/slower bow draw in focused before/after preview. | Corrections match requested appearance and motion. | PASS_USER_REPORTED2026-11-03: explicitly approves the corrections, "Tak ma byc". |

## Results and defects (continued)

No live session started. Add observed results per scenario here, link screenshots
or logs when available, and record any defect's owner/slice/fix/retest evidence.
Future stage specs may refine their scenarios before implementation; keep this
registry synchronized without erasing failed attempts or marking unplayed cases.
