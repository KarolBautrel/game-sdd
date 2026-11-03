# Equipment/portrait/world acceptance

Current rollback acceptance2026-11-02: user rejected the modular model refinements.
Playable battle/gallery use stage33 PNGs again, including walk/combat/hit/death
and original sizes/pivots. Inventory has no modular3D preview. New world art and
illustrated portraits remain. Original-roster manifest hashes prove exact art
retention; native battle fixture verifies PNG routing, absence of ActorAtlasViewport
and at least three distinct walk frames during actual resolver-driven movement.
Modular-source tests/proofs below are historical/offline, not current acceptance.
Final [stage37 rollback report](../../../qa/stages/2026-11-02-stage-37.md):
56/56 project checks, final EXE318 native checks/49 clicks/43 captures PASS;
7 distinct packaged walk frames observed (8 in source). Physical play remains NOT_RUN.

Owner presentation010. Stage34: Blender source/GLB/FBX validation, native atlas
pose/contact/helmet views, distinct generated portrait sources/Aseprite exports.
Stage35: campaign gear/migration tests, modular renderer state tests and native
five-slot equip/unequip/change/reload/campaign-to-combat fixtures. Stage36: all
terrain families map to the new art, map/domain validation remains unchanged,
full verify_project/export_smoke and packaged native play/campaign evidence at
1080p/1440p/4K. Name concrete test files/run IDs in per-stage reports. Actual
normal-speed/ordinary gameplay remains NOT_RUN until desktop release.

Concrete proof: `modular_actor_tests.gd`, `equipment_appearance_tests.gd`,
`environment_art_tests.gd`, Python `test_modular_delivery.py` and
`test_world_art_delivery.py`; Blender `verify_modular.py` and actual FBX reimport
`verify_refined_fbx.py`. Stages34/35 reports link completed runs. Stage36 final
source/export/packaged-native run IDs must be persisted before closure.

Final closure: [stage36 report](../../../qa/stages/2026-11-02-stage-36.md).
`stage36-final-source-20261102`56/56,50 Python tests;
`stage36-final-release-20261102` export/runtime PASS; final EXE native runs
`stage36-packaged-play-20261102`, `stage36-packaged-gear-20261102` and
`stage36-packaged-bounds-20261102` all PASS (3181 checks/168 engine-local clicks/
147 captures, including2160 all-family GPU endpoint poses). Stages34..36 remain
AWAITING_INTERACTIVE;61 physical cases are NOT_RUN. No ordinary-play claim.
