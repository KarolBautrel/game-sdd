# World atlas and provincial travel

Date: 2026-11-04. User prioritizes review point3 (world) ahead of equipment.
Extends002/003; the accepted Marches map remains its province artwork.

The first atlas has four connected provinces and twenty named road destinations.
This is an authored persistent geography, not a per-visit randomized world.
The legacy region001 identifier remains the save's atlas identifier; province is
derived from the current node, so existing version4 saves need no destructive
migration. Node ids and the two original roads/costs are preserved. Province,
name, description and normalized map anchors are authored reference data.

The world overview opens province maps without moving the party. Any reachable
destination can be planned. Outbound routing minimizes hours; town-bound plans
minimize food, then hours, so the nearest-town reserve actually funds the shown
return route. Remaining ties break deterministically by node id. The plan lists
every stop and totals authored time/food. The engine
still commits exactly ONE adjacent leg through CampaignSession.travel. Continue
journey explicitly commits the next leg. Each leg revalidates food plus nearest
town return reserve, is saved atomically and rolls its existing road event once.
No distant teleport, advance charge, reroll by browsing or automatic event skip.
The total food requirement is the maximum prefix-food + return reserve along
the itinerary. A partially funded route may be inspected, but the next leg must
be affordable. The UI distinguishes next-leg affordability from whole-plan cost.

Pending road events/active expeditions block travel, not atlas browsing. A local
plan may survive an event within the current App instance; after restarting or
returning from a scene the player reselects the destination from the saved
location. Plans are presentation-only and never alter the campaign save.

Ravenford remains the only fully serviced town; Old Mine the only managed
expedition entrance. New camps, ruins, crossings and keeps are travel/viewing
destinations with descriptions and the existing authored road-danger system.
They provide no new interiors, shops, loot or healing. All destinations have a
connected return route to Ravenford. Duplicate ids, self/duplicate roads, invalid
anchors/province references and disconnected destinations fail validation.

Proof: world slice009, world_atlas_tests.gd, travel/save/road suites, reference
validator and native world/province/itinerary fixture. Physical player review
remains distinct from automated engine-local input.
