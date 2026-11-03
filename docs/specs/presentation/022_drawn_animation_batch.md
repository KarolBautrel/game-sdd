# Drawn animation batch: knight, weapon profiles and playable character subset

Latest tactical-view override2026-11-03: presentation024/stage62 displays only
south_east/south_west in battle, across all actions/families. Keep all eight
authored views and the existing galleries/sources for future use. Earlier
eight-direction runtime requirements below are superseded at the battle sprite
selection boundary; no new city movement or raster regeneration is authorized.

User2026-11-03 accepts painted pose A from stage51 as the DEFAULT two-handed
sword combat guard; the side guard is no longer that default. Retain the previous
neutral/rest pose for noncombat presentation. The comment that both poses may
be useful preserves alternatives, not a reversal of the explicit A selection.

Latest explicit authorization: build all knight animations in neutral/combat
modes; provide the animation-preview command BEFORE rewriting other characters,
then CONTINUE immediately without waiting for a reply. Prepare sword+shield,
bow, daggers, axe and related weapon poses/animations and replace a useful subset
of characters for testing. This supersedes021's stop-for-visual-feedback gate for
this batch. Automated failures still require correction. User visual acceptance
of the final animation/roster remains pending; don't label it accepted by silence.

Subsequent explicit feedback2026-11-03: user watched the supplied knight player,
says the animations are very good and accepts the3/4 knight motion. They ask to
continue the entire discussed batch and send further review commands periodically.
This is user-reported visual acceptance of the delivered3/4 action set, not
eight-direction acceptance or a claim that the agent watched continuous motion.

## Ordered delivery

1. Knight action set with painted appearance and selected forward two-handed
   guard; neutral/combat idle and walk, draw/sheath, primary cut, secondary thrust,
   block, dodge, hit, death. Preserve identity, gloves, reasonable boots/anatomy,
   source palette/exposure and rigid sword. Expose clips in a local player with
   1x speed, native scale/enlargement, pause, step, frame/timing and ground choice.
   Give the real working open command as soon as packaged, then proceed.
2. Same visual system across sword/shield, bow, paired daggers, axe and spear.
   Use distinct original archer, rogue, raider/spearman appearances where their
   roles differ. First playable subset: warrior/knight, archer_1, rogue_1,
   axe_bandit, bandit_spearman, plus the two-handed knight profile. Preserve all
   other old families and original sources; no wholesale destructive replacement.
3. Required runtime repertoire: neutral idle, combat idle, neutral/combat walk,
   attack, hit and death for eight facings. Additional showcase clips remain
   explicitly discoverable. No same-facing duplication labelled as eight drawn
   directions. Any mirrored/reused motion or incomplete view must be identified.
4. Integrate only complete, validated character profiles through the existing
   raster renderer; preserve authoritative resolver/equipment/save rules and
   world/UI. A source-preview character is not yet a playable replacement.
   Present a gallery containing every new character/weapon/clip and a native
   test entry point. Preserve portraits unless a matching new one is delivered.

## Source and animation contract

Built-in imagegen supplies painted drawings/pose sequences. Aseprite owns all
raster cutting, normalization, source layers, frames/tags and exports. Preserve
raw generated inputs, prompts, source/clip metadata and generation/edit scripts.
No paid external provider/account, installation, new3D modeling or history work
is implied. Use current available imagegen/Aseprite/Godot capabilities.

Animation must show actual articulated/redrawn poses: natural alternating steps,
modest stride, heel/toe contact, stable volume/identity, hip/torso/shoulder-driven
cut with anticipation/contact/recovery. Do not replace a whole-body sword action
with wrist rotation, translate one static cutout and call it walking, or use
crossfade ghosts as invented in-between drawings. The sword stays rigid and
hands stay on the hilt; shields/bow/arrow/daggers follow their own grip roles.
Critical poses and sheet cells are inspected before extending the family.

