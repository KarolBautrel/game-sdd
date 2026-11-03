# Ordered drawn knight combat pilot

Owner presentation021 / slice021. User2026-11-03.

0. ACCEPTED_ART_DIRECTION: both020 pixel/painted finishes fit the intended game.
1. STATIC_GUARD_DELIVERED / AWAITING_USER_VISUAL_REVIEW: both finishes, separate
   rigid sword/foreground gloves, native-scale ground and enlarged/layer boards.
   [Stage48](../../../qa/stages/2026-11-03-stage-48.md): builder PASS27 identities,
   source roundtrip/removable sword/ground anchor/palette/margins;20 original020
   PNG/source identities preserved. Validator PASS. Final boards inspected.
   SIDE_GUARD_DELIVERED / AWAITING_USER_VISUAL_REVIEW2026-11-03: user-reference
   correction in both finishes, hands lateral near shoulder, nearly upright
   blade; [stage49](../../../qa/stages/2026-11-03-stage-49.md). Before/after and
   four other boards inspected. Builder PASS30 identities;47 previous PNG/source
   hashes unchanged, exact source/weapon/ground/margin checks; validator PASS.
   Stage48's central guard is superseded for the next animation reference.
2. QUEUED_AFTER_GUARD_REVIEW: short3/4 readiness/walk/single-cut motion prototype.
   QUICK_WAIST_SAMPLE_DELIVERED: user requests crossguard at belt height and grip
   slightly inward. One painted trial and source/native before-after review,
   [stage50](../../../qa/stages/2026-11-03-stage-50.md). Builder PASS,77 previous
   file identities preserved; validator PASS; final board inspected. Subsequently
   REJECTED by user as too low. Preserved as evidence, not a chosen guard.
   TWO_POSE_SAMPLES_DELIVERED: [stage51](../../../qa/stages/2026-11-03-stage-51.md),
   separate front/side JPG references, TWO hands explicitly confirmed for both.
   Front projects arms/sword forward; side grips above belt, below shoulder.
   Two painted studies plus full/grip comparison, Aseprite sources; builder PASS8
   identities/83 prior files preserved/reference copies; validator PASS. Boards
   inspected. User final pose review pending.
3. QUEUED: continuous normal-speed/native-scale motion review and corrections.
4. QUEUED_AFTER_MOTION_ACCEPTANCE: directional/action expansion and one-knight
   integration, before further cast production.

Shared art direction approval is recorded; guard and motion approval are pending.
Historical Git, paid providers/installations and desktop control remain outside
this background work. Preserve the61 NOT_RUN gameplay cases and all020 sources.

Current rebuild: `python tools/qa/build_drawn_knight_guard_side.py`.
Current exploratory pair: `python tools/qa/build_knight_pose_pair.py`.
Previous preserved guard: `python tools/qa/build_drawn_knight_guard.py`.
Project check: `.venv/Scripts/python.exe tools/validators/validate_all.py`.
Next: guard-pose feedback/corrections, then the authorized short3/4 motion pilot.
