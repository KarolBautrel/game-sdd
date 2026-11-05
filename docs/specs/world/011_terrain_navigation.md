# Terrain-aware living-world navigation

Stage78, authorized2026-11-04 after user approval of the living-region pilot.
Publication checkpoint: f0fc7d16 on master. Preserve the approved atlas pixels.

## Authoritative terrain

The living region references a versioned192x108 semantic cell map over the
entire16:9 illustration. Each cell is road R (cost1), plains P (1.3), forest F
(2), hills H (2.5), difficult mountain slopes M (3.3), water W (blocked), peaks X
(blocked), or an explicit bridge/ford B (1.15). Costs are time per unit distance;
speed is their reciprocal. Slopes remain accessible, high peaks do not.
Water includes rivers and sea. Crossings are authored exceptions in the mask;
ordinary roads never automatically override water or peaks. The initial mask
is manually traced from the illustration; the editor can refine its boundaries.

Company, caravans, patrols and raiders use the same weighted navigation and
movement integration. A* chooses low-time routes, prohibits diagonal corner
cutting, and connects exact endpoints through their own cell centers or a direct
endpoint link proven terrain-safe and no more expensive (world012). Movement
spends its budget across terrain boundaries, including multiple cells per tick.
Distance uses the map's16:9 aspect, so equal screen distances have equal cost.
An invalid/blocked destination is rejected without changing campaign state.
Patrols guard each circuit endpoint for eight ticks (two campaign hours). This
keeps border contact spatial while avoiding synchronized circuits that always
miss one another after terrain changes their travel times.

## Persistence and edits

Navigation caches are keyed by the semantic map signature. Optional terrain
signature and actor path fields extend living state v1 compatibly. Legacy
profiles remain readable. Loading alone does not write or reset progress.
New coordinates use seven decimal places (below0.0002source pixels), avoiding
float-parser drift across repeated JSON save/load roundtrips.
At the next travel/tick command after a mask change, replan the company route
and all NPC legs. If a saved position is newly blocked, project it to the nearest
accessible cell in the settlements' connected mainland and record that recovery
in the journal; never strand the company in an isolated pocket or reset it
to Ravenford or erase contracts/resources. An unreachable old goal stops travel.
Current-signature positions/paths must be passable. Ordinary campaign and pilot
save isolation, atomic commits and dungeon-owned food/time rules remain010.

The terrain editor writes only the region's terrain data, using validated atomic
replacement and retaining the prior file as a local backup. It rejects malformed
rows/codes and masks disconnecting any site or required NPC waypoint. It does
not write campaign profiles. Successful save increments revision; game reload
uses the new mask. A baseline reload is undoable before saving.

Proof: slice011, terrain_navigation_tests.gd, existing living/session suites,
terrain data validator and native editor/runtime review. User review of fine
geographical alignment remains available; no procedural geography is implied.
