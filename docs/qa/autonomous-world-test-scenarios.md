# Autonomous world: player test runbook

Stages99..103. All physical cases below are **NOT RUN / AWAITING_INTERACTIVE**.
Automated results are recorded separately; they do not accept appearance or feel.
Start with cases01..05, then return to the independent-world cases on another seed.
Allow roughly25–40minutes for the first group, depending on the battle.

## Launch and save isolation

Run in PowerShell:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene autonomous-world
```

This is the new Vast **v5** campaign, separate from `living-world`, `strategy`
and `strategy-ai`. It starts paused in Ravenford with seed2087 / Marches on a
fresh slot. Reopening resumes that slot. **New / Resume does not overwrite an
existing seed.** For a fresh case, enter an unused seed such as2201, select
Marches/Vast and press **New / Resume**. Record that seed. Do not delete/reset
older company files. Large also has its own v5 slot when selected.

##01 — Opening, map and pause

1. Check that the old painted map, serif and dark framing are retained. Pan,
   zoom, use Overview, the minimap and Company. Labels/buttons should fit.
2. Open **World**. Check the three named district focus buttons, rival company
   names and outpost owners. These districts share one continuous map.
3. Focus a district and inspect **Briar Road Camp**. The camera should move;
   the company and game clock must stay put until a travel/wait order.
4. Wait20real seconds while paused, then open Jobs and Company. The clock must
   remain unchanged. Space toggles pause outside those blocking tabs;1/2/4 are
   travel rates. A managed dungeon freezes the world-map clock controls.

Fail if inspection moves the company, pause spends time, fonts overflow or
the campaign silently becomes a different seed/size. Record resolution/seed.

##02 — Accept a protected camp commission

1. On a fresh paused opening, open **World**, click **Wait one day / normal
   upkeep** once. This advances exactly one game day, with ordinary food/wages.
2. Find Briar Road Camp. The cause, River League patron, Ravenford issuer,
   **24g +8XP** terms and offered state should be readable. Reports have dates.
3. While still at Ravenford, press **Accept /5days exclusive**. A deadline must
   appear. Accept becomes disabled; Report stays disabled. Click again if the
   button is still enabled: it must not create another reward or claim.
4. Press **Inspect on map** for the camp. Then, in Location, press **Travel to
   selection**. Inspection itself must not have issued that journey.

The exclusivity clock is five days from acceptance. NPCs cannot clear the camp
during that claim; an expedition already started there protects it past expiry.

##03 — Terrain-safe travel and arrival

1. Run at2x or4x to the camp, watching the company banner. It must follow its
   drawn path smoothly around water/high peaks and use actual crossings.
2. Change zoom and camera focus during movement. There should be no banner
   teleport, duplicated party, jump across a river or route reset.
3. At arrival pause. Location must say Briar Road Camp, and **Prepare Briar
   Road Camp** must be enabled for the accepted commission.

Fail if arrival leaves a stuck path/disabled preparation, or the company passes
through blocked terrain. Record the seed and visible route/position.

##04 — Ordinary forest expedition, battle, loot and return

1. Prepare the camp. Its title, forest parchment/illustrations and room names
   must describe a woodland camp. Source/reroll/difficulty controls are hidden.
   Packing uses the company's owned supplies and reserves food for returning.
2. Start with the pinned Start button. Visit **Abandoned Watchfire**, then
   **Bandit Stockade**. The stockade must request an ordinary forest battle.
3. Fight normally. Do not use Debug Win. Check readable movement/attacks,
   Southeast/Southwest presentation, equipment and turn completion.
4. On victory return to the expedition. Claim the stockade reward once:7gold
   enters carried run loot. A second claim must not add more.
5. Continue to **Freed Road**, complete the expedition and use Return to the
   region/F7. The game must return to the same autonomous world/seed, retaining
   company injuries and loot. The camp is cleared; Old Mine is independent.
6. Inspect the same camp again. It must not immediately offer a fresh identical
   expedition or duplicate loot. A later occupation needs a new arriving party.

If defeated, verify that defeat/return and injuries are preserved; the camp
must remain occupied. A defeat is not a failure of the test by itself.

##05 — Earned reward, exact payment and reload

1. Return to Ravenford on the ordinary map. Pause and record gold/XP.
2. In World find the completed camp commission and press **Report /24g +8XP**.
   Gold increases by24 and XP by8 once. Loot was a separate expedition reward.
3. Report becomes disabled/paid. Reopening the tab must not pay again.
4. Close the game, note the displayed date, reopen with the launch command.
   The same v5 seed/date, cleared camp, paid status, company and equipment must
   return. Real time with the game closed must add no campaign time.
5. Open an older campaign using its own original launch command if desired.
   Its prior company/mine progress must still exist; do not reset it for this test.

##06 — Save/reopen during an expedition

Use another fresh seed, repeat02..04 and close after packing/entering the
watchfire or while the stockade battle is pending. Reopen autonomous-world for
that seed (enter it again in the top selector and press New / Resume), then
**Resume saved expedition**. Supplies must not be packed again;
layout, current room, pending encounter and owned equipment must match. Finish
or retreat normally. Repeat return must never grant another settlement/reward.

##07 — NPCs act without the company

1. Open a fresh unused seed. Stay at Ravenford and accept no commissions.
2. Use World's one-day wait repeatedly, inspecting World and Chronicle after
   each day. Expect warning, a paid NPC commitment, departure, arrival, assault
   and a result; timing depends on terrain, rivals' other tasks and means.
3. On the map, **R** marks an independent company; click it for World activity.
   Rival markers should follow safe paths, including turns and crossings.
4. Look for either success/cleared site or a failed expedition/retreat followed
   by recovery and a newly funded attempt. NPCs must not wait for a player visit.
5. Check the dated cause/source and resulting site/commission status, not only
   a moving icon. A rival's claim makes player acceptance unavailable.

A single quiet day is expected during preparation/travel. Several days without
change are worth reporting with seed/date and the current situation phase.

##08 — Expiry and protected active expedition

On a fresh seed, accept the camp at Ravenford but stay there. Wait five days
from the displayed acceptance deadline. The unfinished claim reopens with an
expiry notice; NPCs can subsequently accept it. No reward is earned. In a
separate run, start an owned expedition before the deadline: expedition time
must not let an NPC steal that target. Completed work remains payable even if
the original deadline has passed before reporting.

##09 — Corridor dispute, diplomacy and outposts

1. On a fresh Marches2087 opening, accept no work and advance one day at a time.
   Inspect World, Factions and Chronicle for the High Pass dispute.
2. Look for the cause, actual diplomatic offer, refusal/settlement, warning and
   funded border preparation. An accepted agreement or recovered supplies can
   settle a dispute peacefully. War is not a required result of every seed.
3. If war starts, inspect River Watch/Iron Redoubt. A funded NPC campaign must
   warn, travel and assault before changing control. A failed assault leaves
   the defender in place. No instant owner swap on reading news is allowed.
4. After occupation check the new owner and recovery period; observe eventual
   peace and reinforcement. Original town/capital ownership must stay stable.
5. Reopen the same save: control, history and diplomacy must persist.

The automated matrix includes wars and captures, plus a protected peaceful
fixture. A local physical case may legitimately follow another branch.

##10 — Ruins and distant knowledge

Inspect **Blackroot Ruins** near Ashmere and its Cinder Compact commission.
Acceptance/reporting requires Ashmere. Travel there with adequate provisions.
The NPC may arrive first; that is supported. To test an available ruins
expedition, remain near Ashmere and inspect later occupations as in11, then
accept a newly offered claim at its issuer. Preparation must use the stone /
dungeon archetype, Silent Cloister/Occupied Reliquary rooms and a different
stone tactical encounter from the forest camp. Same packing/loot/return rules.

Read district reports before/after travel. Reports show source and game date;
town messengers deliver the preceding day's summary. Being in a remote district
does not reset its history or create another company. Direct site observations
and dated settlement reports are separate saved facts.

##11 — New occupation requires arrival

After an NPC/player clearing, advance at least14game days. A finite displaced
band may begin travelling toward the cleared site. **!** marks it on the map.
The site must remain cleared until that band actually arrives. Arrival creates
a new dated situation/claim while retaining the earlier clearing in history.
It must not silently restore/reoccupy the old legacy Old Mine. The prototype
has a finite survivor reserve: later quiet periods are allowed, not hidden
infinite enemies scaled to the company.

##12 — Automated edge cases and evidence

No manual filesystem damage is required. These headless suites cover failed
save/retry, malformed state, duplicate commands/payment, finite means, ordinary
combat handoff and protected/expired claims:

```powershell
$godot = 'C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --script res://scripts/domain/world_life_contract_tests.gd
& $godot --headless --path . --script res://scripts/session/life_expedition_tests.gd
```

Full run and source receipt: [runtime QA](2026-11-10-world-life-runtime.md).
Record each physical result: **case / seed / resolution / date / PASS or FAIL /
company action / expected versus actual / optional screenshot**. For04 record
victory/defeat and any unreadable action, sliding, wrong weapon or stuck turn.
