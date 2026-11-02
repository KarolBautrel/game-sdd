# Accumulated live test scenarios

Policy extended2026-11-02 by explicit user instruction: stages9..29 may be
implemented with automated tests while the user uses the computer. Implementation
is ready; actual gameplay for stages8..29 will run together later. All46 scenarios
below remain NOT_RUN. No actual-play PASS is inferred from headless tests or a
prior build. Use the final stage29 build recorded below.

Do not launch/activate visible windows or inject desktop input until the user
releases controls. Use larger left DISPLAY1, windowed. Preserve existing saves;
record the exact final EXE/PCK identity, scene/seed, actions, expected vs observed
result and closed runtime log. Fix defects, rerun affected automation and rebuild
before repeating live acceptance. Stage reports retain AWAITING_INTERACTIVE.

## Final build for the session

Technical stages13..29 implemented; all46 live cases still NOT_RUN. Use
`artifacts/export-smoke/stage29-release-20261102/sdd-game.exe` with its adjacent
PCK and owned windowed App profile. Build identity and source/native/export evidence:
[stage29 report](stages/2026-11-02-stage-29.md).
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

## Results and defects

No live session started. Add observed results per scenario here, link screenshots
or logs when available, and record any defect's owner/slice/fix/retest evidence.
Future stage specs may refine their scenarios before implementation; keep this
registry synchronized without erasing failed attempts or marking unplayed cases.
