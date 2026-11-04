# Slice031: player-reported dungeon visual defects

Owner ../031_dungeon_visual_cohesion.md. Stage72.

1. Current72c restoration: compare native output with the preserved textured72
   reference. It must match before researching a replacement. Magnified edge grain
   remains a known visual defect. Shared world resources retain their behavior.
2. At720p/1080p/1440p/4K, inspect both full and injured HP, portrait rectangles,
   name/HP line heights and bar containment inside each company card/footer.
   Red fill is identical for Bran/Torin and reflects actual model resources.
3. For authored and generated graphs, route id pairs exactly match corridors.
   Polyline endpoints connect the intended plates; interior segments avoid
   unrelated plates. Route layer ignores mouse input. Selecting a room cannot
   create a new corridor or mutate run state; adjacent selection emphasizes only
   the existing route from current room toward the selected destination.
4. Use real native controls for start, room preview/confirm, shrine event, rubble,
   oil and loot. Verify existing state/cost/focus guards and complete rendered
   frame bounds. Capture generated layouts as well as the exact illustration.
5. Keep L67-01/player-review1 open for the user's visual retest. Historical source
   PASS and agent GPU inspection never imply user approval or completed OS play.

Executable proof: dungeon_visual_cohesion_tests.gd plus existing route-preview,
party-layout and expedition-art suites; native play review --views dungeonpolish.

Follow-up72b: inspect native unscaled frame-edge/corner crops against stage72.
No stretched grain bands, large mottled pixels or irregular enlarged rivets.
Straight rails keep their thickness; corners retain the approved shape. Check
the surrounding backdrop at720p/1080p/4K and rerun affected presentation checks.

72b is now REJECTED_BY_USER.72cproof: native restored1080p route PNG matches the
preserved72reference SHA256 exactly;692cohesion checks/validator/native restore
fixture PASS. Skill/pack/MCP research and the independent concept are recorded
under design/dungeon-ui/research-2026-11-04/. A raster concept is not native UI
acceptance and must not become the default before the user's look selection.
