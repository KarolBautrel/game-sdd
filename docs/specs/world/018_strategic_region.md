# Native strategic-region campaign

Stage95,2026-11-09. Extends world017; proof [slice019](slices/019_strategic_region.md),
UI [presentation045](../presentation/045_strategic_region.md). Existing pilots,
art and files remain unchanged. No model/provider or tactical world-clash joining.

## Isolation and terrain

Explicit strategy-campaignv3 adds immutable region, company travel, jobs/cause
watermarks, scouting, permanent mine state, checkpoint context and company notes
to v2. V1/v2 keep explicit load/create with no conversion. Legacy companyv4 is
still validated; its atlas location is a compatibility anchor, never a dynamic
town ID. Actual location belongs to v3 and is derived from stopped travel.

Generate a fresh Large v2 geography using accepted generation/render/navigation.
Keep its original six anchors/base checksum, place three extra towns on reachable
mainland with separation. Store six towns, mine/pass/abbey and seven detailed
core-edge paths with terrain costs/weights/checksum. Bind new core coordinates /
ticks once before play. Water/peaks stay blocked; crossings and forest/hill/slope
costs use the existing navigator, including no diagonal corner cutting.
Persist positions/costs at seven decimal places for exact JSON roundtrips;
validate measured cost within1e-6. Core edge ticks=ceil(terrain cost/.007), the
Large caravan scale. Render army /
cargo progress by cost on the actual path, also backwards, never river-crossing
chords. Company uses the same terrain and approved .045/2 base budget, fatigue,
camping and65%starvation modifier. Never recover/teleport a blocked position on load.

## Time, money and company services

A v3 transaction owns company+classic world. A host-only optional clock hook
interleaves company arrivals/upkeep and job refresh per classic tick; JSON cannot
provide a callback. Standalone v2 behavior is unchanged. Validate and atomically
save the whole profile before publication; failure rolls back all clock/path /
AI/resources/jobs/loot/receipts. No wall-clock catchup.
Outside expeditions:1food/32ticks,3gold/day, existing fatigue/camping. Inside:
one tick/new visited room plus16/new camp, packed food keeps dungeon rules.
Pause normal time during packing/menus/jobs/runs; only checkpoints advance inside.

Buying1carried food consumes4strategic food; price1g or2g below target reserve.
A delivery consumes3owned carried food and supplies12strategic units. Coin/gold
transfer1:1; record explicit sources/sinks/events at this boundary. Other supplies,
gear/sales/training/inn reuse company legality through a memory-only calculator,
never a second writer. Actual stopped town, stock, issuer treasury and no-run
gates are v3 rules. Preserve owned copies, effects, gear and advancement.

## Causal jobs and obligations

Families: delivery, recon and Old Mine restoration. Cause is a committed food
deficit, missing/stale intelligence, actual public convoy-loss/war event, or the
initial occupied-mine fact. Freeze cause ID/tick/context, issuer faction/town,
target, quantities/conversion, gold/XP and a real core coin hold when posting.
No more than one live need per faction/family. Monotonic job IDs, weekly cause
keys and cooldowns prevent reusing an already paid cause.
Accept/report only at the actual stopped issuer without a run. Accepted terms /
holds survive politics and never expire. Unaccepted offers expire after3days or
close when the cause resolves; release their gold. Objective grants readiness,
not payment. Report consumes the actual held reward, transfers actual goods,
adds fixed XP/reputation and marks paid once. Prior recon, wrong issuer, missing
objective, short stock, unknown/paid IDs reject atomically. Recon requires an
actual arrival after acceptance, not a global intelligence flag or UI success.
Keep live jobs/holds/causes, bounded closed records, permanent mine status,
cooldowns and successful request/job watermarks through history pruning.

## Managed expeditions

Keep DungeonDebug/CombatDebug/resolver. Explicit strategic owner applies only
while v3 is active; legacy CampaignSession remains independent. Packing uses
owned supplies/effects/equipment. Checkpoint saves normal run/seed plus room/camp
counts; resume repeats pending combat from entry. Existing company settlement
validates the saved completed state, receipt and exact domain payload in memory.
Only genuine completed mine outcome permanently restores the mine and its saved
ore rate. Retreat/failure/sandbox cannot. Accepted restoration job becomes ready;
return/report still pays. Keep loot/refunds/effects and reject duplicate settle.
The mine's effective owner changes from bandits to River League through its
saved status overlay; immutable base-geography ownership is not rewritten.
F7/return leads to the strategic map; restored mine never respawns. Leaving this
pilot never writes an old player profile.

## Acceptance

Headless native controls/domain tests prove terrain samples, causal/funded jobs,
owned packing, ordinary resolver combat/loot/return, rollback/retry/reload and
private-information filtering. No secret faction plans/policies/treasuries in UI.
Physical appearance/gestures/ordinary victory stay AWAITING_INTERACTIVE while
desktop is withheld. Model adapter96 follows the real company loop.
