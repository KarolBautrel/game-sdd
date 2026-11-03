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

Stage56: load `drawn_roster_skirmish` through the scenario catalogue and the opt-in
launcher setting. Verify four allies/four enemies, all six explicit painted
profiles, matching equipment and distinct UI names. Execute each role's movement,
attack, hit and complete death through CombatDebug/resolver; check bow release,
normal input unlock and reset during pending playback. Exercise full legal-command
battles to victory and defeat without Debug Win. Proof:
`scripts/presentation/drawn_battle_review_tests.gd`, combat slices, existing drawn
runtime/equipment suites and repository validator. User-run normal-speed ordinary
victory/defeat and board readability remain L56-01/L56-02, not automated acceptance.

Stage57: record user defects for slow movement, narrow warrior rear stance and
explicitly requested sword occlusion. Back up affected source/runtime identities.
Set only neutral_walk/combat_walk cels to50ms in all96 source clips and manifests;
prove matching400ms runtime cycles and80px/400ms travel, with unaffected idle/
attack/hit/death timings. Redraw warrior north standing/locomotion/attack/reaction
poses with shoulder-width standing feet, interior shield and held sword mostly
hidden in front of the torso; retain death and other facings. Aseprite idle lower
contact must remain exact across the loop, with upper-body breathing retained.
Run source reopen/pixel/tag/duration proof, current battle/runtime/combat checks
and repository validator. Provide native/enlarged comparisons and the real battle
command; continuous visual retest is L57-01, separate from numerical proof.

Stage58 supersedes57 cadence: back up the current candidate, restore96 walk clips
to100ms cels, publish160px stride and prove800ms gait/200px/s travel in runtime and
preview. New knight-only idles and neutral walks must show a broad/staggered combat
base and lowered held neutral sword in all eight facings (five drawings/three
reflections), with planted breathing feet and original other actions preserved.
Verify source reopen/pixels/tags/timing, loaded renderer routing, phase/travel,
attack/hit/death/reset and validator. Supply a comparison that shows movement
against the floor at normal speed. L58-01 is the visual retest; no terminal result
or new roster production is inferred from this correction request.

Stage59: explicit user rollback of58. Restore its retained pre-change861-file
baseline byte-for-byte and copy restored source PNGs back to runtime. All2304
runtime PNG hashes must match pre58, and registry must return to400ms/80px. Preserve
unrelated stage56/57 work, record rejection and block automatic58 reapplication.
Run restored runtime/battle/combat checks and repository validator. Stop visual
iteration; no new approval or character production is requested.

Stage60 is newly authorized after rollback: native-pixel neutral pose matching the
shield warrior, preserving knight head/boots/combat appearance; all96 walks125ms
per cel/1000ms cycle and160px stride. Back up the restored state, verify Aseprite
sources/exports/idle contact, unchanged other raster actions and all non-walk
durations. Actual CombatDebug movement must follow160px/s with no more than a
partial slow cycle for a104px step. Run runtime/battle/combat checks and validator;
provide native-scale pose samples and normal-speed distance-aware preview. L60-01
is visual retest, and prior rejected58 remains blocked.
