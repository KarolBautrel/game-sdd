# Slice038 — smooth world motion

Owner: ../038_smooth_world_motion.md, world012/slice012.

- Within one cell and across tick boundaries, forward travel never reverses
  toward a cell center or stops for an interpolation reset.
- Equivalent elapsed time at30/60/144FPS gives equivalent positions;1x/2x/4x
  preserve phase and terrain safety. Multiple simulation steps do not replay
  stale traces. Pause/resume and rate changes do not jump the marker.
- Native live-frame capture samples company and every active NPC, records
  discontinuity/blocked-position checks, and retains an actual frame sequence.
- Designer mask SHA256 is unchanged and ordinary saves are not used for QA.
