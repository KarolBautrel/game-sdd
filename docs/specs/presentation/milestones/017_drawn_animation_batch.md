# Ordered drawn animation production

Owner022 / slice022. Latest user2026-11-03 authorizes autonomous continuation.

1. DELIVERED / USER_ACCEPTED_3Q:12 knight clips,68 redrawn frames, neutral/combat
   modes using selected pose A. Explicit positive motion feedback2026-11-03.
2. DONE: knight-preview command supplied in chat BEFORE other-character generation
   began; user opened it and approved motion. Continued immediately as instructed.
3. SOURCE_PACKAGE_PASS: sword/shield, bow, daggers, axe and spear roles completed.
   Five drawn camera views and three disclosed Aseprite reflections per role.
   Dedicated front/back bow and spear attack repairs used; mixed-facing/opaque
   left-view candidates retained unused. Neutral main breathing uses two drawings
   held500ms each in four250ms cels. All48 view sources reopen pixel-exactly.
4. IMPLEMENTED / AWAITING_INTERACTIVE: all six profiles active through the existing
   raster renderer. Knight12 clips x8views=544 runtime frames; each other role
   seven primary clips x8views=352 frames. Total2304 runtime frames. Native gallery
   exposes all roles, knight extras, facing/clip selection, pause/step and floors;
   available standalone and from Tools. Separate knight test encounter added.
   Authored walk/idle timing, attack-impact/reaction/recovery, complete fall and
   reset cancellation implemented without changing resolver/equipment/save rules.
5. AUTOMATED_PASS / AWAITING_INTERACTIVE: offline player2344 frames/386 clips,
   398 editable Aseprite sources including two boards and ten independent weapon
   masters. Runtime copy hashes verified;119 earlier source identities preserved.
   Static native-scale neutral/attack boards inspected; no continuous-motion
   observation by the agent claimed. Exact final evidence below.

Final checks2026-11-03:

- `build_drawn_animation_preview.py`: PASS,6profiles/2344frames.
- `node tools/qa/check_drawn_animation_player.cjs`: PASS,3579 timing/canvas checks.
- `run_drawn_godot_checks.py --import-assets --require-all --regression`: PASS;
  final native6980 checks, original roster15679, equipment31, feedback179, animation
  lifecycle OK and domain combat slice validation passed. Logs have no engine
  errors/warnings. Includes actual resolver-driven attack/hit/death, impact timing,
  full final frames, reset cancellation and embedded gallery input restoration.
  Final gallery step/resume correction rechecked with `--require-all --only
  runtime`:6980/0. Other regression suites passed before this gallery-only fix.
- `build_catalogue.py`:9920 textures; `validate_all.py`: PASS.
- `summarize_drawn_batch.py`: PASS,48views,386animation sources,398Aseprite files.

Proof: [stage53](../../../qa/stages/2026-11-03-stage-53.md),
[stage54](../../../qa/stages/2026-11-03-stage-54.md),
[source guide](../../../../assets_src/characters/drawn_animation/2026-11-03/README.md)
and its `batch_verification.json` / per-view reports. Browser render unavailable:
browser access host unavailable. Shared art/pose A and original3/4 knight motion
accepted; directional/other-role and gameplay visual acceptance pending.

Next: user gallery and ordinary battle/campaign review, L53-01/L54-01/L54-02.
Do not regenerate the completed directional queue or start another roster batch
without new scope. All61 earlier physical cases remain NOT_RUN. No native desktop
input/visible agent launch, external paid provider, installation or Git mutation.

Active user feedback2026-11-03: overall result praised; fix idle sliding, shield
interior on rear views and stronger/longer bow draw/aim/release. Stage55 COMPLETE /
USER_ACCEPTED_PREVIEW:96 idle clips have planted lower shins/boots, N/NE/NW shield
interiors corrected, bow attack1800ms with1260ms release in8views.938 before files
retained;125 before/after samples supplied. Explicit user approval "Tak ma byc".
Native7368checks/0failures; full roster/lifecycle/equipment/combat/feedback suites,
offline3579checks and repository validator PASS. See stage55 and newest handoff.
Next: user's next task; no further visual iteration is currently requested.

Subsequent explicit publication request completed: full source checkpoint9edbd4a3
merged into default master as167e2e22, ordinary push confirmed;4069LFS objects /
404MB uploaded. Source audit4626files PASS, author/committer linked to KarolBautrel.
Existing main README cleanup preserved; historical author repair not executed.
Receipt: docs/qa/2026-11-03-drawn-main-publication.md. The separate reusable English
workshopv1.0.1 is subsequently published and installed; see its dated handoff.

