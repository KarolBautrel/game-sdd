# Ordered player review checkpoint

Current stage80: user authorizes the seeded-region generator. Launch
`& .\tools\qa\start_game.ps1 -Scene regions`; review three presets/seeds, route
preview, actual bridge travel, gear/mine retreat and resumption. Authored Marches
retains the original map and designer revision9. See2026-11-04-generated-regions.md.
Generated appearance/physical feel and earlier ordinary mine-victory review stay
unreported. Work remains local; stage79 motion is retained in both map types.

Latest follow-up: user approves living stage77 and requests publication, now
complete as f0fc7d16. Stage78 terrain navigation is the active local review:
`& .\tools\qa\start_game.ps1 -Scene terrain-editor`, then Living world. Check
river/peak blockers, crossings and forest/hill/slope movement costs. See
2026-11-04-terrain.md. Physical ordinary mine victory remains unreported.

Current authorized stage77 replaces the static-atlas gameplay priority with the
living-region pilot: `& .\tools\qa\start_game.ps1 -Scene living-world`. Same
accepted map family, separate resumable save, continuous movement, contracts and
mine/world consequences. Follow2026-11-04-living-world.md and physical L77-01.

Current override: user explicitly moves to point3, world travel, before point2.
Stage76 delivers four provinces/twenty destinations and a global/provincial atlas;
native/focused evidence and current full-check status are in world-atlas QA.
Next is its player review. Dungeon appearance remains approved; equipment and
later battle/courtyard reviews remain pending. No automatic new push is requested.

Previous publication checkpoint: current native Ashen dungeon appearance is APPROVED for
this stage. Stop visual dungeon redesign and return to step2, equipment review.
The user requests publication and a reminder of this original queue, not another
implementation batch. Detailed physical full-flow actions were not reported;
retain that technical evidence gap without reopening accepted visual review1.

Date:2026-11-04. User requests saving all six review steps, then addressing them
one at a time. Latest72c: user rejects flat72b and restores textured72 as temporary
current. New concept/research await visual choice; no later step is accepted.
See design/dungeon-ui/research-2026-11-04/RESEARCH.md.

Latest73: user approves the mine v2 look and requests archetype samples before
implementation. Mine/dungeon/castle/forest gallery is ready at
docs/design/exploration-archetypes/2026-11-04/index.html. Three new themes await
review; this visual approval does not close L67-01 or other physical tests.

Stage74 follow-up supersedes that pending art review: ALL FOUR samples are now
approved. Reusable UI skill and 15-layout/4-theme preparation library are saved.
Native component production/integration is next; current game still uses textured72.
Visual direction approval does not close the physical flow case L67-01.

| Order | Review | Command from repository | Physical case | Current status |
| --- | --- | --- | --- | --- |
| 1 | Dungeon appearance and passage/event flow | `& .\tools\qa\start_game.ps1 -Scene dungeon` | L67-01 | USER_APPROVED_CURRENT_VISUAL_STAGE; automated flow PASS; detailed physical flow not reported |
| 2 | Equipment ownership, hand conflicts, retained selection/scroll | `& .\tools\qa\start_game.ps1 -Scene app -HeroEquipmentPilot` | L68-01 | PENDING |
| 3 | Living-region movement/pause, caravan/factions/contracts, mine consequences and persistence | `& .\tools\qa\start_game.ps1 -Scene living-world` | L77-01 | ACTIVE_REVIEW; stage77 full74/74 and native146/48/18 PASS; ordinary physical mine victory pending; stage76 appearance approved/preserved |
| 4 | Forest Ambush: routes, cover, actor readability, ordinary terminal battle | `& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_forest_ambush` | L70-01 forest part | PENDING |
| 5 | Mine Breach: crossings, occlusion, movement/turn completion | `& .\tools\qa\start_game.ps1 -Scene combat -CombatScenario painted_mine_breach` | L70-01 mine part | PENDING |
| 6 | Courtyard prototype: WASD, followers/collision,3NPC conversations | `& .\tools\qa\start_game.ps1 -Scene town-preview` | L71-01 | PENDING; services/inn/final NPC art are not implemented |

Use PowerShell in game_dir/sdd-game. Close a previous preview before starting
another. Dungeon initially defaults to generated content: choose **Use Old Mine**
before **Start Expedition** to review the exact illustrated authored chart.
Commands and save boundaries remain in2026-11-04-preview-guide.md.

## Step1: saved user feedback; stage72 correction ready for retest

1. Worn/aged material is a good direction, but visible repeated square texture
   patches/seams across backgrounds look poor. Address the large backdrop and
   panel interiors, not only a single corner. Keep natural varied material without
   an obvious small repeated grid.
2. World-travel view is the approved concrete target. Match its finished framing,
   material application, typography, spacing and fitted composition directly.
   Sharing asset filenames/colors alone has not produced the requested result.
3. Bottom party portraits need a better integrated strip/card arrangement. Names,
   whole portraits and explicit current/max HP must fit. Bran's red and Torin's
   yellow health bars must become one consistent HP color/style; hero identity
   accents must not redefine health meaning.
4. Room plates need readable actual connections so the player sees where a path
   starts/ends and which destination it reaches. Latest feedback supersedes the
   earlier omission of all connector overlays. Heavy pipes/crosses remain rejected;
   proposed direction is restrained map-like paths behind plates, with a clear
   current room and selected passage. Never invent edges or cross labels.
5. Fit all text/values inside frames with deliberate padding and line heights.
   Verify actual native rendering, HP readability, long room/event names and
   target window sizes rather than reducing essential text until unreadable.

Next: repeat step1 with the user using the implemented dungeon-only correction.
Review quiet non-repeating material, dark world-family framing, whole portraits /
current-max HP, both red health bars and truthful selected passage paths.
Keep the rest of this queue saved and pending.
Source/historical automated PASS is not user visual acceptance of this screen.

Follow-up72b: user reports improvement but pixelated background motifs around
frames. Corrected the remaining enlarged grain in edge strips and the backdrop;
native720p/1080p/4K PASS, including inspected1:1 edge crops. Current screenshots
are in `docs/design/dungeon-ui/review1/material-fix/`. Step1 stays active for retest.

Latest72c supersedes72b: user found the flattened screen much worse. Textured72
restored and snapshotted; native output matches its saved reference exactly.
Research/new concept is isolated in `research-2026-11-04/`; awaiting look selection.
