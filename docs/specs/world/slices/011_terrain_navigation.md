# Slice011 — terrain navigation

Owner: ../011_terrain_navigation.md. Stage78.

- River/sea/peak destinations fail atomically; opposite banks route via a
  designated crossing, never a diagonal gap or first/last endpoint shortcut.
- Weighted routing can prefer a longer road over a short forest/mountain route.
  Equal movement budgets travel progressively less far on plains/forest/hills/
  slopes. Crossing a terrain boundary consumes both actual costs in one tick.
- All six sites and NPC waypoints remain connected. Long simulations keep
  every group and traversed segment on passable terrain, while deliveries,
  raids and faction conflict still operate.
- Legacy mid-route saves survive a new mask; only a transaction reprojects a
  newly blocked position/replans its route. Failed writes preserve old state.
- Invalid masks/rows/disconnected sites fail validation. Editor paint/undo/redo,
  route probe and save/reload use the same domain map as the runtime.

Proof: scripts/domain/terrain_navigation_tests.gd, living_world_tests.gd,
living_world_session_tests.gd, terrain_editor_interface_tests.gd and native QA.
