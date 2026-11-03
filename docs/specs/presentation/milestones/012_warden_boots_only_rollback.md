# Restore stage41 with smaller existing boots

Owner presentation017 / slice017. User2026-11-02 rejected stage42.

1. DONE: exact stage41 armor/face/pose/texture source restored in a separate
   current package; original foot width/depth reduced6%, smooth blend to unchanged
   upper shaft above0.32m. All Z and all non-boot geometry/materials unchanged.
2. TECHNICAL_PASS:65209 actual-file assertions,110384 triangles/5 meshes, actual
   FBX reimport/maps/UV/bounds, byte-identical original textures;38 stage41 +44
   rejected-stage42 +8223 roster +215 world hashes retained. Matched visual board
   inspected; validator and git diff --check PASS. Read
   [stage43](../../../qa/stages/2026-11-02-stage-43.md).
3. USER_STATIC_APPEARANCE_ACCEPTED2026-11-03: user reviewed the restored preview
   and says it is good. This closes the static rollback/art review. Preserve the
   approved package; do not resume stage42 or its animation/cast rollout queue.

The subsequent2026-11-03 "No to dawaj" authorized the fitted rig and small
idle/walk/one-weapon-attack pilot under presentation018 / milestone013. That
isolated source pilot is technically delivered; user motion review remains the
next gate. This does not revive stage42, authorize full sets or release controls.

All61 physical cases remain NOT_RUN; no production change or commit/push.
