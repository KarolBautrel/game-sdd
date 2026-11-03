# Stages63..65: Bran campaign, two bandits, wolf

User2026-11-03: execute all three proposed tasks together. IMPLEMENTED /
AUTOMATED_PASS / AWAITING_USER_ART_AND_PHYSICAL_REVIEW. Owner: presentation025 /
slice025 / milestone020; existing equipment/world/combat rules preserved.
All work remains local/uncommitted on master with stages61/62. No push requested.

## Delivered behavior

Bran's two kits now have complete managed campaign proof: ordinary travel and
authored Old Mine rooms, shrine choice, guarded fight, reward, lower exit,
settlement and restart. Both kits win by legal AI/resolver commands in19steps;
no forged result/Debug Win. Gear/identity persist, reward is paid once, duplicate
receipt rejects. Normal shop ownership/conflict/failed-write and road proofs
remain. Identity suite1259/0; no actual player-save mutation.

New bandit archer: burgundy hood and patched brown leather, own face/wooden bow,
full cheek draw with raised elbow, aiming hold, release and recovery. Existing
raider_archer/bandit_archer appearance routes to it in tactical play, including
ordinary managed random encounters. Torin and the accepted six actors are kept.

New shield fighter: iron cap/visible mature face, worn chain/leather/fur and rust
tunic, right-hand sword/left-arm round wooden iron-boss shield. Real shieldman
role selects this appearance. Ordinary cleaver brute remains its own old family;
no unrelated shield is given to it. The new four-frame block completes when
Shield Wall is shown; other status-only lifecycle remains unchanged.

New grey/brown wolf: independent quadruped drawings,95px standing silhouette
against171px humans on the shared384x320 canvas/pivot192,270. Four-leg walk,
alert ready stance, crouch/lunge/bite, recoil and articulated floor collapse.
Existing melee/fangs resolution is reused in the isolated pilot. It is not added
to the managed random enemy pool as an unrelated balance change.

All three have seven primary clips, guard additionally block. One drawn SE view
and one disclosed SW reflection per actor, reversing handedness/asymmetry.
44canonical Aseprite animation clips /272PNG runtime cels. Nine built-in imagegen
sheets, exact prompts, raw outputs and reference images are saved under
assets_src/characters/tactical_batch/2026-11-03. All raster processing was Aseprite.
The wolf's clipped last ready cell is excluded; ready loop13/14/15/14 has one
explicit held drawing. Red/yellow generator residue is removed in Aseprite.
Detached release arrow is excluded from the sprite; engine projectile is retained.

## Verification

- Initial exporter and final44source open/tag/duration/pixel checks PASS. Idle
  contacts planted; human lower shins232+, wolf paws250+. Walks8x125ms/160px.
  Wolf uses one standing-scale reference for crouch/bite/fall rather than fitting
  a shorter corpse to standing height.
- Canonical edited-source export reproduces all272 PNG files byte-for-byte,
  leaves all44 Aseprite files unchanged, and records source hashes. Metadata-only
  packaging rejects changed/unverified sources. No accepted PNG was regenerated;
 2304previous accepted hashes match, old raw eight-view assets remain available.
- New native suite1887/0: both facings, complete north walk, full attack/recoil/
  death, correct final corpse, real damage/terminal result, full Shield Wall brace,
  readable review names, native size/transparency and animation unlock.
- Full normal isolated review battle:4accepted allies vs3new enemies; existing
  AI on both teams wins in33commands. Passive-player policy reaches defeat in185.
  Neither is physical play or Debug Win. Role session/command counts are retained.
- Full combined runner PASS: drawn7386/0, prior battle313/0, tactical5158/0,
  new pilot1887/0, original roster16111/0, lifecycle, equipment31/0, domain combat,
  feedback179/0, identity1259/0, campaign gear50/0, campaign session, trade48/0
  and validate_all. Logs: artifacts/drawn-animation, artifacts/bran-identity,
  artifacts/tactical-batch. Invalid source tables reject in four negative cases.
- New offline player413checks/0; prior player3579/0. Native still/attack/death/
  locomotion atlases and terrain board inspected. Continuous1x human review remains
  open; Node playback is not browser or motion-quality acceptance.
- Direct launcher ConfigureOnly proves larger left DISPLAY1, screen0, correct
  scenario. Normal CombatDebug scene starts headlessly without diagnostics. Owned
  override.cfg restored byte-for-byte; no OS input or visible app was launched.

Issues found and fixed: unsupported per-unit display_name was moved to the
existing presentation naming boundary; imported fully transparent RGB fill is
ignored only at alpha0 for contact comparison (visible RGBA remains exact);
tactical aliasing originally affected archive inspection. Original/legacy gallery
contexts now preserve raw families and requested eight-view facings, with explicit
icon regressions. Current battlefield heroes/villains always show SE/SW.

## Review

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_tactical_batch_preview.ps1"
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_painted_enemy_pilot.ps1"
```

Preview has actual1x/enlargement, direction/action selection, pause and frame
buttons. Battle is an isolated normal encounter with no campaign settlement.
Bran's resumable separate campaign is tools/qa/start_hero_equipment_pilot.ps1.
L63..65 remain user review/physical cases. New art is a candidate until the user
reviews it; no wider human/creature/city batch or publication is inferred.
