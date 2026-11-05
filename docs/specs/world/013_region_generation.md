# Seeded region generation v1

Stage80, user authorization2026-11-04: implement the proposed region generator.
Preserve the authored Marches map, designer terrain r9 and existing save files.
World010..012 retain simulation/contract/movement rules. This first geography
generator keeps six functional site roles and the current three-town/two-faction
loop; wider multi-region travel and new contract families are later increments.

## Generation order and invariants

Input: positive integer seed1..1000000000, version1 and preset marches/woodland/
highlands. The same inputs produce the same192x108 geography, independent of
preview history. Bounded deterministic retries are permitted and recorded.

1. Build coherent elevation/moisture fields and an irregular coast. Form
   clustered forest, hills, accessible slopes and blocked peaks; no random
   independent terrain-cell confetti.
2. Carve source-to-coast river channels through low ground, eroding their
   channel profile downstream. Tributaries join a real river. Water is blocked.
3. Place explicit bank-to-bank bridges/fords on suitable channels. Prove their
   bank connectivity; ordinary roads cannot silently turn water/peaks walkable.
4. Find connected accessible ground. Place three settlements, the defended mine,
   a mountain-pass landmark and forest abbey with separation and terrain/context
   suitability. Retain current role ids/names for the existing pilot's contracts.
5. Plan terrain-weighted roads between settlements and branch routes to sites.
   Preserve bridge cells and blocked peaks/water. Store actual detailed paths
   plus bounded NPC waypoints. All sites/waypoints and road segments must be
   reachable/safe; inaccessible candidate layouts are rejected, not shipped.

Generated coast/forest/mountain/river/road geometry must materially vary by seed
and preset. The map renderer consumes these exact data, not a fixed illustration
with randomized labels. Diagnostics expose coverage, accessible component,
crossings, path safety and attempt count. Generated sites remain stable after
starting/resuming a campaign.

## Persistence and playable pilot

Optional `living_world.geography` stores an immutable versioned snapshot with
seed/preset, terrain, sites, river/road geometry and a content checksum. Save the
snapshot, not only a seed, so future generator/engine changes cannot redraw an
existing campaign. Reject corrupt/unsupported snapshots without replacement.
Definition/navigation must be profile-specific; validating/previewing another
region cannot change the active region's navigation or the authored mask.

Preview generation is read-only. Play/Resume opens a separate resumable
`user://qa_living_world_generated_v1_<preset>_<seed>.json` through the existing
CampaignSession boundary. Fresh generated profiles reuse real equipment, upkeep,
caravans/patrols/raiders, contracts, mine entry and managed settlement/return.
The authored pilot has its original separate save and remains available from the
region selector. Never replace a live region or reset progress to reroll it.

Proof: slice013, region_generation_tests.gd, generated_region_session_tests.gd,
snapshot schema/reference checks and actual native generated-region travel.
