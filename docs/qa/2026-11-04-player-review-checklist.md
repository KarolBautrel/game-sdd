# Ordered player review checkpoint

Latest user follow-up: current native Ashen dungeon appearance is APPROVED for
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
| 3 | Region journey preview/cancel/confirm, costs/reserve and return | Continue in the same App window, Region tab | L69-01 | PENDING |
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