Stage56: user explicitly selects next-step point1, actual battle review of the six
current roles. IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE. Added isolated
four-versus-four `drawn_roster_skirmish`, matching existing-rule loadouts, distinct
actor names/title and validated opt-in direct launch. Source/accepted art unchanged.
Owning presentation022/slice022 and tooling001 updated before implementation.
`drawn_battle_review_tests.gd`:301/0, all six roles movement/attack/hit/full death,
impact/MP/reset/input, direct/default launch, real board sprite loading; full
legal-command Godot simulations victory69commands and defeat96commands, no Debug
Win. Drawn7368/0, equipment31/0, feedback179/0, lifecycle/combat slices and validator
PASS; launcher ConfigureOnly/invalid-ID/scene checks PASS, original local profile
restored. User launch command sent; physical/continuous visual review still NOT_RUN.
See stage56 and L56-01/L56-02. Next: user's ordinary battle result and fixes within
point1. No additional art batch, weapon mechanics or Git publication authorized.

Stage57: actual user battle review reports slow movement, narrow warrior north
stance and explicitly requests sword occlusion. Remaining animation/movement
described positively, terminal result not given. IMPLEMENTED / AUTOMATED_PASS /
AWAITING_USER_RETEST. All96 walk sources now50ms cels/400ms cycles at80px stride;
source/player/runtime agree. Warrior/north redrawn with wider planted feet and
held sword in front of torso, inner shield preserved.313 before files retained;
exactly36 runtime PNG edits,2268 other PNGs and north death unchanged. Source
roundtrip/idle contact/timing/scope PASS. Native7386/0, battle307/0 including actual
movement timing, original15679/0, equipment31/0, feedback179/0, lifecycle/combat
slices/import/offline3579/validator PASS.18 native/2x before/after samples supplied.
Owning022/slice022 updated; see stage57/new handoff and L57-01. Next: user retest
within point1, ordinary terminal cases still open. No new roster/Git/workshop scope.

Stage58: user rejects57's rapid foot cycling; requests wider combat stance and
lowered neutral sword for the two-handed knight. IMPLEMENTED / AUTOMATED_PASS /
AWAITING_USER_RETEST. Restore96 gait clips to100ms cels/800ms cycles and use160px
stride, preserving200px/s root travel at half the cycling. Knight neutral/combat
idles and neutral walking redrawn in5views+3 mirrors, broad/staggered guard A and
lowered held sword.128 runtime art edits;2176 others and all non-walk timings
unchanged.861 baseline files, Aseprite saved source/idle planting/scope proofs PASS.
Native7386/0, battle307/0, original15679/0, equipment31/0, feedback179/0,
lifecycle/combat/import/offline3579/validator PASS.36 native/2x before/after samples
with distance-aware floor supplied. Owning022/slice022 and source configs updated.
See stage58/new handoff. L57-01 partial/rejected cadence; L58-01 pending. Next is
user visual retest within point1; terminal/campaign cases and later scope stay open.

Stage59: user explicitly REJECTS58's blurred model/posture and requests rollback
and stopping for now. RESTORED_EXACTLY:861 pre58 source/metadata/registry hashes
and2304 runtime PNG hashes match. Original knight appearance/poses/neutral carry
and stage57's400ms/80px cadence restored; earlier56/57 work preserved. Rejected
changes archived, automatic58 reapplication blocked. Restored runtime/battle/
combat/player/validator checks recorded in stage59. No new visual acceptance,
terminal result or Git publication. Next: wait for user's new task; no iteration.

Stage60: user newly authorizes neutral standing closely based on sword/shield
warrior and calmer walking. IMPLEMENTED / AUTOMATED_PASS / AWAITING_VISUAL_REVIEW.
Native-pixel Aseprite composition preserves original knight head/boots,24 neutral
PNG edits only;2280 other graphics (all walking/combat) unchanged.301 before files.
All96 gait sources125ms cels/1000ms cycles/160px stride give160px/s, two foot contacts
per second; other durations/domain rules unchanged. Native7386/0, battle313/0,
original15679/0, equipment31/0, feedback179/0, lifecycle/combat/import/offline3579/
validator PASS.28-case reference/before-after/distance-aware viewer logic PASS.
Owning022/slice022 updated; see stage60/new handoff. Next: L60-01 user visual review
only. Rejected58 stays blocked; no broader production or publication authorized.

Subsequent user decision2026-11-03:60 USER_ACCEPTED_FOR_NOW; "na ta chwile
zatwierdzam". User requests the accepted current work in the main game repo and
asks for next-step advice. Publish on default master after checks. Keep a deferred
posture/locomotion polish item; do not iterate further now. Rejected58 and open
terminal/campaign cases remain distinct. Suggested next scope is the character
identity/weapon contract before the remaining human roster, then a creature pilot;
this is advice, not a newly authorized implementation batch.
