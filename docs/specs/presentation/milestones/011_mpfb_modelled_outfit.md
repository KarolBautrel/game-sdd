# Warden: coherent legs and actual outfit volume

USER_REJECTED2026-11-02. This queue is cancelled by the explicit rollback to
stage41 with boots-only correction. Follow [milestone012](012_warden_boots_only_rollback.md).
Historical technical results below do not grant art acceptance.

Owner presentation016 / slice016. User authorized2026-11-02.

1. DONE: anatomical body/leg axes measured, stage41/reference identities pinned;
   four approved head/eye/hair/brow geometry/UV/shader identities preserved.
2. DONE: knee/ankle alignment, smaller boots, real cuirass/shoulder crowns/lames,
   leather bands/buckles, cloth panels and drape.105 editable outfit parts.
3. TECHNICAL_PASS:194738 offline triangles;8906 assertions, actual FBX import,
   all7 maps/eye alpha, bounds drift0.000000164m, zero mesh-audit errors and5
   retained warnings. Three Aseprite boards/16 rendered views inspected.38 stage41
   +202 earlier model +8223 roster +215 world files unchanged. Validator and
   git diff --check PASS. See [stage42](../../../qa/stages/2026-11-02-stage-42.md)
   and [guide](../../../design/character-art/MPFB_MODELLED_OUTFIT.md).
4. AWAITING_USER_REVIEW of the corrected body/outfit; then full-body rig/short motion proof,
   varied head/body/equipment recipes and only later full animation/enemy batches.

Current work is background static art only;61 live scenarios remain NOT_RUN.

Reproduce: background `build_warden_outfit.py`, `verify_warden_outfit.py`, hidden
Aseprite `warden_outfit.lua`, project validator. The anatomical master uses the
recorded source-to-costume matrix; do not attach an unscaled rig. Read the
[variation plan](../../../design/character-art/CHARACTER_VARIATION_PLAN.md) before
cast work: different geometry/age/skin/hair and silhouettes, not recoloured clones.
