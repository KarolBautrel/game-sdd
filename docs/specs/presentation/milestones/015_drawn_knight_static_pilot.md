# Two drawn knight proposals

Owner presentation020 / slice020. User2026-11-03.

1. STATIC_DELIVERED: generated pixel/painted sources, persisted prompts, two-layer
   Aseprite masters/native sources, native-scale ground boards, 3x/8x native
   enlargements and a separate painted-source detail board. Background builder
   PASS:20 hashed files, PNG/source headers, exact native source roundtrip,
  45 pixel colors/binary alpha. Final boards inspected. See [stage47](../../../qa/stages/2026-11-03-stage-47.md).
2. ACCEPTED_ART_DIRECTION2026-11-03: user says both finishes fit the intended
   game. They request a two-handed combat guard instead of the rest sword pose.
3. SUPERSEDED_BY021: user authorizes the discussed ordered stages, starting with
   static guard review in both finishes. Finish choice may be resolved through
   that representative proof. See milestone016; no skipped visual/motion gates.

No historical Git work, installation, provider purchase or native desktop input.
All61 gameplay cases remain NOT_RUN. Technical checks are not art approval.

Reproduce: `python tools/qa/build_drawn_knight_static.py`.
Repository check PASS: `.venv/Scripts/python.exe tools/validators/validate_all.py`.
Next: presentation021 combat-guard review, then the ordered motion prototype.