Use approximately100px/m and shallow18-degree tactical exposure. Stable ground
pivot/frame canvas, clear weapon margins, consistent filtering and alpha are
required. Do not independently normalize every animated body to one bounding
height, causing squash/bob/weapon growth. Root motion and planted foot intervals
must be compatible with the displayed movement and declared clip timing.

Keep technical file/pose checks, source preview, watched continuous1x motion,
gameplay interaction and user approval distinct. Desktop remains unreleased:
background/headless work is authorized, no mouse/keyboard or visible app launch
by the agent. User may open the supplied command. The61 original physical cases
stay NOT_RUN; add actual new integration cases to the existing live-test registry.

## Runtime timing and routing

The knight's five additional clips (draw, sheathe, alternate thrust, parry and
dodge) are also completed for every facing, making12 knight clips per direction.
The native gallery exposes these as knight-specific choices and hides roles
without the selected clip. Other roles require the seven primary directional
clips; their extra3/4 defense samples remain in the offline player. Neither
gallery invents a combat outcome or a new resolver action from a review clip.

The knight animation sandbox is selectable through the existing Tools scenario
catalogue. It reuses the ordinary full-combat encounter, its terrain, stats and
melee item profile; it gives the pilot a separate ID/painted knight visual and
removes its off-hand shield. This is an art/test fixture, not a new weapon rule
or campaign reward. The native gallery is available both as a standalone scene
and a read-only Tools overlay; closing the overlay restores battle input rather
than quitting the game.

Complete profiles publish seven primary clips for each of the eight distinct
facings: neutral_idle/combat_idle, neutral_walk/combat_walk, attack, hit, death.
Use the authored per-frame durations and retain full anticipation/recovery.
Legacy pose/walk/combat/status_reaction names map at the renderer boundary;
nearby opposition selects combat readiness for both idle and walking. Neutral
and combat idles must not be collapsed by the existing periodic idle refresh.
Eight-direction completeness, source roundtrip and non-clipping checks gate
activation. The extra3/4 showcase clips remain available in the local player.

Damage/reaction display begins at the declared attack impact frame (bow release
for archers), after anticipation. Finish the complete attack/reaction or last
death drawing before releasing the presentation lock. Generation changes cancel
stale playback; dead actors hold the final death frame.
Reset/reload invalidates pending timers/commits, kills owned movement tweens and
unlocks input. Floating message tweens are bound to their disposable message
node, so clearing messages cannot leave callbacks capturing freed UI objects.
Do not apply the legacy
additional rigid fall/lunge to already drawn articulated actions. Presentation
still uses authoritative resolver events without changing outcomes or costs.
Walking speed uses declared in-place cycle/stride metadata and actual displayed
travel, rather than keeping the old fast movement duration with a slow new cycle.

Directional reuse decision: five independently drawn views (front, front-right,
right profile, back-right, back) plus three Aseprite-reflected left views. Label
reflections in the player, source recipes and runtime provenance. They reverse
costume asymmetry and visible weapon handedness; no mechanical handedness is
introduced. User review of that convention remains pending. Preserve attempted
left-view drawings as candidates; mixed-facing/opaque-background attempts must
not become runtime profiles. Never claim eight independently drawn views.

Proof: [slice022](slices/022_drawn_animation_batch.md),
[milestone017](milestones/017_drawn_animation_batch.md).

## User correction batch: idle contact, shield reverse and bow aim

User2026-11-03 approves the overall delivered direction and requests three narrow
corrections with playable samples before the next task. Idle feet must remain
planted: register neutral/combat idle drawings to a common ground anchor and retain
the first frame's lower shins/boots while allowing upper-body breathing. Apply to
all six roles/eight views, without changing movement clips or game speed.

Back-facing and back-three-quarter shield views must show a plain wood/leather
interior, straps/grip and forearm connection, not the decorated exterior emblem.
Keep the existing shield silhouette, character identity, poses and other gear;
correct source views N/NE and reflected NW. Inspect side/front views separately.

