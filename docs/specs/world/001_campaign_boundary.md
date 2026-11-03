# Campaign boundary v1

Status: implemented and accepted. Date: 2026-11-01.

This describes the accepted stage6 baseline. Current extensions are world002
(travel),003 (events/ambush),004 (stash),005 (equipment),006 (town trade),007
(advancement/save v4); shared presentation002 owns the campaign interfaces. Their automated
proof passes; actual play remains deferred. App opens location-gated Ravenford
or dungeon preparation through those extensions.
The existing direct DungeonDebug entry remains a free sandbox. F7 opens the hub
from preparation or a finished sandbox, or checkpoints a managed expedition.

Stage13 extends this accepted v1 boundary through world002: v2 migration,
position/travel/clock and location-gated town/dungeon entry. Original stage6
acceptance remains historical; new actual-play scenarios are deferred.

CampaignSession owns a version1 save at user://campaign_v1.json. It is loaded
lazily by App; smoke tests never access the player's save. Tests use separate
paths or memory. Missing save creates a new profile; malformed/unsupported saves
block transactions and are never silently overwritten. Writes use a sibling
temporary file and rename; failed writes leave in-memory state unchanged.

Stage6 initial campaign:40 gold,0 XP, empty loot, oil4, pickaxe2, trap tools2,
bandage3, camping kit1, food3. Purchase prices respectively2,4,3,2,5,1 gold.
Inn recovery costs5 gold and clears persistent injuries/debuffs; unavailable
while an expedition is active. World005 adds owned starter sword/bow; world003
implements broken-cart choices. Blacksmith remains future work.

Managed preparation receives only the selected carried loadout and durable
party effects. Start validates the existing packing limits and owned quantities,
deducts exactly those supplies once and creates a unique run receipt id. It
rejects insufficient stock, malformed loadouts or a second active run. Sandbox
loot is never imported into campaign inventory. No automatic healing on start.

Exploration actions checkpoint dungeon data/state through DungeonRunSession.
An active snapshot survives process restart. Tactical combat itself is not saved
mid-turn: resuming a pending encounter launches it again from its saved entry
and seed. Authoring play remains isolated. Reset is disabled for managed runs;
the hub offers Resume, and normal dungeon retreat follows existing exit rules.

Completed/retreated/failed results settle through the active receipt. Apply only
the domain inventory_delta (failed delta must be zero), retain persistent party
effects and refund remaining carried supplies once. A mismatched, missing or
already processed receipt cannot duplicate gold, XP, items or supply refunds.
Settlement and active-run removal are a single saved transaction. Pending return
remains available if a write fails. Invalid payloads never partially mutate state.

Proof: world slice001, campaign session tests, world/town UI tests, full runner
and actual purchase/start/checkpoint/restart/retreat/return on DISPLAY1.
