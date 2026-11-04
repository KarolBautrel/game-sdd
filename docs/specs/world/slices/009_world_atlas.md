# Slice009: provincial atlas

Owner: ../009_world_atlas.md; presentation035.

- Existing v4 profile opens at its original node; loading never rewrites bytes.
- Twenty destinations in four provinces are connected. Two legacy quotes remain.
- Distant plans list adjacent legs/totals deterministically and leave state intact.
- Confirm travels one leg; events block continuation until resolved. Arrival
  clears the finished plan. Every stop has a legal return route.
- Cross-province travel reloads; insufficient food/failed writes remain atomic.
- Every shown return plan can be completed with exactly the nearest-town food
  reserve. Black Keep uses the three-food high-pass route rather than the faster
  four-food road; native outbound/return confirms actual town service reopening.
- Native overview -> province -> destination -> plan -> next leg and bounded
  labels are captured at720p/1080p without desktop input or player saves.

Proof: scripts/session/world_atlas_tests.gd, journey_interface_tests.gd,
world_travel_tests.gd, road_event_tests.gd and native campaign review.
Physical/global travel and player visual review: NOT_RUN until reported.