The archer attack has a stronger full draw, drawing hand anchored at the cheek,
elbow at shoulder height or slightly higher, visibly bent bow, an explicit aiming
hold, quick release and follow-through. Keep eight drawings but increase the clip
from1000ms to1800ms:160/200/220/300/380/80/200/260ms. Release remains frame5
(zero-based), at1260ms. Update all eight views, source timing and runtime impact
metadata together. This changes presentation timing only, not resolver outcomes.

Preserve before-correction source/frames and exact prompts. Show focused native/
enlarged before/after motion samples. Subsequent explicit user feedback2026-11-03
accepts these corrections ("Tak ma byc"); this is preview acceptance, not ordinary
campaign play. No new roster, weapon rule, paid provider, Git or desktop-input
scope is introduced.

## Six-role ordinary battle review (stage56)

User2026-11-03 explicitly selects point1 of the proposed next steps: review the
current six painted roles in ordinary combat before expanding the roster. Provide
one isolated Tools encounter, `drawn_roster_skirmish`, on the existing Old Mine
terrain: four controllable allies (knight, warrior, archer_1, rogue_1) against four
AI opponents (two axe_bandit and two bandit_spearman). Use normal AP/MP, hit rolls,
damage, turn advancement and terminal conditions. No Debug Win or injected death
counts as an ordinary victory/defeat. Do not write campaign saves or add rewards.

Every actor explicitly selects its approved painted profile. Encounter-local
equipment agrees with the baked weapon: existing sword/shield and bow profiles,
the already supported two-handed greatsword profile, and ordinary melee profiles
named for daggers, axe and spear. Daggers use the existing single basic attack;
spear uses the existing adjacent melee range. These are art-review fixtures, not
new dual-wield/reach mechanics or campaign inventory items. The two-handed knight
and bow have empty off hands. Keep the previous knight sandbox and normal default.

An explicit launcher scenario option may start this encounter directly through
the validated scenario catalogue. Pending expedition combat and map-authoring
drafts retain priority. Show a recognizable encounter title and distinct actor
names in the existing combat UI. Reset/reload restores this encounter and cancels
pending animation commits. Default launch behavior remains unchanged.

Automated proof must exercise all six profiles through the actual CombatDebug
movement/attack/hit/death presentation and resolver, including bow anticipation,
full final frames and reset cancellation. Run a bounded full encounter through
legal commands to terminal results; label this a simulation, never hands-on play.
L56-01 records the user's ordinary battle at board scale and L56-02 its defeat/
restart counterpart. Keep each NOT_RUN until evidence arrives. Readability,
grips, shield surfaces, aim, feet and crowded sorting require actual visual review.
This scope does not authorize new character art, equipment-system redesign or Git
publication. Earlier L53/L54 and61 physical cases remain independently open.

## Battle feedback: brisk walking and rear sword/shield stance (stage57)

User2026-11-03 reports that movement in the six-role battle is much too slow.
Retain the80px authored stride and all existing walk drawings, but halve neutral
and combat walk cels from100ms to50ms across all six roles/eight views. This makes
both root travel and step cadence twice as fast:400ms per80px rather than800ms.
Do not speed up attacks, bow aiming, hit/death, idle breathing or authoritative
AP/MP/turn rules. Keep Aseprite sources, manifests, player and runtime in agreement.

User also requests a wider natural standing stance for the one-handed warrior
viewed exactly from behind (north), and explicitly clarifies that the sword must
be more occluded by the body. Keep the same character, proportional boots, armor,
shield interior, blade length and one-handed grip. Move the held sword/hand toward
the front of the torso in depth; conceal the occluded parts rather than painting
the entire long blade along the side of the rear silhouette. A deliberate attack
sweep can reveal the blade. Widen planted standing feet to a stable shoulder-width
stance without bowed knees. Preserve natural alternating steps in walking and
the complete existing death. No other facing or character appearance is requested.

