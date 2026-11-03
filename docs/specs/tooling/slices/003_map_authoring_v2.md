# Slice003: map authoring v2

Owner: ../003_map_authoring_v2.md

| ID | Scenario | Expected |
| --- | --- | --- |
| M4-01 | Convert canonical TMX twice | identical v2 JSON; visuals/spawns preserved |
| M4-02 | Invalid grid, gid flags, objects, asset, spawn | reject without writing output |
| M4-03 | Both runtimes load map | same grid/visual defaults, encounter overrides win |
| M4-04 | Workbench loads referenced encounter | visible full board/spawns, source bytes unchanged |
| M4-05 | Edit tile/decor/unit spawn, save copy/reload | complete independent inline data, no map_path |
| M4-06 | Block/overlap spawn, Play Draft | invalid blocked; valid draft uses normal resolver |
| M4-07 | Real workbench round trip | edit, save copy, reload, play move/attack, return |

Automated proof: tests/test_tiled_maps.py and scripts/presentation/map_authoring_tests.gd.
Manual proof: stage4 report. All prior suites must pass before advancing.
