# Small town spaces: exploration plan v1

Date:2026-11-04. Authorized as the LAST item of timed polish milestone022.
Status: DESIGN_COMPLETE; stageA IMPLEMENTED / AUTOMATED_PASS /
AWAITING_INTERACTIVE. StagesB/C remain pending in the bounded order below.
Existing world001..007 and CampaignSession retain all economy/save/service rules.
Presentation006/007 and character presentation022..025 retain the approved art.

## Experience and scope

Explore a small Ravenford courtyard and, later, an inn interior. The party walks
with WASD, meets stationary NPCs and opens short readable conversations. Each
space is a compact authored stage, not a simulation of a whole city. No combat,
quests, schedules, reputation, procedural streets, housing or new economy in v1.
The current town services remain fully usable throughout development.

Dark fantasy direction: worn flagstone, charcoal wood, aged brass, restrained
warm braziers and quiet parchment dialogue. Reuse the current environment props
and approved painted actors for the mechanical pilot. Blockout/pilot art must be
labelled honestly; final roof/wall/innkeeper art needs the established asset
workflow and native-scale review before replacing approved campaign screens.

## Space and movement metrics

- Use a2:1 oblique diamond projection of a logical square grid,96x48px cells.
  Keep gameplay coordinates separate from screen coordinates. WASD points toward
  screen up/left/down/right; diagonal input is normalized and never faster.
- First courtyard:12x10logical cells, a clear gate at the lower edge, inn door
  on the upper-left approach, trader on the right, training guard on the left.
  Main paths at least2cells wide, door approaches at least2x2clear cells. Keep
  optional crate/brazier loops off the entrance-to-NPC critical path.
- Match original drawn stride rather than increasing foot cadence. At0.65sprite
  scale the accepted160px/s travel becomes104screen px/s; the eight125ms walk
  cels retain a1second cycle. Idle feet remain planted. No animation resampling.
- Foot collision radius0.16logical cell; sweep movement in bounded substeps and
  slide at obstacles. Clamp to authored walkable cells. NPC bodies block movement
  locally; decoration never silently changes the logical collision layer.
- Lead with Bran and use two visible companions in the mechanical pilot.
  Followers use a distance-sampled breadcrumb path,52screen px spacing, inheriting
  the leader's valid route. No direct interpolation through walls/corners.
  Followers have presentation-only collision with each other; no party trapping.
- Initially frame the entire small courtyard with safe actor headroom, no camera
  shake. Larger spaces may use Camera2D deadzone/smoothing/bounds after a separate
  movement review. Never change camera or body speed by frame count.

## Controls and interaction

Named actions: town_up/down/left/right (WASD and arrows), town_interact (E/Enter),
town_cancel (Escape). Read mapped actions, not raw keys in movement code. Initial
keyboard bindings are data; preserve a path to menus. Full remapping/gamepad
settings are a later input-settings slice, not falsely claimed by this pilot.

Nearest reachable NPC within100screen px is eligible; break equal-distance ties
by stable NPC id. Show one prompt, including the mapped action name. Interaction
opens an aged-parchment dialogue with speaker name, authored text and explicit
choices. Movement/follower updates and background interactions stop while open.
E held does not repeat; Escape closes and restores focus without immediately
reopening the same dialogue. Window focus loss clears held movement.

First cast: gate watch (where to go), quartermaster (existing Trading Post),
innkeeper (existing5gold recovery). Pilot conversations are informational only;
service launch is unavailable until the guarded campaign bridge is implemented.
No fake purchase, heal, quest reward or save side effect from dialogue text.

## Data and architecture

- Canonical finite TMX remains the map source under tooling003; derived map-v2
  JSON provides floor/blocked cells, decoration aliases and named spawn metadata.
  Town role metadata never creates combat units. No combat grid/resolver reuse
  for real-time motion and no change to tactical SE/SW restrictions.
- A town-space JSON references its map, party entry spawn and authored NPC rows
  (stable id, name, spawn id, existing visual profile, dialogue, service hint).
  Validate map/NPC/profile/dialogue references, unique ids and reachable spawns.
- Pure town movement model owns projection, walkability, swept movement,
  breadcrumbs and nearest-interaction selection. Native town view owns sprites,
  sorting by feet, texture playback, input context and dialogue controls.
- Reuse complete eight-facing source clips for noncombat town presentation.
  Direct profile lookup keeps these separate from the accepted SE/SW battle
  selector; never generate missing north views from the two-view enemy pilots.
- StageA is an isolated developer preview with in-memory local movement only.
  It must never load/write a campaign save or replace the default town scene.
- StageB embeds town exploration into App as optional town-view UI state.
  App retains an ephemeral position/space anchor when a service opens, routes to
  the existing trade/recovery/training UI and restores the anchor on return.
  No new autoload or durable hero position is required for v1. Restart returns to
  the safe town entrance. World location remains town_ravenford.
- Revalidate CampaignSession.at_town/can_trade and pending-event/active-run
  restrictions for entry and every transaction. Services continue their existing
  atomic saves. Entering a room, walking, talking, closing or cancelling spends
  no food/gold/time and does not reroll road events. Leaving the gate opens the
  existing region UI; actual travel still needs its normal preview/confirmation.

## Ordered build and acceptance

A. Mechanical courtyard pilot: author/validate map and space data; prove movement,
collision, normalized diagonals, follower route and blocking dialogue; render
native720p/1080p/1440p and provide a separate preview command. Retain pilot status.

B. Guarded campaign bridge: optional Explore courtyard entry, NPC services through
existing owners, return anchors, full campaign roundtrip/restart and failed-write
tests. Keep the service-card route available. Physical ordinary play required.

C. Inn and final art: test a second bounded room/door return, review scene art,
occlusion/fading roofs, NPC identity, ambient feedback and final pixel sources.
Only then consider the exploration view as the default town presentation.

Proof owner: slices/008_town_exploration.md. A passed mechanical pilot does not
approve final town art, stageB persistence or stageC. No automated fixture closes
an actual keyboard/gameplay scenario.