Preserve stage56 source/runtime baselines with hashes. Use imagegen for redrawn
rear poses and Aseprite for native-scale cleanup, idle planting, editable sources
and exports. Retain the exact prompt/raw candidate and before/after samples.
Verify source roundtrip,96 walk clips at400ms, unchanged non-walk timings,
foot planting and actual CombatDebug travel/attack/death/reset. The user's report
is positive for remaining animation/movement, but gives no terminal battle result;
do not close ordinary victory/defeat or later production scope by inference.

## Natural cadence and two-handed swordsman stance (stage58)

User rejects stage57's rapid leg cadence: faster root travel is useful but the
feet cycle unnaturally fast. Restore8x100ms walking cels and calibrate a160px full
stride instead of80px, retaining the current200px/s root speed with half as many
cycles. Update all96 neutral/combat walk sources, manifests, runtime and preview
ground travel together. Preserve attacks, bow aim, idles, hit/death and AP/MP rules.
Use actual movement/contact-phase evidence and a native-speed user retest; a shorter
timer alone does not prove natural locomotion. Stage57's800ms→400ms cadence is
superseded, and remains retained as a rejected comparison baseline.

The swordsman here is the distinct two-handed `knight`, compared by the user with
the sword/shield warrior and axe role. Broaden and stagger his combat standing
base with relaxed knees and a credible fighting weight shift, preserving selected
forward guard A and two-handed grip. In neutral idle AND neutral locomotion he
must visibly carry the same sword lowered at his side, rather than empty hands
or the ready guard. Keep identity, body scale, modest boots and coherent weapon
length/occlusion in five drawn views plus three disclosed reflections. Preserve
existing combat walk/attacks/reactions/death/extras; redraw only neutral/combat
idles and neutral walking. Replant idle feet after export. The sword/shield north
correction from57 remains in place. Preserve the previous sources and provide
native/enlarged comparison plus a distance-aware walking sample before acceptance.

## Explicit rollback of58 (stage59)

User rejects58's blurred replacement model and fighting posture and explicitly
requests returning to the previous version and stopping iteration. Restore the
exact pre58 source/metadata/registry baseline, including knight drawings, original
stances/neutral carry and stage57's400ms/80px gait. This rollback does not approve
that earlier cadence or resolve known issues; it is the user's selected temporary
state. Preserve stage56/57 work and the rejected58 evidence. Verify all861 baseline
files and2304 runtime PNG identities; do not regenerate art. Disable reapplication
of the rejected recipe and record no further production authorization.

## Shield-warrior neutral reference and measured walking (stage60)

The user now explicitly reopens two narrow tasks after59: make the two-handed
knight's neutral standing pose closely follow the sword/shield warrior, and calm
the horse-like rapid stepping. This revokes the pause only for these tasks. Keep
the restored sharp character, combat pose and all other action drawings. Reuse
native accepted character/weapon pixels in Aseprite rather than regenerating or
rescaling the whole model. Preserve the knight's head/face and boots, use the
warrior's relaxed lowered sword arm as the pose reference, and keep the two-handed
blade rigid. New neutral source/exports must retain planted feet and breathing.

Use eight125ms walking cels (1000ms cycle) and160px stride:160px/s travel, with two
foot contacts per second rather than five. This is60% faster than the original
100px/s but deliberately20% below57's200px/s for a natural walking cadence. All96
neutral/combat walking sources, manifests, renderer and distance-aware previews
must agree. Walking pixels, attacks, bow aim, reactions, death and resolver/AP/MP
rules stay unchanged. Keep full backups and prove the native pixel scope, source
roundtrip, timing/stride/root speed and actual battle lifecycle. Acceptance of
natural motion remains a user visual review, not a headless claim.

Subsequent explicit user decision2026-11-03: stage60's neutral pose and walking
are USER_ACCEPTED_FOR_NOW. Retain this working version for development, with a
future user-authorized posture/locomotion polish pass; do not reopen art iteration
automatically. The user requests committing/pushing the accepted current work to
the main game repository/default branch. This does not publish a new workshop
release, approve rejected58, rewrite Git history or close unreported terminal
battle/campaign cases. No next implementation is authorized by the request for
advice on next steps.
