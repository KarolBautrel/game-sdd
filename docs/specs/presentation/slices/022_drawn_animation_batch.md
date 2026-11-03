# Slice022: complete drawn knight preview, then character subset

Owner [presentation022](../022_drawn_animation_batch.md).

1. Record pose A selection and explicit background-continuation authorization;
   preserve all earlier sources and uncommitted work on2d-art-research.
2. Author and inspect knight neutral/combat/action sources. Verify nonempty frames,
   margins, alpha, shared scale/pivot, chronology, loop boundaries, glove/weapon
   grip and readable whole-body action. Saved Aseprite sources reproduce exports.
3. Package the local player, exercise asset loading/timing/pause/step/selection,
   provide a working open command BEFORE the character-subset mutation, record
   this communication, and continue without waiting for approval.
4. Prepare five further weapon profiles/character roles in order. Record exact
   delivered facings/actions and any reuse; source-only/incomplete candidates
   must not silently become full playable replacements.
5. Wire complete profiles into combat/gallery with neutral/combat distinctions,
   correct weapon-role visuals and fallback for untouched families. Test actual
   frame routing, finite death final state, action interruption and gear changes
   where touched. Renderer never decides legality/outcomes or resets saves.
6. Run targeted asset/runtime tests, repository validator and applicable combat
   slices. Inspect final native-scale contact sheets; observe a real continuous
   preview when isolated runtime permits, otherwise record it as unreviewed.
   Persist reports and deferred manual cases without pausing the authorized batch.

Final executable proofs: `tools/qa/build_drawn_animation_preview.py` (2344frames,
119 prior SHA identities), `tools/qa/check_drawn_animation_player.cjs` (3579checks),
`scripts/presentation/drawn_animation_tests.gd -- --require-all` (6980checks,
including12knight clips in8views, seven clips for five roles, gallery filtering,
real resolver impact/full-fall/reset lifecycle), original_roster_tests (15679),
combat_animation_lifecycle_tests, equipment_appearance_tests (31), combat_slice_tests,
combat_feedback_polish_tests (179), `tools/validators/validate_all.py`. All PASS.
Per-view Aseprite reopen/pixel/timing proofs and durable summary at
`assets_src/characters/drawn_animation/2026-11-03/batch_verification.json`.
Physical/continuous-motion gaps remain L53-01/L54-01/L54-02; see stage53/54.

Correction proof (stage55): compare native idle boot pixels across four cels for
all96 idle clips; each must match frame0 below the declared shin boundary, retain
nonempty upper-body animation and reopen exactly from saved Aseprite. Inspect N/
NE/NW shield interior samples. Verify1800ms bow attack and1260ms release in all
eight views, execute archer impact/recovery timing, rebuild catalogue/player and
retain before/after samples. PASS:7368 native checks,3579 offline checks, full
regression suites and validator. Imported idle comparisons ignore only RGB at
alpha0 (Godot fills invisible border colors); visible RGBA and alpha match exactly.
User explicitly accepts the corrections2026-11-03; ordinary gameplay gaps remain.
