# Stage84 ordinary desktop skirmishes and live fixes

User delegated about two hours on2026-11-04 23:15:54UTC. Sky Computer Use controls
the actual normal-permission Godot window on left DISPLAY1, ordinary selected
CombatDebug scenarios. No Debug Win, forced terminal state or campaign-save edits.
The debug scene's Next turn step runs the normal enemy policy one command at a
time; player decisions are made from the visible board. Engine-local native
victory fixtures are recorded separately and do not count as desktop play.

## Forest Ambush, seed2070 — VICTORY round2

Knight2,7->6,7 through low cover; Bran2,5->5,6; Torin1,7->5,5 and aimed shot
guard14->11. Rogue3,9->7,9 exposed flank. Enemy archer approaches8,4 and hits
Knight14->13; guard approaches8,8 and hits Rogue10->6; wolf approaches8,9 and
hits Rogue6->2. AI routes around the blocked rock belt.

Round2 Knight6,7->7,8 and two ordinary6damage attacks kill guard. Bran5,6->7,4
for2MP and Power strike archer9->2. Torin normal shots kill archer and reduce
wolf10->7. Rogue two4damage attacks finish wolf. All four allies survive:
Knight13/14, Bran14/14, Torin10/10, Rogue2/10. Flanking has a real health cost;
focus fire and ranged support matter. No stuck turn, invalid weapon, idle sliding
or obstacle penetration observed. Art and motion appearance remain user-reviewable.

Evidence: artifacts/qa-runs/live-control-2026-11-05/forest-victory.png;
forest-round1.png and ordinary process game-20261104T235520346.log.

## Mine Breach — VICTORY round2

New process game-20261105T002038037.log loads tooltip fix. Knight2,7->6,7 for4MP
and Defend; Bran2,5->5,6 for3MP (crate low cover), Shield wall2DR. Torin1,7->5,5
for4MP, aimed shot guard14->11. Stationary-pointer popup refreshes to11/14 at
animation commitment; actual capture mine-tooltip-fixed.png. Rogue3,9->5,7 for2MP,
Defend. Archer shoots Knight14->13, moves8,4; guard moves7,7 and hits13->11;
wolf moves6,6 and hits11->9. Each attack loses1damage through Defend.

Round2 Knight two6damage attacks kill guard11->5->0. Bran two Deep cuts kill
wolf10->5->0, bleeding feedback and open tooltip update correctly. Torin's shot
from5,5 to8,4 is correctly rejected for blocked LOS with AP2 preserved. He routes
above the pillars to7,3 for4MP, then two shots reduce archer9->6->3. One premature
repeat click on his own destination is rejected without resource loss after the
move had committed. Rogue takes lower crossing5,7->7,5 for3MP and kills archer
with4damage. All survive: Knight9/14, Bran14/14, Torin10/10, Rogue10/10.
Evidence mine-victory.png. No turn lock, obstacle penetration or idle drift.

The physical LOS rejection exposed a false new terrain explanation. Corrected
presentation030/042/slice042 and EnvironmentArt against existing combat/grid022;
blocked cells really do block ranged LOS.124focused checks PASS with0warnings,
native tactical-environment-los-final PASS at720p/1080p/12actions/0diagnostics.

## Painted Six - Old Mine, seed2001 — INTERRUPTED / NOT_COMPLETE

Ordinary process game-20261105T004854774.log,4allies/4enemy axe/spear actors.
Fresh source includes corrected blocked-cell explanation, visible on desktop.

Knight5,8->9,8 for4MP, two attacks reduce southern Axe Raider I14->8->2.
Bran5,5->9,5 for4MP, Shield wall, End. Torin3,7->7,7 for4MP. His shot at the
southern axe is intercepted by allied Knight on the shot line:14->13HP. A shot
at Spearman I11,6 is rejected for LOS, AP preserved. Torin Defend and End.
Last agent-controlled state: round1 Rogue turn,5,2,10/10HP,2AP,4MP, Move selected,
no destination committed. Other actors retain starting resources; no enemy turn
played in this third scenario. A subsequent attempted pointer action was blocked
because the user resumed desktop input; no further game input sent.

User explicitly stops work and requests publication. A read-only final screenshot
shows the user has switched to a different Old Mine scenario with Debug victory;
this is not evidence of completion of Painted Six. Restart seed2001 next session
unless the original process/state is still available. No runtime save is claimed
for this isolated, transient debug battle. Two complete ordinary victories stand.

## Live defect and fix

Forest default engine tooltip retained old HP after damage/death while the actor
badge was correct. presentation043/slice043 introduces a tile-owned custom Label
inside the existing native tooltip. Weak reference avoids popup retention. Every
tile render updates the open Label using the same presentation snapshot.

11headless checks PASS: actual legal attacks and corpse resources, safe reopening.
Native livetooltip entry: first fixture lacked notify_mouse_entered and failed;
fixed fixture uses the documented Viewport entry notification and embedded
subwindows. live-tooltip-native-entered PASS at720p/1080p,4GPU captures,0diagnostics.
Real native popup remains open across legal nonlethal/lethal commands and matches
the tile exactly. Bounded setup moves a target for this test, so it is explicitly
not a played-victory receipt. Physical Mine shot independently confirms the fix.

Primary engine references inspected:
https://github.com/godotengine/godot/blob/4.7/scene/gui/control.cpp
https://github.com/godotengine/godot/blob/4.7/scene/main/viewport.cpp
https://github.com/godotengine/godot/blob/4.7/doc/classes/Viewport.xml

## Motion evidence

Native tactical-motion-clip-final captures44real GPU frames during normal
preview/confirm four-cell march, using recorded milliseconds and original timing.
Buffer images before PNG encoding so disk/compression does not stall playback.
Earlier trials were too sparse and remain failed audit artifacts. Final native
PASS,0diagnostics; 4MP spent and final planted idle. This is a timed image sequence,
not a desktop video. Portable player/gallery follows after battle review.

## Observations retained for later UI iteration

Unaffordable actions disappear, shifting action slots and keyboard numbers. This
is existing behavior; avoid changing it mid-batch without matching owner/tests.
No claim of complete combat balance or endless-world readiness follows from
these small pilots. L77-01 campaign mine-contract victory remains open.
