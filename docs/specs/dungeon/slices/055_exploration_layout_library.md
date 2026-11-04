# Slice055: reproducible configuration library

Owner: ../overview/047_exploration_layout_library.md.

-15distinct recipes,5per length,4themes and60base combinations.
- Replay stays identical from copied/installed paths. Theme/difficulty changes
  preserve topology for the same seed and length.
- Seed sweeps check connectivity, duplicate ids/edges/positions, role counts,
  key reachability, exit accessibility, non-crossing diagram edges, routes that
  avoid unrelated room centers and pool diversity. Broken graphs fail.
- Copied-project smoke tests use a path with spaces and no game checkout.
-9runtime templates stay unchanged. Engine import/balance/playability/native
  fidelity remain later proofs; this is a preparation dataset.

Executable proof: `packages/dark-fantasy-ui-workshop/tests/test_workshop.py` and
`skills/dark-fantasy-game-ui/scripts/workshop.py check --seeds 100` from the package.
Result/evidence: `docs/qa/2026-11-04-dark-fantasy-ui-workshop.md`.
