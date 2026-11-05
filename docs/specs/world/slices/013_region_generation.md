# Slice013 — generated regions

Owner: ../013_region_generation.md; presentation039.

- Repeating seed/version/preset produces identical snapshots/checksums; different
  inputs change geography, river/coast paths and site placement.
- Batch seeds: all sites/waypoints connected, roads do not cross blocked cells,
  bridges connect banks, terrain coverage/context/separation gates hold and
  generation has bounded attempts/time. Fail a malformed/unsupported snapshot.
- Playing a seed uses a separate save; existing authored r9/profile are untouched.
  Continuous travel, NPCs, real mine preparation/retreat and gear return work.
- Reload resumes the exact generated snapshot/state without reroll/write. Failed
  transactions keep state/navigation intact. Independent regions do not leak
  navigation into one another or the designer map.
