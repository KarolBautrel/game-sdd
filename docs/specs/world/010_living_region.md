# Living mercenary region v1

Date:2026-11-04. User authorizes the living-world proposal. Stage77 implements
its first complete region before procedural geography/content expansion. Keep
the approved atlas art and its immutable snapshot. Owners002/003/009 retain
legacy travel; this opt-in pilot uses the same CampaignSession/equipment/dungeons.

## Persistence and time

Add an optional `living_world` block with its own version1 to campaign v4.
Existing profiles without the block keep their rules and bytes on read. Validate
the block when present; invalid data blocks mutations/load without replacement.
The pilot has a separate resumable `user://qa_living_world_v1.json`; it never
overwrites the ordinary player's profile. All commands and simulation steps use
CampaignSession's existing atomic commit. Failed writes publish no new state.
Serialize positions with full float precision so save/load never drifts actors.

The first geography is authored on the approved world illustration. A domain
navigation grid constrained to authored land computes paths; roads are faster
than wilderness/forest. This is continuous click-to-travel, not province/node
teleportation. Geography generation is the next stage after player review.
Stage78/world011 supersedes the coarse land-only mask and NPC straight legs
with shared weighted semantic terrain and explicit river crossings.

One simulation tick is15campaign minutes. The UI runs ticks every0.6real seconds
at1x, with pause/2x/4x; it interpolates the domain positions. Load always pauses.
Menus and tactical deliberation pause time. Camping advances time with reduced
fatigue; food is consumed every8hours and wages3gold every24hours. Hunger adds
fatigue/slows movement but never forbids returning. Depleted wages do not create
negative gold. These pilot upkeep rules apply only to the optional living mode.
Owned expedition packing still retains return provisions. Quantities and clocks
are bounded and deterministic; menus/paused rendering never advance/save ticks.

## World activity

Three settlements: Ravenford/River League, Saltwatch/River League and Black
Keep/Iron March. Settlements expose actual supply/security and food prices
(2gold below40supply, otherwise1gold), provisions and existing5gold inn recovery.
Existing equipment/training trading remains Ravenford's authored catalogue.

Caravan, two patrols and mine-based raiders move on persistent authored routes.
Raids remove cargo/supply; arrivals supply their destination; patrol contact
reduces bandit pressure and nearby friendly patrols protect caravans. Occupied Old Mine sustains raids, cleared mine stops
them. Rivalry tension escalates into a bounded border conflict, with faction
strength/security consequences and journal messages; this first model uses
patrol/skirmish activity rather than territorial conquest.
On escalation the Iron patrol extends its route to the contested border;
skirmish losses are applied on actual patrol proximity with a cooldown.

Company contact with active raiders uses the existing persisted ambush/toll/
tactical battle and return boundary. A grace interval prevents instant repeated
contact. Pending events and active expeditions block strategic tick/travel.
World location_id remains the last arrived atlas site during free movement;
all living service/entry gates additionally check actual position/stationarity.

## Contextual contracts and dungeon consequences

Contract offers have stable ids, condition-based creation, acceptance/progress/
report/paid states and at-most-once rewards. Accept/report at the issuer town.
Ravenford offers restoration when the mine is occupied and supply is low.
Black Keep offers reconnaissance of High Pass when border intelligence is absent.
Saltwatch offers a3food delivery when its supply is low. Outcomes affect actual
stock, gold/XP and faction relations; rewards are authored configuration.

Mine restoration requires a managed completed Old Mine or generated-mine run
with at least one genuinely cleared combat room. Bypassing enemies, retreat,
failure, another site or a duplicated return receipt does not restore the mine.
Campaign settlement marks the objective, clears the mine and changes supply/
security atomically with the existing dungeon receipt. Report pays the contract
once. The changed mine persists and cannot be farmed by revisiting/reloading.

Dungeon world time advances at checkpointed room visits and camps, not every
autosave: one tick per newly visited room,16ticks per newly used camp. Counters
live in the active run, so retries/reload cannot charge twice. The simulation
advances its world parties/factions during these ticks without surface contacts.
Daily wages still fall due at their normal boundary; food remains owned by the
dungeon rules and is not charged again as surface upkeep.

Proof: slice010, living_world_tests.gd, living_world_session_tests.gd, existing
campaign/road/dungeon suites and native pilot input/renderer. Physical player
review remains separate; no Debug Win can establish ordinary victory acceptance.
