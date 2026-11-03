# Approved warden motion pilot

Owner presentation018 / slice018. User2026-11-03 authorized implementation.

Latest2026-11-03: USER_REJECTED_MOTION. Archive all current work to `3d-models`;
stop this rollout. Research drawn/painted2.5D production next. Historical technical
results below do not override rejection of the gait, legs, sword action and hands.

1. TECHNICAL_PASS stage44: exact approved appearance,29 bones,56632 weighted
   vertices, no missing/opposite-side weights, at most2 influences. Actual rest
   files and texture bytes preserved; placement/deformation renders inspected.
   Boot cuff issue fixed. Deep-squat cloth limitations remain outside pilot range.
   [Report](../../../qa/stages/2026-11-03-stage-44.md).
2. TECHNICAL_PASS stage45: idle48/walk32/sword40frames at24fps,480 four-view PNGs,
   12 Aseprite sources and local looped player. All123 source frames measured;
   whole stance drift<0.002mm, no blade path hits or pose-loop break. Actual FBX
   6meshes/29bones/3actions, maximum posed drift<0.000002m after documented import
   connect-flag normalization. Boards/details inspected; validator PASS.
   [Report](../../../qa/stages/2026-11-03-stage-45.md).
3. USER_REJECTED: no full animation sets,
   eight-direction production rendering, distinct-face enemy families or runtime.
   Browser host unavailable: M018-01 controls/layout and M018-02 continuous1x
   playback are still pending; frame measurements/stills do not close them.

Preserve the stage43 package and all prior work.61 physical game cases remain
NOT_RUN. User now explicitly requests a complete current-state commit/push to
the separate `3d-models` branch, followed by internet research; no 3D expansion.
