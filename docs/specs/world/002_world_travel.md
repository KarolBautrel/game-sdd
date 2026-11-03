# World travel and campaign v2

Status: implemented; automated PASS; live tests deferred. Stage13,2026-11-01.

Stage16/world005 extends this v2 contract with equipment and migration to v3.
Travel/world rules below remain unchanged.

Campaign owns world position, elapsed hours and journey sequence in save version2
at the existing campaign_v1.json path. Valid v1 saves migrate in memory without
losing gold/XP/items/effects/active run/receipts; load alone never rewrites a file.
Legacy profiles begin at Ravenford, retaining their old hub/active-run semantics.
Malformed or unsupported saves remain blocked and unchanged. All new mutations
use the existing atomic temp/rename/publish transaction. New-game defaults are
schema-validated reference JSON, copied into each campaign instance.

World state: region_id, location_id, elapsed_hours, journey_count, seed,
pending_event (empty until stage14), resolved_nodes and last_journey. Initial
location Ravenford, elapsed0, sequence0, seed170717. Clock starts day1 at08:00.
Only region001 is supported in this slice. Region edges are bidirectional with
the same authored hours/food/danger. Travel only to an adjacent destination;
reject self/unknown/unreachable destinations, active expeditions or pending events.

Quote before committing: charge exactly authored hours/food once, advance location
and journey sequence, store last journey. No gold cost or real-time wait. A double
activation of the same destination cannot charge twice after arrival. Require
enough food for the trip and a cheapest-food return path to a town; charge only
the trip and reserve the rest. Managed packing at a remote dungeon must also
leave that return-food reserve in campaign stock. This prevents stranding.

Market/inn require town location. New managed dungeon preparation/start requires
Old Mine location. Sandbox is independent. Expedition settlement keeps current
world position; it does not teleport to Ravenford. Existing legacy active runs
migrated at Ravenford may finish there without invented historical travel costs.

Region UI shows a passive spatial route map/current position, clock, authored
route cost/danger/return reserve and ordinary Travel controls. Town/Prepare entry
controls remain present but unavailable away from their destination. UI sends
commands to Campaign/WorldTravel, never computes different costs or outcomes.

Proof: world slice002, world_travel_tests.gd, campaign/town/session regression,
schema/reference validation and full verifier. Actual travel, gating, layout,
restart and packing/reserve behavior remain live L13-01/02, NOT_RUN.
