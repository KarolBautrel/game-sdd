# Slice012 — continuous strategic motion

Owner: ../012_continuous_motion.md; presentation038.

- Trace samples follow actual terrain-safe segments monotonically in weighted
  time. A within-cell walk does not detour back through that cell's center.
- NPC movement carries remaining budget through a route waypoint in one tick;
  patrol guards and real arrivals still stop deliberately.
- Rendering traces never alter the persisted profile. Failed save rolls back
  both simulation and transient trace publication; reload starts stationary.
- Godot integral-float mask metadata validates without rewriting revision9.
