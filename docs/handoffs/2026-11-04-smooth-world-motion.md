# Latest handoff: smooth world motion on designer revision9

User manually refines terrain and accepts it as a good basis, then asks to smooth
interrupted movement and explain the next step. No request to publish this turn.
Master remains564dbdae; local stages78/79 and the user's mask must be preserved.

Designer terrain revision9 SHA256:
a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327.
Runtime file remains byte-identical; durable copy under assets_src/world_navigation/
2026-11-04/. Never regenerate the initial trace over this work.

Owners world012/presentation038 and slices012/038. Stage79 replaces the renderer's
per-tick A* with committed weighted-time traces and one accumulator/phase. Pause
and speed changes preserve pose/time. NPCs carry leftover budget through ordinary
route points; patrol guard rests remain intentional. Visible NPC banners draw at
subpixel positions with native hit/focus targets. Exact route endpoint trimming
is terrain-safe and cost-checked. Base speed/costs/tick duration stay unchanged.
Traces are transient, publish only on successful commit, and roll back on failed
writes. The validator accepts Godot integral-float metadata without rewriting it.

Focused motion52, navigation27, living28, session41/UI97 and seven Python tests
pass during implementation. Final full/native receipts and actual frame records
are in [stage79 QA](../qa/2026-11-04-smooth-world-motion.md). Do not confuse a
static frame sequence or native metrics with physical feel acceptance.
Final exact-source verification78/78 PASS (63Python tests), zero diagnostics.
Complete core native318checks/114pointer actions/38captures PASS; final banner
layer native78checks/28actions/8captures PASS, zero diagnostics and540frame
samples. Ten unaltered screenshots, raw samples and compact receipts retained.
Final runtime r9 hash and its durable backup still match the turn-entry bytes.

Next: user restarts `& .\tools\qa\start_game.ps1 -Scene living-world`, checks
bridges/curves and pause/resume at1x/2x/4x. Then propose seeded regions built from
terrain/crossings before placing settlements/roads/dungeons, retaining this
authored Marches region. That generator is a proposal, not authorized work yet.
Do not reactivate the expired two-hour batch or old art work. Ordinary physical
mine victory and equipment/battle/courtyard reviews remain saved/unreported.
